# 30-day external beta

AgentLaunch Doctor is collecting evidence from external Mac operators before expanding beyond its read-only CLI scope.

## Who this is for

The beta is most useful if you run at least three user LaunchAgents for local AI agents, developer tools, or automations on macOS.

## Safe participation

1. Run a local scan.
2. Review findings locally.
3. If you share a report, use `--strict --format json` and inspect the file before uploading it.
4. Prefer the beta feedback issue form. Share finding codes and aggregate counts, not plist contents, labels, filenames, paths, logs, tokens, or account details.

AgentLaunch Doctor does not collect telemetry. Participation is voluntary and public GitHub issues are public.

## Evidence gates

The product remains an active investment only if the beta reaches:

- 10 verified external operators
- 5 independently confirmed fixes
- at least 50% confirmed-resolution rate among reviewed incidents
- fewer than 10% false high-severity findings
- at least 30% of activated operators repeating a scan within 7–30 days
- zero secret leaks

Owner-operated machines and owner QA downloads do not count as external adoption.

## Submit feedback

Open a [beta feedback issue](https://github.com/pastorstephan-prog/agentlaunch-doctor/issues/new?template=beta-feedback.yml). If safe redaction is uncertain, do not post the report; describe only the generic finding code and outcome.
