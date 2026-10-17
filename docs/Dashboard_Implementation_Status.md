# Dashboard implementation order

Work proceeds one milestone at a time. A preview being complete does not mean
live simulation or recovery is connected.

| Step | Task | Status and evidence |
|---|---|---|
| 1 | Requirements, ownership, and invariants | Done. Server authority and deterministic approval remain intact. |
| 2 | Jac environment and application setup | Done, migrated to required Jac 0.34.13 on WSL 2. Native binary pinned and checksum verified; 33 static checks, 15 client runtime tests, 28 simulation tests, web build, and sealed app build pass. |
| 3 | Preview foundation and payload validation | Done for preview. Nine runtime tests pass, including the response-envelope fix. Canonical live decoding is part of Step 6. |
| 4 | Dashboard shell | Done for the healthy Figma console. Presentation is authored in Jac; responsive browser checks pass. |
| 5 | Read-only topology and inspection | Done. Four fixed snapshots, twelve buses, component/line inspection, retained physical faults, and six topology runtime tests. |
| 6 | Live grid reads, fault/reset controls, and measured metrics | Done locally. Canonical payload validation, all three fault scenarios, reset, fresh reads, server metrics, and separate fixed previews. Reset persistence regression fixed and checked over HTTP. See [verification](Live_Grid_Integration.md). |
| 7 | Recovery controls, ordered events, and incident outcomes | Implemented locally. Canonical orchestration, correlated ordered events, execution mode, committed actions, and before/after measurements are connected. Deterministic runtime and HTTP checks pass; fresh browser and live-provider verification remain pending. See [recovery integration](Recovery_Integration.md). |
| 8 | Busy, rejection, revision, error, fallback, and stale-response handling | Stale recovery requests now carry the observed generation and revision; the server rejects mismatches before planning. Client busy/timeout guards, rejection evidence, and refresh recovery are in place. Provider/deterministic fallback and cross-tab concurrency remain pending. |
| 9 | End-to-end scenarios and performance/accessibility verification | Partly covered: live fault/reset browser flows and responsive layouts pass; preview keyboard/reduced-motion checks pass. Full recovery workflows and measured performance remain pending. No FPS claim is made. |
| 10 | Final run instructions, optional deployment, demo, and submission artifacts | Pending final verification. Local setup instructions already exist; hosting is not verified. |

The current checkpoint connects Step 7 and preserves the fixed preview workflow.
See [live integration verification](Live_Grid_Integration.md) for the current
checks, and [design review](Design_Review.md) for the earlier Figma console work.

The new [WSL setup requirement](WSL_Setup.md) supersedes the earlier Windows
compiler setup. The migration is included in the current dashboard update.

Steps 1–5 and the WSL migration were pushed earlier. Step 6 is included in this
dashboard milestone. PR creation remains with the user.
