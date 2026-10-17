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
| 6 | Live grid reads, fault/reset controls, and measured metrics | Next. Adapt the transport boundary to shared contracts, register/consume the actual endpoints, and refresh authoritative state after operations. |
| 7 | Recovery controls, ordered events, and incident outcomes | Pending. Consume actual recovery orchestration, run IDs, event sequence, execution mode, and before/after results. Match the remaining Figma screens without inventing events. |
| 8 | Busy, rejection, revision, error, fallback, and stale-response handling | Pending. Prevent duplicate/conflicting operations and ensure older responses cannot replace current state. |
| 9 | End-to-end scenarios and performance/accessibility verification | Pending for live workflows. Preview browser verification is already complete; no FPS or end-to-end recovery claim is made. |
| 10 | Final run instructions, optional deployment, demo, and submission artifacts | Pending final verification. Local setup instructions already exist; hosting is not verified. |

The current checkpoint completes the healthy console redesign and preserves the
preview workflow. See [design review and verification](Design_Review.md) for
files, checks, deliberate differences, and remaining limitations.

The new [WSL setup requirement](WSL_Setup.md) supersedes the earlier Windows
compiler setup. The migration is included in the current dashboard update.

Existing foundation/shell/topology milestones were pushed earlier. The healthy
Figma console refresh and decoder regression fix are included in the current
dashboard milestone. PR creation remains with the user.
