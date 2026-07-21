# Repository Instructions

- Keep every default operation read-only.
- Never add automatic repair, restart, upload, telemetry, AI/API calls, Keychain access, or log-content reading.
- Reports must never contain secret values.
- Add regression tests for every new finding type.
- Use Git Flow: `main` for releases, `develop` for integration, `feature/*` and `release/*` branches for changes.
- Run `swift test` and `swift build -c release` after meaningful changes.
