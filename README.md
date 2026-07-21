# AgentLaunch Doctor

[日本語](README.ja.md)

Read-only health and privacy diagnostics for macOS LaunchAgents used by local AI agents and automations.

AgentLaunch Doctor answers a narrow question: **is this background job configured safely enough to trust, and does launchd agree that it is healthy?**

It checks plist validity, executable and working-directory paths, launchctl state, last exit status, log freshness, file permissions, restart-loop risk, public bind arguments, and secret-shaped configuration. It never prints secret values or reads log contents.

## Safety promise

AgentLaunch Doctor never:

- loads, unloads, restarts, edits, deletes, or repairs a job
- reads Keychain, browsers, mail, chats, or unrelated files
- reads stdout/stderr log contents
- sends diagnostics to a server or AI provider

The default report is for local use. Add `--strict` before sharing a report; strict mode redacts labels and filenames too.

## Quick start

Requirements: macOS 13 or later. Download the Universal binary from GitHub Releases, or build from source with Swift 5.9 or later.

```bash
git clone https://github.com/pastorstephan-prog/agentlaunch-doctor.git
cd agentlaunch-doctor
swift run agentlaunch-doctor --all-user-agents
```

Release archive:

```bash
curl -LO https://github.com/pastorstephan-prog/agentlaunch-doctor/releases/latest/download/agentlaunch-doctor-macos-universal.zip
unzip agentlaunch-doctor-macos-universal.zip
./agentlaunch-doctor --all-user-agents
```

Inspect selected jobs:

```bash
swift run agentlaunch-doctor ~/Library/LaunchAgents/com.example.agent.plist
```

Create a shareable JSON report:

```bash
swift run agentlaunch-doctor --all-user-agents --strict --format json > report.json
```

If runtime lookup is restricted, run static plist checks only:

```bash
swift run agentlaunch-doctor --all-user-agents --strict --no-runtime
```

Exit code is `1` when a high-severity finding exists, otherwise `0`. CLI usage errors return `2`.

## Checks

- missing or invalid plist labels
- missing, relative, non-executable, or tilde-based program paths
- missing working directories and log directories
- stale or world-writable log files, without reading their contents
- group/world-writable plists
- group/world-readable plists that embed secret-shaped configuration
- secret-shaped environment entries and command arguments, reported only as counts
- apparent `0.0.0.0` or `::` all-interface binds
- very low restart throttles and missing common launch triggers
- launchctl loaded state, PID, run count, and last exit status

Findings are diagnostic evidence, not automatic proof of a vulnerability. Review a job's own documentation before changing it.

## Development

```bash
swift test
swift build -c release
```

## Scope

Version 0.1 inspects per-user LaunchAgents. It deliberately does not request administrator access or inspect system LaunchDaemons.

## License

ISC. See [LICENSE](LICENSE).

## Support the project

If AgentLaunch Doctor saves you time, you can support continued maintenance through [GitHub Sponsors](https://github.com/sponsors/pastorstephan-prog).
