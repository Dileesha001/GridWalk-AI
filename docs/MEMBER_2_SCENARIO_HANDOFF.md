# Member 2 Step 7: scenario and result handoff

`run_triage(fault_id)` is the server entry point. When primary Gemini and backup Groq do not apply a plan, it calls Member 1's merged `generate_fallback_plan(observed)` once before the run deadline. A returned plan is checked against the current generation and revision, passed to `validate_plan`, and committed only by `apply_approved_plan`. A `None`, stale, rejected, or expired candidate commits nothing. A committed candidate uses `RecoveryResult.execution_mode = deterministic`; all uncommitted runs use `none`. Ordered fallback events identify the Groq switch and deterministic switch separately.

## Reproducible scenario evidence

On Jac 0.34.13 under WSL, `scripts/step07_scenario_smoke.jac` used labeled fixed failures for both AI planners. These numbers therefore prove the deterministic path and Member 1's current fixture, not a live AI response. Each run began with a reset, retained its active fault, recorded seven ordered events, and stored a result under its `run_id`.

| Fault ID | Result | Served kW | Unmet kW | Critical preserved | Revision |
| --- | --- | ---: | ---: | ---: | ---: |
| `FAULT-SOURCE-A` | `applied`, `deterministic`, `partial` | 100 → 180 | 105 → 25 | 42.86% → 100% | 1 → 2 |
| `FAULT-LINE-A-H` | `applied`, `deterministic`, `partial` | 145 → 180 | 60 → 25 | 42.86% → 100% | 1 → 2 |
| `FAULT-INSUFFICIENT-BACKUP` | `applied`, `deterministic`, `partial` | 100 → 155 | 105 → 50 | 42.86% → 100% | 1 → 2 |

The `partial` outcome means unmet demand remains. The simulated fault is never described as physically repaired. For the line fault, `LINE-A-H` remains faulted even after a healthy tie carries recovery power. For insufficient backup, the final 50 kW unmet demand must stay visible in the client.

`tests/agent_integration_checks.jac` exercises the three deterministic scenarios and event/result polling; a fixed invalid switch followed by accepted revision; a blocked tie with no feasible fallback or application; reset during planning; a different-fault request while a fault is active; duplicate recovery; auditor failure after a valid commit; and an expired deterministic deadline. The different-fault request follows Member 1's `inject_fault` contract: it raises `ValueError("Reset simulation before injecting another fault")` and leaves the current graph unchanged. The client should present that as a request error and refresh authoritative state. A reset during a run leaves the older run accessible by its explicit `run_id`, while the default event poll for the new generation is empty.

Verification on 2026-10-17 after merging Member 3's dashboard: `jac check . -n` passed 60 files, `jac test tests/*_checks.jac` passed all 54 server checks, the recovery client decoder suite passed 9 checks, and `jac build --client web main.jac` succeeded. All used Jac 0.34.13 in WSL. The three-scenario smoke script completed separately with the metrics above. The browser recovery flow has not been rerun against this branch.

## Member 3 adapter contract

- Call `run_triage(fault_id)` and retain `TriageResult.run_id`; display `recovery_result` and authoritative `after_state` from that response.
- Poll `get_agent_events(run_id)` for that run, or `get_agent_events()` for the latest completed run in the current grid generation. Events are persisted together when the run finishes, with sequence numbers starting at 1. `get_recovery_result(run_id)` returns the same stored final result.
- Render `PROPOSAL` actions as proposed, `VALIDATION` as validator evidence, and `APPLICATION` actions as committed. Only `RecoveryResult.applied_actions` and the application event prove a graph change.
- Show `execution_mode` from the final result. `none` means no action was committed, even if proposals or fallback attempts occurred. Show actual before/after metrics and active faults, including residual unmet demand.
- The live dashboard transport and correlated event/result display are merged from Member 3. This branch extends the client decoder to accept the server's `budget_exhausted` and `fallback_failed` statuses. Keep duplicate/conflicting controls blocked during a request and discard older asynchronous responses after reset or a newer request. Fresh browser recovery checks remain outstanding.

## Jac share and limits

A source-file count on this branch after the merged dashboard changes, including Jac, Python, shell, and CSS files but excluding generated and ignored directories, found 60 Jac files / 5,398 Jac lines and 9 other source files / 641 other lines. That is **89.39% Jac by physical lines** and **87.99% by bytes** under this stated method. The organizer's official counting method has not been confirmed. The Python and shell files are setup/verification helpers; the CSS file is presentation support.

The fixed checks do not establish concurrent-run behavior or a fresh browser recovery. Primary Gemini and live Groq paths were checked earlier; repeat live-provider acceptance is probabilistic. The server's 65-second deadline is checked before applying a fallback candidate, but a synchronous candidate search cannot be interrupted mid-call. Member 3's merged dashboard covers basic busy and stale-response handling; recovery concurrency and browser verification remain open.
