# Member 2 recovery contract handoff

`shared/contracts.jac` is the single typed source for the recovery objects below. This branch proposes their precise fields for review by Members 1 and 3. It does not implement validation, graph mutation, model calls, or event delivery.

The contract compiled with Jac 0.16.7; the installed byLLM plugin is 0.6.19. No provider call or recovery run has been exercised by this branch.

## Plan and validation

| Type | Meaning |
| --- | --- |
| `RecoveryAction` | `SHED_LOAD` targets a stable load bus ID; `CLOSE_SWITCH` targets a stable switch ID. Actions are intentions, never mutations. |
| `RecoveryPlan` | Active `fault_id`, observed `grid_revision`, ordered actions, concise explanation, and optional affected source ID. The orchestrator must check the fault and revision against current server state. |
| `CandidateAllocationView` | Read-only candidate dispatch, service, signed line transfers, and unserved/shed IDs. Member 1 can project its existing `AllocationResult` into this type. |
| `ValidationResult` | Acceptance, checked revision, specific reasons, and optional candidate allocation/metrics. Rejection may have no candidate if the payload is structurally invalid. |

`SHED_LOAD` and `CLOSE_SWITCH` are the smallest action set supported by the current fixture and planning guide. Add action kinds only when Member 1 can validate and apply them. A physically faulted line cannot conduct merely because its switch is closed. Tier 1 shedding must be rejected by Member 1's validator. `grid_revision` is an observed version, not permission to commit; Member 1 must recheck it and the candidate during application.

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
