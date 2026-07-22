# Contributing

Bug reports and focused pull requests are welcome.

External scan outcomes should use the beta feedback form and follow [BETA.md](BETA.md).

## Before opening an issue

- Reproduce with the newest release.
- Prefer `--strict --format json` when attaching a report.
- Remove anything you do not want published. Strict mode is a safeguard, not a substitute for reviewing an attachment.
- Never post tokens, plist contents, log contents, private paths, or account details.

## Development

Requirements: macOS 13 or later and Swift 5.9 or later.

```bash
swift test
swift build -c release
.build/release/agentlaunch-doctor --version
```

Keep diagnostics read-only. Changes that load, unload, restart, edit, or delete LaunchAgents are out of scope.
