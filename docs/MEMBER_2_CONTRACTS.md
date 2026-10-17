# Member 2 recovery contract handoff

`shared/contracts.jac` is the single typed source for the recovery objects below. The Member 1 validator and application handoff is settled here. Member 1 still owns its implementation; the Member 3 event transport remains a later integration decision.

The contract compiled with Jac 0.16.7; the installed byLLM plugin is 0.6.19. No provider call or recovery run has been exercised by this branch.

## Plan and validation

| Type | Meaning |
| --- | --- |
| `RecoveryAction` | `SHED_LOAD` targets a stable load bus ID; `CLOSE_SWITCH` targets a stable switch ID. Actions are intentions, never mutations. |
| `RecoveryPlan` | Active `fault_id`, observed `grid_generation_id` and `grid_revision`, ordered actions, concise explanation, and optional affected source ID. The generation and revision identify the observed graph snapshot. |
| `CandidateAllocationView` | Read-only candidate dispatch, service, signed line transfers, and unserved/shed IDs. Member 1 can project its existing `AllocationResult` into this type. |
| `ValidationResult` | Acceptance, checked generation and revision, specific reasons, and optional candidate allocation/metrics. Rejection may have no candidate if the payload is structurally invalid. |

`SHED_LOAD` and `CLOSE_SWITCH` are the smallest action set supported by the current fixture and planning guide. Add action kinds only when Member 1 can validate and apply them. A physically faulted line cannot conduct merely because its switch is closed. Tier 1 shedding must be rejected by Member 1's validator. The snapshot fields are observations, not permission to commit.

### Member 1 Task 4/5 handoff: ready to implement

- `SHED_LOAD.target_id` is a **load bus ID** (`LOAD-*`); `CLOSE_SWITCH.target_id` is a **switch ID** (`SW-*`). Unknown IDs, wrong target kinds, duplicate or conflicting actions, and unsupported action types get factual rejection reasons. Both actions refer to the existing grid; a switch closure never repairs a physically faulted line.
- `GraphState.generation_id` is an opaque UUID assigned when a healthy fixture is built. `reset_simulation()` builds a new generation with revision 0. A plan copies this value into `RecoveryPlan.grid_generation_id`. `fault_id`, generation ID, and revision must all match the authoritative grid. Checking only fault and revision would allow an old plan after reset and reinjection of the same fault.
- Member 1's non-mutating entry point is `validate_plan(plan: RecoveryPlan) -> ValidationResult` in `grid/validation.jac`. It reads the current graph and rejects a mismatched fault, generation, or revision before previewing actions. `checked_generation_id` and `checked_revision` report the snapshot it checked. Acceptance requires no reasons and a complete candidate. Rejection has `accepted=False`, at least one specific reason, and no candidate when no valid preview exists. Validation does not mutate nodes, edges, or the revision.
- Translate ordered actions into `switch_overrides: dict[str, bool]` and `shed_load_ids: set[str]`, then use `preview_allocation(grid, switch_overrides, shed_load_ids)`. `CandidateAllocationView` copies `AllocationResult.source_dispatch_kw`, `.served_load_kw`, `.line_transfer_kw`, `.unserved_load_ids`, and `.deliberately_shed_ids` by value. `candidate_metrics` must describe that same candidate, rather than the old committed graph.
- Member 1's Task 5 entry point is `apply_approved_plan(plan: RecoveryPlan) -> GraphState` in `grid/simulation.jac`. It rechecks fault/generation/revision and reruns validation against the current state as part of one application operation; the caller's earlier `ValidationResult` is evidence, not commit authority. Only a fresh accepted candidate may be committed. On rejection, raise a factual error and leave state unchanged. On success, commit actions/candidate, increment revision once, and return the recomputed authoritative `GraphState` with the physical fault retained.
- A repeated application of the same plan is stale after the first revision increment and must leave state unchanged. A reset followed by the same fault is stale because the generation changes. Member 2's orchestration will handle these rejected operations as non-applied outcomes.

## Run and event records

| Type | Meaning |
| --- | --- |
| `ExecutionMode` | `none` before any candidate is applied, otherwise the provider that produced the applied candidate: primary AI, backup AI, or deterministic fallback. |
| `RecoveryOutcome` | `no_action` for a healthy/no-op run; `recovered` when all demand is served; `partial` when a valid committed plan leaves noncritical unmet demand; `infeasible` when critical demand cannot be preserved; `failed` for no valid applied result or a run error. Final classification must use computed metrics. |
| `AgentEvent` | Run ID plus monotonic sequence, actor, kind, outcome, concise summary, and optional factual evidence. Proposed/rejected actions must never be labeled applied. |
| `RecoveryResult` | Run/fault IDs, outcome and execution mode, only committed actions, authoritative before/after `GridMetrics`, summary, proposal/revision counts, elapsed milliseconds, and optional failure reason. |

`run_id` identifies one recovery attempt. Events for a run must be returned in `sequence` order; the server assigns the ID and sequence. Reset or another fault must prevent an older run from applying a plan. Member 3 can use the same ID to discard stale responses. The Auditor must summarize committed state; if its AI wording fails, deterministic code should produce a factual summary without undoing a valid commit.

## Integration decisions to confirm

- **Member 1:** `validate_plan` input/output signature, projection of `AllocationResult`, explicit rejection reasons, and approved application signature. Confirm stale revision and duplicate application behavior. `ValidationResult` is proposed here to unblock this handoff; the validator remains Member 1's code.
- **Member 3:** whether `get_agent_events` returns all events or filters by `run_id`, whether polling is enough, and the `run_triage` response envelope. The event fields and enum values are ready for the dashboard adapter to review.
- **Team:** confirm whether whole-load `SHED_LOAD` plus `CLOSE_SWITCH` covers the three scenarios. Any new action kind needs a matching deterministic validator and application path.

Do not copy these objects into module-specific dictionaries or infer successful recovery from a typed LLM response. This branch supplies contracts only; scenario metrics and provider behavior remain unverified.
