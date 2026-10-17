# Member 2 — Agents and AI Task List

Scope: implement the Jac Monitor, Planner, and Auditor walkers, typed recovery proposals, bounded AI calls, recovery orchestration, factual events, and final results. Member 1 owns graph arithmetic, validation, approved application, and deterministic fallback candidate generation. Member 3 owns the dashboard and client adapter. The governing rule is: **AI proposes; deterministic Jac code validates; the simulation engine applies.**

This list reflects `dev` at commit `84f1164`. Member 1 has merged `GraphState`, three fault scenarios, and a non-mutating allocation preview. `grid/validation.jac` and approved-plan application are still placeholders. Do not claim an end-to-end recovery until those operations are available and integrated.

## Branch workflow

Create each implementation branch from the latest merged `origin/dev`, in the order below. Push each completed branch separately; the human team creates its PR into `dev`. Start dependent work from updated `dev` after the preceding PR merges. Keep Member 2 code in Jac (`agents/` and shared Jac contracts); add no Python or TypeScript application layer. Track the actual Jac code share before submission and confirm the organizer's interpretation of the 80% rule. Documentation and configuration should stay small and honest.

| Order | Branch | Deliverable | Dependency | Status |
| --- | --- | --- | --- | --- |
| 0 | `member2/00-task-list` | This task list and handoff sequence | Current `dev` | Ready for PR |
| 1 | `member2/01-recovery-contracts` | Shared typed actions, plans, feedback, events, and results | Member 1 handoff; Member 3 event transport later | Member 1 validation/application handoff ready on `member2/01b-validation-handoff` |
| 2 | `member2/02-telemetry-monitor` | Graph-traversing Monitor with factual fault observations | `GraphState` and fixture IDs | Code implemented; runtime verification pending |
| 3 | `member2/03-typed-planner` | Typed `by llm()` proposal path and primary Gemini smoke test | Tasks 1–2; provider access | Jac code implemented; live provider check pending key |
| 4 | `member2/04-validation-revision` | Validation, bounded revision, current-state application orchestration | Member 1 validation/application; Tasks 1–3 | To do |
| 5 | `member2/05-auditor-events` | Auditor, ordered events, final result and read API | Task 4; Member 3 envelope agreement | To do |
| 6 | `member2/06-fallback-budgets` | Request budgets, backup provider, deterministic fallback handling | Tasks 4–5; tested provider access | To do |
| 7 | `member2/07-scenario-integration` | Three scenario handoff and failure-path evidence | Members 1 and 3 integrations | To do |

## 1. Shared recovery contracts

- Extend the existing `shared/contracts.jac`; import Member 1's `GraphState` rather than copying it.
- Define typed action targets by stable ID, ordered `RecoveryPlan` actions, `ValidationResult` with specific rejection reasons and candidate evidence, `AgentEvent`, and `RecoveryResult` with execution mode, applied actions, and before/after metrics.
- Agree action enum, target kinds, revision/stale-plan field, validation/application signatures, failure envelope, run ID, event sequence, and reset/duplicate-request behavior with Members 1 and 3. Do not turn the development guide's illustrative IDs into fixture facts.
- **Done when:** one Jac contract is usable by the Planner, Member 1 validator, and Member 3 adapter; field names and open decisions are recorded.

## 2. Telemetry Monitor

- Implement a Jac walker in `agents/monitor.jac` that traverses the current graph and reports source capability, faults, affected or disconnected loads, and available conducting routes.
- Use Member 1's `GraphState`, fixture IDs, and computed allocation facts. Detect line faults and isolation as well as source deficits. Keep final capacity and flow judgments in Member 1's deterministic core.
- **Done when:** healthy state yields no invented incident; each named fault yields reproducible factual observations suitable for a Planner input.

## 3. Typed Planner and primary provider

- Implement the Planner walker in `agents/planner.jac` with a typed `by llm()` return and meaningful `sem` descriptions for the visible facts, actions, and response fields.
- Keep provider/model settings in one server-side place. Verify the installed Jac/byLLM versions, Gemini model access, key variable, and typed output with a real smoke test. Use fixed proposals separately for repeatable checks.
- The model may propose actions and a concise rationale; it must not mutate the graph, perform allocation arithmetic, or decide final acceptance.
- **Done when:** a proposal using actual fixture IDs reaches the typed contract; report the model and access that were actually tested.

## 4. Validation, revision, and application

- Implement `run_triage(fault_id)` orchestration in `agents/orchestration.jac`: Monitor facts → Planner proposal → Member 1's non-mutating validator → specific feedback → bounded revision.
- Apply only an accepted candidate through Member 1's approved-plan operation, with a current graph revision check. A rejected, malformed, stale, or exhausted proposal must leave authoritative state unchanged.
- Never force a rejection to create an agent story. Use labeled invalid fixed proposals to prove feedback and revision handling.
- **Done when:** one real or fixed proposal can pass validation and application; invalid and exhausted paths terminate with factual outcomes and no invalid mutation.

## 5. Auditor, events, and result API

- Implement the Auditor walker in `agents/auditor.jac` from committed actions, actual validation evidence, final `GraphState`, and before/after metrics.
- Emit ordered, run-correlated events for observation, proposal, rejection, revision, application, fallback, and audit. Distinguish proposed actions from applied actions and primary AI from fallback modes.
- Provide the agreed `get_agent_events()` and recovery-result envelope to Member 3. If AI audit wording fails after a valid commit, return a factual Jac-generated summary without undoing recovery.
- **Done when:** the timeline and result agree with server state and Member 3 can render them without inventing metrics.

## 6. Budgets and fallback

- Bound each request, schema retry, plan revision, provider switch, and total recovery run; include adapter retries in the total budget.
- Test an independent Groq or OpenAI backup if credentials and access are available. Route Member 1's deterministic fallback candidate through the same validator, and label its execution mode accurately.
- Handle timeouts, rate limits, malformed output, unavailable models, and all-options-fail without hanging or applying an invalid plan. Never expose API keys in client data or logs.
- **Done when:** the observed primary, backup, deterministic, and failure paths terminate within the agreed limits; report any provider path that could not be tested.

## 7. Scenario integration and handoff

- Exercise source derating, line failure, and insufficient backup with Members 1 and 3. Verify one valid recovery, specific rejection/revision, and an infeasible outcome where applicable.
- Check stale reset/new-fault behavior, duplicate run requests, and auditor failure. Keep faults and unmet demand visible when service cannot be restored.
- Run Jac checks and meaningful runtime checks for the changed code. Record actual scenario IDs, provider/execution mode, observed metrics, and remaining limits. Measure the Jac code share honestly; the official counting method remains open.
- **Done when:** the server and dashboard tell the same factual story for all three scenarios, and Member 3 has the event/result contract and evidence needed for the demo.

## Immediate handoffs

1. **Member 1:** Task 4 can proceed from the [validation/application handoff](MEMBER_2_CONTRACTS.md#member-1-task-45-handoff-ready-to-implement) once `member2/01b-validation-handoff` is merged. Action targets, validator output, application behavior, and reset-safe stale-plan fields are specified there. Deterministic fallback candidate ownership stays with Member 1 for later integration.
2. **Member 3:** agree `run_triage` result envelope, event ordering/run IDs, polling or streaming, execution mode labels, and busy/reset behavior before Task 5.
3. **Provider access:** select a Gemini Flash model only after typed output succeeds for the actual account; confirm whether a separate backup provider can be tested. Keep keys outside the repository.

For every branch handoff, report changed files, exact checks run, fixture and execution mode used, observed result, limitations, and the next dependency. A compiler pass alone does not prove provider calls or a recovery outcome.
