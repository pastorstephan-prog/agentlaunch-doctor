# 30-day external beta

AgentLaunch Doctor is collecting evidence from external Mac operators before expanding beyond its read-only CLI scope.

## Who this is for

The beta is most useful if you run at least three user LaunchAgents for local AI agents, developer tools, or automations on macOS.

## Safe participation

This path assumes Homebrew and Xcode 15 or later are already installed:

```bash
brew install pastorstephan-prog/tap/agentlaunch-doctor
agentlaunch-doctor --version
agentlaunch-doctor --all-user-agents --format feedback
```

The feedback format automatically uses strict redaction. Copy only its small text output into the activation form. Do not upload a full text or JSON report, plist, log, or screenshot. An exit code of `1` means the scan succeeded with one or more high findings; `2` means the command usage was invalid.

Review detailed findings only on your Mac with `agentlaunch-doctor --all-user-agents`. Do not bypass Gatekeeper; use the Homebrew source build if the release archive is blocked.

AgentLaunch Doctor does not collect telemetry. Participation is voluntary and public GitHub issues are public.

## Evidence gates

The product remains an active investment only if the beta reaches:

- 10 verified external operators
- 5 independently confirmed fixes
- at least 50% confirmed-resolution rate among reviewed incidents
- fewer than 10% false high-severity findings
- at least 30% of mature activated operators repeating a scan after 30 days
- zero secret leaks

Owner-operated machines and owner QA downloads do not count as external adoption.

## Submit feedback

First run: open an [activation issue](https://github.com/pastorstephan-prog/agentlaunch-doctor/issues/new?template=beta-activation.yml).

If installation or the command could not start, use the separate [installation-failure form](https://github.com/pastorstephan-prog/agentlaunch-doctor/issues/new?template=beta-install-failure.yml); it does not ask you to invent scan counts.

After attempting a fix and re-scanning: open a [follow-up issue](https://github.com/pastorstephan-prog/agentlaunch-doctor/issues/new?template=beta-follow-up.yml) and reference the first issue number. A confirmed fix requires the same external operator, a linked initial and follow-up issue, the original finding disappearing, and the job working afterward.

External operators are deduplicated by GitHub user. Owner-operated machines, bots, CI, clones, and release downloads do not count as activation. If safe redaction is uncertain, do not post anything.
