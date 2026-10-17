# Verification checkpoint: 17 October 2026

The supported environment is Ubuntu WSL 2 with native Jac 0.34.13.
`bash scripts/verify_wsl.sh` passed the complete client scan (36 local files,
including two pre-existing untracked presentation drafts), all 29 client runtime
checks, all 49 existing server tests, the web build, and the sealed app build.
The `grid/metrics.jac` native optimization fallback is informational; that module
runs in the server codespace. No type-check gate was disabled.

The old adapter draft now delegates to canonical grid/recovery clients and their
shared transport. It no longer uses unsupported `AbortSignal.timeout` typing or
draft `expected_version` request fields. The active dashboard keeps the same
canonical operations and validation boundary.

## Product browser verification

Chrome headless accessed the sealed `dist/gridwalk-ai.jab` served by WSL at
`http://127.0.0.1:8011`. The preview, live fault/reset, and product recovery
scripts passed. Screenshots and machine-readable results are written to ignored
`.jac/console-verification/`.

| Scenario | Observed execution | Outcome | Served | Unmet | Critical served |
|---|---|---|---|---|---|
| Source capacity reduction | Deterministic fallback | Partial | 180 kW | 25 kW | 100% |
| Physical line fault | Deterministic fallback | Partial | 180 kW | 25 kW | 100% |
| Backup shortage | Deterministic fallback | Partial | 155 kW | 50 kW | 100% |

Each product run had seven ordered events. The checks confirmed the real server
result against the UI, run correlation, one recovery request on duplicate input,
busy controls, persistence after navigation, reset clearing, retained faults,
and no browser console errors or warnings. The fixed-proposal fixture separately
tests rejection/revision and an exhausted infeasible run. A rejected fixture
proposal does not establish that all possible recovery plans are infeasible.

Responsive checks passed at 1440, 1024, 768, and 375 pixel widths. The diagram
scrolls inside its panel. Four font faces and sixteen preview SVGs loaded.
Keyboard checks cover native scenario selection, recovery activation, evidence
focus/scrolling, and the skip link. The accessibility tree exposes named controls
and ordered evidence; reduced motion prevents the preview animation. These are
targeted accessibility checks, not a full screen-reader or WCAG certification.

Three consecutive local navigations with browser cache enabled and no CPU/network
throttling measured DOMContentLoaded at 78.8, 57.4, and 50.2 ms; load completed at
79.0, 57.6, and 50.5 ms. Resource transfer was 2,750,330 bytes per navigation.
These are local load observations, not hosted latency, FPS, or Core Web Vitals
claims. Paint and layout-shift values were unavailable in this run.

## Reproduce

Run verification servers one at a time because source entries share client build
output. Never run simulation-mutating checks against a shared demo in use.

```bash
bash scripts/verify_wsl.sh
jac start dist/gridwalk-ai.jab --port 8011
```

From Windows, while that server is ready:

```powershell
.venv/Scripts/python.exe scripts/verify_console.py http://127.0.0.1:8011
.venv/Scripts/python.exe scripts/verify_live_console.py http://127.0.0.1:8011
.venv/Scripts/python.exe scripts/verify_grid_api.py http://127.0.0.1:8011
.venv/Scripts/python.exe scripts/verify_recovery_console.py http://127.0.0.1:8011
```

For fixed proposals, stop that server and start `jac start recovery_verify.jac
--port 8013`, then run `verify_recovery_api.py http://127.0.0.1:8013` and
`verify_recovery_console.py http://127.0.0.1:8013 --fixture`. This entry is only for
local verification; `main.jac` remains the product entry.

## Remaining external dependencies

The actual typed Gemini probe returned `API_KEY_INVALID`; Groq authentication
returned HTTP 401. A model-list response alone did not verify inference. Supply
valid local credentials, restart, and run `scripts/verify_provider_plan.jac`
before describing a demo as a live AI run. The product remains usable through
honestly labeled deterministic fallback. Provider failures do not bypass
validation or expose raw provider errors in product events.

Hosting is optional and has not been deployed. Judge-accessible video upload,
team registration/check-in, organizer interpretation of the Jac percentage,
repository starring, and final form receipt require the team's actual accounts
and organizer link. See the submission package for ready-to-use material.
