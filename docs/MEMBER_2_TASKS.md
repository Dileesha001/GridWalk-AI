# Member 2 — Agents and AI Task List

Scope: implement the Jac Monitor, Planner, and Auditor walkers, typed recovery proposals, bounded AI calls, recovery orchestration, factual events, and final results. Member 1 owns graph arithmetic, validation, approved application, and deterministic fallback candidate generation. Member 3 owns the dashboard and client adapter. The governing rule is: **AI proposes; deterministic Jac code validates; the simulation engine applies.**

Member 1's validator and approved-plan application are merged. The Jac 0.34.13 migration and Member 2 Steps 4–5 are merged; Step 4 has fixed-proposal runtime coverage and one successful live Gemini line-fault recovery. Step 5 adds the Auditor and event/result API, but runtime polling and dashboard integration remain unverified. Step 6 adds bounded Gemini/Groq routing; deterministic fallback awaits Member 1. Do not claim an end-to-end dashboard recovery yet.

## Branch workflow

Create each implementation branch from the latest merged `origin/dev`, in the order below. Push each completed branch separately; the human team creates its PR into `dev`. Start dependent work from updated `dev` after the preceding PR merges. Keep Member 2 code in Jac (`agents/` and shared Jac contracts); add no Python or TypeScript application layer. Track the actual Jac code share before submission and confirm the organizer's interpretation of the 80% rule. Documentation and configuration should stay small and honest.

| Order | Branch | Deliverable | Dependency | Status |
| --- | --- | --- | --- | --- |
| 0 | `member2/00-task-list` | This task list and handoff sequence | Current `dev` | Merged |
| 1 | `member2/01-recovery-contracts` | Shared typed actions, plans, feedback, events, and results | Member 1 handoff; Member 3 event transport later | Merged; Member 1 handoff accepted |
| 2 | `member2/02-telemetry-monitor` | Graph-traversing Monitor with factual fault observations | `GraphState` and fixture IDs | Merged; line-fault observations exercised through Step 4 |
| 3 | `member2/03-typed-planner` | Typed `by llm()` proposal path and primary Gemini smoke test | Tasks 1–2; provider access | Merged; live Gemini proposal repeated on Jac 0.34.13 |
| 4 | `member2/04-validation-revision` and `member2/04b-orchestration-runtime` | Validation, bounded revision, current-state application orchestration | Member 1 validation/application; Tasks 1–3 | Fixed paths passed 8/8; one live line-fault plan validated and applied; 04b branch ready for PR |
| 5 | `member2/05-auditor-events` | Auditor, ordered events, final result and read API | Task 4; Member 3 envelope agreement | Merged; Jac compile passed; runtime polling and Member 3 integration pending |
| 6 | `member2/06-fallback-budgets` | Request budgets, backup provider, deterministic fallback handling | Tasks 4–5; tested provider access | Gemini/Groq routing and budgets implemented; deterministic candidate awaits Member 1; live backup unverified |
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

1. **Member 1:** validation and approved application are integrated. Provide the non-mutating deterministic fallback candidate described in [Step 6 handoff](MEMBER_2_FALLBACK_BUDGETS.md); its generation remains Member 1's responsibility.
2. **Member 3:** review the proposed polling and result contract in [Step 5 handoff](MEMBER_2_AUDITOR_EVENTS.md), then integrate it into the dashboard. Client busy and stale-response behavior still need integration.
3. **Provider access:** Gemini typed output and one accepted line-fault run passed on Jac 0.34.13 before Step 6. Groq backup is wired but awaits a saved local `GROQ_API_KEY` and live access check. Keep keys outside the repository.

For every branch handoff, report changed files, exact checks run, fixture and execution mode used, observed result, limitations, and the next dependency. A compiler pass alone does not prove provider calls or a recovery outcome.
