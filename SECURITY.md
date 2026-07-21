# Security

AgentLaunch Doctor is intentionally read-only.

- It inspects only plist paths selected on the command line, or regular plist files in the current user's `~/Library/LaunchAgents` when `--all-user-agents` is used.
- It calls only `launchctl print` for runtime state.
- It never loads, unloads, restarts, edits, deletes, repairs, or uploads a job.
- It never reads Keychain, browser data, mail, chats, unrelated files, or log contents.
- Secret-shaped values are counted but never included in reports.
- `--strict` also redacts labels and plist filenames.

Do not post a local-mode report publicly. Use `--strict` and inspect the output before sharing.

Report vulnerabilities through GitHub private security advisories. Do not include real tokens, private logs, or tokenized URLs.
