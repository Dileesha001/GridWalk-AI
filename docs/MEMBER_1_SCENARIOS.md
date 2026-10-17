# Member 1 Task 6 — scenario and fallback handoff

The fixed Jac test proposals in this document are deterministic simulation data, not live AI output. The grid remains a fictional, lossless kW model.

## Fallback interface

`grid/fallback.jac` exports `generate_fallback_plan(observed: GraphState) -> RecoveryPlan | None` for Member 2. Pass the `GraphState` observed for the current fault. The function returns `None` for a healthy grid, a changed generation/revision/fault, an already committed allocation, or when no validator-accepted proposal exists. It never mutates graph state.

The generator enumerates closures of healthy open switches and optional noncritical whole-load sheds in stable ID order. The committed fixture has three open ties and five noncritical loads, so it examines at most 256 action sets. Each nonempty action set goes through `validate_plan`. Among accepted plans, it maximizes served kW, then minimizes deliberate shed kW, then action count. This is a bounded search over actions using the existing greedy allocation preview; it does not claim a globally optimal power flow. Unserved demand without a `SHED_LOAD` action is reported as **unmet**, not deliberate shedding.

Member 2 must validate the returned plan again against the current graph before applying it through `apply_approved_plan`. Member 2 owns timeout/provider handling and the `ExecutionMode.DETERMINISTIC` label and events. A `None` result leaves the fault and unmet demand visible; it must not be reported as a successful recovery.

## Observed fixed-proposal outcomes

All values below are after applying a current, validator-accepted fallback plan to a fresh named fault. The healthy fixture serves 205 kW with no unmet demand. Each result retains its active fault and preserves all 105 kW of Tier 1 demand.

| Fault | Proposed switch closures | Served / unmet kW | Unserved loads | Deliberate shed kW |
|---|---|---:|---|---:|
| `FAULT-SOURCE-A` | `SW-TIE-B-A`, `SW-TIE-B-H`, `SW-TIE-R-A` | 180 / 25 | `LOAD-OFFICE` | 0 |
| `FAULT-LINE-A-H` | `SW-TIE-B-A`, `SW-TIE-B-H` | 180 / 25 | `LOAD-HOMES` | 0 |
| `FAULT-INSUFFICIENT-BACKUP` | `SW-TIE-B-H` | 155 / 50 | `LOAD-HOMES`, `LOAD-OFFICE` | 0 |

The insufficient-backup fault reduces total available source capacity to 175 kW, below 205 kW total demand, so complete restoration is impossible in that scenario. The deterministic preview serves 155 kW and leaves 50 kW unmet. The line-fault candidate closes a healthy alternate tie while `LINE-A-H` remains physically faulted and carries zero transfer.

`tests/scenario_checks.jac` verifies these values, nonmutation during proposal, current validation and application, stale reset rejection, duplicate prevention, and a test-only blocked alternate path that returns `None` without clearing the physical fault. It also passes fixed fallback proposals through Member 2's `_run_triage_with_planner` helper for all three named faults; this does not exercise provider budgets, event modes, or the live dashboard.

## Verification on the Task 6 branch

Jac 0.34.13 in WSL: `jac check grid/ tests/scenario_checks.jac agents/orchestration.jac shared/contracts.jac -n` passed all 10 checked files. `jac test tests/*_checks.jac -v` passed all 43 tests, including seven new scenario checks. The WSL runtime needed the project's declared `python-dotenv` dependency to import Member 2's planner; it was installed with `jac install python-dotenv --no-save --no-npm --no-dev` without changing `jac.toml`.

## Remaining joint integration

- Member 2: call `generate_fallback_plan` after provider options fail or exhaust, revalidate and apply only a current accepted plan, label the deterministic mode, and test budgets/events.
- Member 3: consume authoritative state, fault/reset, recovery result, and ordered events in live controls. The read-only preview does not prove this path.
- Joint run: verify the same three metrics and retained faults in the dashboard, including a no-candidate failure, reset, and duplicate requests.
