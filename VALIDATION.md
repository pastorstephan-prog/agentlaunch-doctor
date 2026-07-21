# Validation record

Validated: 2026-07-21

## Real-machine sample

- New Mac: 25 user LaunchAgents on macOS 26.5.2
- Old Mac: 37 user LaunchAgents on macOS 26.3.1
- Total: 62 real user-owned jobs
- Architectures: Apple silicon on both machines

Only aggregated strict-mode results were retained. No plist values, labels, filenames, private paths, or log contents were copied into this repository.

The real sample exercised repeated findings for stale logs, unloaded agents, non-zero last exits, missing labels/programs/triggers, secret-shaped environment configuration, permissive secret-bearing plist permissions, and always-on restart policy.

## Privacy verification

Strict JSON output from both machines was searched for the account name, hostnames, known public handle, organization labels, and full home-directory path. Matches: 0.

Synthetic regression tests also verify that environment secrets, command-line secret values, labels, filenames, and temporary source paths are absent from strict reports.

## Performance baseline

On the New Mac:

- conventional 10-job baseline (`plutil`, `stat`, and individual `launchctl print` calls): 0.12 seconds
- AgentLaunch Doctor full 25-job scan: 0.02 seconds

The Doctor scanned 2.5 times as many jobs in about one sixth of the baseline time, exceeding the 50% time-reduction gate.

## Defects found during validation

1. Per-job `launchctl print` could hang across a larger old-Mac sample.
2. Waiting for `launchctl list` before draining stdout could fill the pipe and cause a false all-unloaded report.
3. A binary built on a newer macOS point release was not portable to the older test Mac, while a source build on that Mac passed. Release binaries are therefore built on GitHub's stable macOS image, target macOS 13+, and are packaged as Universal binaries.

All three defects were corrected or reflected in the distribution design before the first public release.
