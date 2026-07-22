#!/bin/bash

set -euo pipefail

usage() {
  echo "Usage: $0 /path/to/agentlaunch-doctor /path/to/output.zip" >&2
}

fail() {
  echo "error: $*" >&2
  exit 1
}

[[ $# -eq 2 ]] || { usage; exit 2; }

binary_input=$1
archive_input=$2

[[ -f "$binary_input" ]] || fail "binary not found: $binary_input"
[[ "$archive_input" == *.zip ]] || fail "output archive must use the .zip extension"

for command in codesign ditto lipo security xcrun; do
  command -v "$command" >/dev/null 2>&1 || fail "required command is unavailable: $command"
done

: "${NOTARY_APPLE_ID:?Set NOTARY_APPLE_ID to the Apple Developer account email.}"
: "${NOTARY_TEAM_ID:?Set NOTARY_TEAM_ID to the Apple Developer Team ID.}"
: "${NOTARY_APP_SPECIFIC_PASSWORD:?Set NOTARY_APP_SPECIFIC_PASSWORD to an app-specific password.}"

binary_dir=$(cd "$(dirname "$binary_input")" && pwd)
binary_path="$binary_dir/$(basename "$binary_input")"
mkdir -p "$(dirname "$archive_input")"
archive_dir=$(cd "$(dirname "$archive_input")" && pwd)
archive_path="$archive_dir/$(basename "$archive_input")"

temporary_dir=$(mktemp -d "${TMPDIR:-/tmp}/agentlaunch-notary.XXXXXX")
temporary_keychain=""
notary_result="$temporary_dir/notary-result.json"

cleanup() {
  if [[ -n "$temporary_keychain" ]]; then
    security delete-keychain "$temporary_keychain" >/dev/null 2>&1 || true
  fi
  rm -rf "$temporary_dir"
}
trap cleanup EXIT

identity_keychain_args=()
if [[ -n "${MACOS_CERTIFICATE_P12_BASE64:-}" ]]; then
  : "${MACOS_CERTIFICATE_PASSWORD:?Set MACOS_CERTIFICATE_PASSWORD when importing a P12 certificate.}"
  certificate_path="$temporary_dir/developer-id.p12"
  temporary_keychain="$temporary_dir/signing.keychain-db"
  temporary_keychain_password=$(uuidgen)

  printf '%s' "$MACOS_CERTIFICATE_P12_BASE64" | base64 -D > "$certificate_path"
  security create-keychain -p "$temporary_keychain_password" "$temporary_keychain"
  security set-keychain-settings -lut 21600 "$temporary_keychain"
  security unlock-keychain -p "$temporary_keychain_password" "$temporary_keychain"
  security import "$certificate_path" \
    -k "$temporary_keychain" \
    -P "$MACOS_CERTIFICATE_PASSWORD" \
    -T /usr/bin/codesign \
    -T /usr/bin/security
  security set-key-partition-list \
    -S apple-tool:,apple: \
    -s \
    -k "$temporary_keychain_password" \
    "$temporary_keychain"
  identity_keychain_args=("$temporary_keychain")
fi

if [[ -n "${DEVELOPER_ID_APPLICATION:-}" ]]; then
  signing_identity=$DEVELOPER_ID_APPLICATION
else
  identity_line=$(security find-identity -v -p codesigning "${identity_keychain_args[@]}" | grep '"Developer ID Application:' | head -n 1 || true)
  [[ -n "$identity_line" ]] || fail "no Developer ID Application identity is available"
  signing_identity=${identity_line#*\"}
  signing_identity=${signing_identity%\"*}
fi

lipo "$binary_path" -verify_arch arm64 x86_64
codesign \
  --force \
  --options runtime \
  --timestamp \
  --sign "$signing_identity" \
  "$binary_path"
codesign --verify --strict --verbose=2 "$binary_path"

signature_details=$(codesign -dv --verbose=4 "$binary_path" 2>&1)
grep -q '^Authority=Developer ID Application:' <<< "$signature_details" || fail "Developer ID authority was not recorded"
grep -Eq '^flags=.*\(runtime\)' <<< "$signature_details" || fail "Hardened Runtime was not enabled"
grep -q '^Timestamp=' <<< "$signature_details" || fail "a secure signing timestamp was not recorded"

rm -f "$archive_path"
(
  cd "$binary_dir"
  ditto -c -k "$(basename "$binary_path")" "$archive_path"
)
[[ "$(zipinfo -1 "$archive_path")" == "$(basename "$binary_path")" ]] || fail "archive layout is not the expected single root executable"

xcrun notarytool submit "$archive_path" \
  --apple-id "$NOTARY_APPLE_ID" \
  --team-id "$NOTARY_TEAM_ID" \
  --password "$NOTARY_APP_SPECIFIC_PASSWORD" \
  --wait \
  --output-format json > "$notary_result"

notary_status=$(/usr/bin/python3 -c 'import json, sys; print(json.load(open(sys.argv[1])).get("status", ""))' "$notary_result")
if [[ "$notary_status" != "Accepted" ]]; then
  /usr/bin/python3 -m json.tool "$notary_result" >&2
  fail "Apple notarization status is $notary_status"
fi

echo "Developer ID signature: verified"
echo "Hardened Runtime: enabled"
echo "Apple notarization: Accepted"
shasum -a 256 "$archive_path"
