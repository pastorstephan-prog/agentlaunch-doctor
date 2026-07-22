# Changelog

All notable changes to AgentLaunch Doctor are documented here.

## 0.2.2 - 2026-07-23

- Fix Universal-architecture validation in the protected release workflow.

## 0.2.1 - 2026-07-23

- Pin third-party GitHub Actions to immutable commits.
- Build releases as drafts and publish them only after checksum, archive layout, version, architecture, and code-signature verification succeeds.
- Run the full test suite and a release-build smoke test on a hosted Intel Mac in addition to Apple silicon CI.

## 0.2.0 - 2026-07-22

- Add a privacy-safe, actionable next step to every text and JSON finding.
- Reclassify stale logs as informational because quiet or infrequent jobs can be healthy.
- Add a privacy-guarded external beta feedback form and explicit 30-day evidence gates.
- Expand the regression suite from 7 to 10 tests.

## 0.1.3 - 2026-07-21

- Remove the inactive GitHub Sponsors link until the funding profile is publicly available.

## 0.1.2 - 2026-07-21

- Place the executable at the root of the release archive so the documented unzip command works directly.

## 0.1.1 - 2026-07-21

- Fix the release checksum manifest so it verifies correctly after download.

## 0.1.0 - 2026-07-21

- Add read-only inspection of per-user macOS LaunchAgents.
- Add plist, path, permission, restart, network exposure, log metadata, and launchctl runtime checks.
- Add strict redaction and JSON output for safely shareable reports.
- Add synthetic privacy regression tests and Universal macOS release packaging.
