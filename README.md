# AgentLaunch Doctor

[日本語](README.ja.md)

Read-only health and privacy diagnostics for macOS LaunchAgents used by local AI agents and automations.

AgentLaunch Doctor answers a narrow question: **is this background job configured safely enough to trust, and does launchd agree that it is healthy?**

It checks plist validity, executable and working-directory paths, launchctl state, last exit status, log freshness, file permissions, restart-loop risk, public bind arguments, and secret-shaped configuration. Every finding includes a privacy-safe next step. It never prints secret values or reads log contents.

## Safety promise

AgentLaunch Doctor never:

- loads, unloads, restarts, edits, deletes, or repairs a job
- reads Keychain, browsers, mail, chats, or unrelated files
- reads stdout/stderr log contents
- sends diagnostics to a server or AI provider

The default report is for local use. Use `--format feedback` for public beta feedback; it automatically enables strict redaction and outputs only the version, aggregate counts, and finding codes. Add `--strict` before sharing any other report.

## Quick start

The three-minute beta path requires macOS 13 or later, Homebrew, and Xcode 15 or later. Homebrew builds the tagged source locally:

```bash
brew install pastorstephan-prog/tap/agentlaunch-doctor
agentlaunch-doctor --all-user-agents --format feedback
```

An exit code of `1` means the scan completed and found at least one high-severity item; it is not an installation failure. Review the local detailed report with `agentlaunch-doctor --all-user-agents`. Then submit only the minimal feedback output through the [beta activation form](https://github.com/pastorstephan-prog/agentlaunch-doctor/issues/new?template=beta-activation.yml).

Without Homebrew, build from source with Swift 5.9 or later:

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

The release archive is ad-hoc signed and not Apple-notarized. Gatekeeper may block it on another Mac; use the Homebrew source build when that happens. The project does not recommend bypassing macOS security checks.

Inspect selected jobs:

```bash
agentlaunch-doctor ~/Library/LaunchAgents/com.example.agent.plist
```

Create a privacy-minimal beta feedback report:

```bash
agentlaunch-doctor --all-user-agents --format feedback
```

If runtime lookup is restricted, run static plist checks only:

```bash
agentlaunch-doctor --all-user-agents --strict --no-runtime
```

Exit code is `1` when a completed scan has a high-severity finding, otherwise `0`. CLI usage errors return `2`.

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

## External beta

The current beta measures external activation, confirmed fixes, false high-severity findings, and repeat use without default telemetry. See [BETA.md](BETA.md) or [日本語ベータ案内](BETA.ja.md) before sharing feedback. Public issues must contain only aggregate counts and finding codes—never plist contents, labels, paths, logs, screenshots, or secrets.

## Development

```bash
swift test
swift build -c release
swift run agentlaunch-doctor --all-user-agents
```

## Scope

Version 0.2 inspects per-user LaunchAgents. It deliberately does not request administrator access or inspect system LaunchDaemons.

## License

ISC. See [LICENSE](LICENSE).

## Support the project

Funding is not active yet. Public support options will be added only after the funding account is approved and the route is verified.
