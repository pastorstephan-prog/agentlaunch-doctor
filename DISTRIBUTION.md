# Distribution and notarization

## Current safe routes

| Route | Signature and Gatekeeper state | Intended audience |
| --- | --- | --- |
| Homebrew source build | Built locally from a pinned public tag and checksum | Recommended while Developer ID is unavailable |
| GitHub universal ZIP | Ad-hoc signed, checksum-verified, not notarized | Technical testers who understand Gatekeeper may block it |
| Developer ID ZIP | Not available until a Developer ID Application certificate is issued | General direct-download users after notarization passes |

Never tell a user to bypass Gatekeeper. Keep Homebrew as the default installation route until a downloaded release passes Developer ID and notarization checks.

## One-time private setup

Do not commit certificates, passwords, API keys, or notarization output containing account information.

Required private values:

- `MACOS_CERTIFICATE_P12_BASE64`: base64 of the exported Developer ID Application certificate and private key; omit it when the identity is already installed locally
- `MACOS_CERTIFICATE_PASSWORD`: the P12 export password
- `NOTARY_APPLE_ID`: Apple Developer account email
- `NOTARY_TEAM_ID`: the ten-character Apple Developer Team ID
- `NOTARY_APP_SPECIFIC_PASSWORD`: an app-specific password created for notarization
- optional `DEVELOPER_ID_APPLICATION`: the exact certificate common name when more than one Developer ID identity is available

For GitHub Actions, store every value as an Actions secret. A partial secret configuration must be treated as an error, not as permission to fall back silently to ad-hoc signing.

## Signing and notarizing a release candidate

Build the universal executable first, then run:

```bash
scripts/sign-and-notarize.sh \
  dist/agentlaunch-doctor \
  dist/agentlaunch-doctor-macos-universal.zip
```

The script fails unless all of these are true:

- the binary contains both `arm64` and `x86_64`
- a Developer ID Application identity is available
- Hardened Runtime and a secure timestamp are present
- the ZIP contains exactly one root executable
- Apple's notary service returns `Accepted`

A ZIP can be notarized but cannot be stapled directly. Apple publishes the ticket online for Gatekeeper. If offline stapled verification becomes a product requirement, distribute a signed installer package and staple the ticket to the package.

## Release gate

Before publishing:

1. Run `swift test` and release builds on Apple silicon and Intel.
2. Confirm the CLI version equals the protected tag.
3. Verify the universal architectures and strict code signature.
4. Create the GitHub release as a draft.
5. Re-download the exact draft assets and verify checksum, archive layout, version, architectures, and signature.
6. For Developer ID releases, retain evidence that notarization returned `Accepted` and test a quarantined download on a clean Mac.
7. Publish only after every check succeeds.
8. Update the Homebrew formula with the public source-tag checksum and pass both architecture jobs.
9. Merge the release commit back into `develop`.

## 日本語要約

Developer ID証明書の取得前はHomebrewを標準配布経路とします。証明書取得後は、上記スクリプトがUniversal構成、Developer ID署名、Hardened Runtime、タイムスタンプ、ZIP構造、Apple公証の`Accepted`までを一括検証します。ZIPへ公証チケットを直接stapleすることはできないため、オフライン検証が必要になった段階で署名済みPKG配布へ移行します。
