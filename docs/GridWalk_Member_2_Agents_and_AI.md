# GridWalk AI — Member 2 Tasks and Instructions

## Role and result

**Role:** Multi-Agent and AI Engineer.  
**Primary coding tool:** Codex. **Backup:** Antigravity.  
**Deliverable:** A Jac walker workflow that detects faults, proposes typed recovery actions, responds to deterministic validation feedback, applies only approved changes through Member 1's core, and explains actual outcomes.

Read [the development guide](GridWalk_AI_Development_Guide.md) and [the shared AI-agent guidelines](GridWalk_AI_Agent_Guidelines.md) before implementation.

**Core invariant:** AI proposes; deterministic Jac code validates; the simulation engine applies.

## Ownership and boundaries

You own Monitor, Planner, and Auditor walkers, recovery-plan schemas, runtime LLM integration, bounded revision/fallback orchestration, agent events, and recovery results. Member 1 owns graph state, arithmetic, validation, and application. Member 3 owns the client and integration coordination.

- Import canonical graph-state types rather than inventing another graph representation.
- Coordinate proposal/feedback types with Member 1 and event/results with Member 3.
- Never let an LLM directly mutate authoritative graph state.
- The deterministic Validator is separate from the three walker roles; it is not another LLM vote.

## Task checklist

### Phase 1 — Agent foundation

1. [ ] Implement Telemetry Monitor Walker to inspect faults and affected loads.
2. [ ] Implement Triage Planner Walker to inspect affected sectors and backup opportunities.
3. [ ] Define the typed recovery proposal contract using stable references.
4. [ ] Configure a tested primary Gemini model through `by llm()`.
5. [ ] Test basic proposals against fixed sample inputs and actual fixture IDs.

### Phase 2 — Collaboration and feedback

6. [ ] Connect proposals to Member 1's deterministic validator.
7. [ ] Preserve specific rejection evidence for invalid plans.
8. [ ] Implement Planner revision using that evidence.
9. [ ] Bound revisions and terminate cleanly when attempts are exhausted.
10. [ ] Implement Incident Auditor Walker for factual incident explanations and logs.

### Phase 3 — Reliability and integration

11. [ ] Configure Groq or OpenAI as backup, subject to tested access and credentials.
12. [ ] Handle API timeouts, rate limits, malformed output, and unavailable models.
13. [ ] Orchestrate a labeled deterministic fallback through the same validator.
14. [ ] Expose ordered events, concise rationales, execution mode, and final results to Member 3.
15. [ ] Test all three core end-to-end workflows with Member 1.

## Walker behavior

### Telemetry Monitor

Traverse the graph and report computed observations: source capability, affected/disconnected demand, physical faults, conducting paths, and overloads. Use Member 1's arithmetic and state projection. Detect line-disconnection effects as well as source overloads.

### Triage Planner

Read the snapshot and available recovery options. Generate a typed action proposal and concise explanation. Submit it for non-mutating validation. On rejection, pass concrete reasons and current facts into a revised proposal while the budget remains. An approved plan must still match current state when Member 1 applies it.

### Incident Auditor

Read the committed actions, final graph, validation evidence, and computed metrics. Explain root cause, switching/shedding actions, preserved critical demand, and residual unmet demand. Do not invent restored capacity, repaired equipment, or engineering guarantees. If audit generation fails after successful recovery, retain the valid recovery and return a factual non-AI summary.

## Proposal and result contracts

Exact field names/enums and installed-version signatures are **Open**. Ratify one typed shared definition.

| Contract | Required meaning |
|---|---|
| `RecoveryPlan` | Fault/context ID, affected source when applicable, ordered typed actions, explanation |
| Action | Recognized type and stable target ID; load actions target loads, switch actions target switches |
| `ValidationResult` | Accept/reject plus specific factual reasons and candidate metrics |
| `RecoveryResult` | Outcome, applied actions, execution mode, before/after metrics, incident summary |
| `AgentEvent` | Actor, event type, concise evidence, outcome; ordering and run correlation recommended |

`SHED_LOAD` and `CLOSE_SWITCH` are illustrative action types from the discussion, not a finalized exhaustive enum. The example IDs in the development guide are not a validated fixture.

### Recovery sequence

```text
Monitor snapshot
  -> primary AI proposal
  -> deterministic validation
       accepted -> current-state check -> apply -> recompute -> audit
       rejected -> specific feedback -> bounded revision
       API/attempt failure -> tested backup within total run budget
       AI still unavailable -> deterministic candidate -> same validator
       no valid candidate -> preserve fault and report infeasibility
```

Do not apply rejected actions, count intended actions as committed, or claim a fallback result was produced by the AI. New faults/reset events must not allow a stale plan to be applied.

## AI implementation instructions

- Use `by llm()` with typed return objects; do not rely on free-form prose or an unconstrained dictionary.
- Use `sem` for LLM-visible function, parameter, return-field, and tool descriptions. Docstrings are human documentation, not the compiler-generated prompt.
- Keep capacity arithmetic, flow allocation, path validity, and final acceptance outside the LLM.
- Use one configuration source for provider/model selection.
- Choose an accessible Gemini Flash model with a real typed-output smoke test. No exact model ID is finalized.
- Test the independent backup provider; a second Gemini model is not an independent provider fallback.
- Verify API-key variable names and supported options against the installed provider adapter.
- Keep secrets server-side and out of source control, browser responses, logs, screenshots, and recordings.
- Log provider/model, attempt, latency, and success/failure without credentials.
- Coding subscriptions do not automatically supply application API access or quota.

### Bound the entire run

Agree a per-request timeout, schema retry limit, revision limit, provider-switch budget, and overall recovery deadline. Include SDK/adapter retries in the total budget. Prevent nested retry loops from stalling the application. Exact limits are **Open**.

### Honest agent activity

Record observations, proposed actions, validation decisions, revisions, applied changes, and final outcomes. Show concise rationales and tool/validation evidence. Do not fabricate private model reasoning or force a rejection to make the demo appear more agentic. A valid first proposal is legitimate; use clearly labeled invalid-plan tests for guaranteed feedback-path coverage.

## Interfaces and handoffs

| Direction | Contract/operation |
|---|---|
| Consume Member 1 | `get_grid_state()`, `validate_plan(plan)`, and the internal approved-plan apply operation |
| Provide Member 3 | `run_triage(fault_id)`, `get_agent_events()`, final result and mode |
| Coordinate with Member 1 | Typed proposal, specific rejection evidence, fallback candidate generation/application split |
| Coordinate with Member 3 | Response envelope, ordering/run IDs, busy/error/infeasible states, event delivery |

These are logical names, not fixed REST paths. Keep deterministic fallback candidate generation ownership explicit with Member 1; do not duplicate competing allocation algorithms in orchestration.

## Development checkpoints

All times are Sri Lanka time on 17 October 2026; intermediate targets are team recommendations.

| Target | Your contribution |
|---|---|
| 9:00–9:30 AM | Ratify proposal/feedback contract, version, provider configuration, and budgets |
| 10:30 AM | Monitor/planning interface joins the first graph/UI integration |
| 11:30 AM | Basic typed planning works |
| 12:30 PM | One AI scenario passes through deterministic validation and application |
| 1:30 PM | Validation/revision loop works |
| 2:30 PM | Events, audit, fallback, and final result integrated into dashboard |
| 3:45 PM | Feature freeze; fix failures and verify actual model behavior |

## Completion checks

- [ ] Fixed-output tests cover valid proposal, rejection/revision, exhausted attempts, and malformed output.
- [ ] Real-provider typed planning is tested separately from fixed-output tests.
- [ ] Primary failure, backup failure, and all-options-fail paths terminate within budget.
- [ ] Every candidate, including fallback, passes through the same validator.
- [ ] All three scenarios have reproducible graph outcomes with Member 1.
- [ ] Events and results clearly separate proposed, rejected, and applied actions.
- [ ] Audit failure cannot invalidate a successful committed recovery.
- [ ] Jac checks and relevant runtime tests pass; handoff identifies tested provider/model and remaining limitations.

## Official competition requirements

Source: **AI Hackathon 2026 Sri Lanka.pdf**, schedule p. 4, submission p. 8, eligibility p. 9.

- Every member registers and checks in on the day; teams have three people and submit one project.
- All project coding happens during hacking hours; brainstorming beforehand is permitted and repositories are checked.
- Hacking begins at 9:00 AM; submission and the working demo video are due by **5:30 PM on 17 October 2026**.
- Working software must meaningfully use Jac, with at least **80% of the code in Jac**.
- Submit through the shared organizer link on time; late entries cannot win.
- Provide GitHub link, working demo video, and a written description of Jac/Jaseci usage; star [the official Jac repository](https://github.com/jaseci-labs/jac).
- Build in good faith; project misrepresentation causes disqualification.
- Jac Hammer hosting is **encouraged, not required**.

The brief does not define the 80% measurement method or explicitly settle AI coding-tool permissions. Confirm interpretation with organizers rather than assuming either prohibition or guaranteed approval.

## Your contribution to judging

Official criteria: p. 7 of the brief, with no published weights. The following evidence is a team recommendation.

| Official criterion | Evidence you should enable |
|---|---|
| Technical execution | Bounded requests, typed outputs, tested failures, and reliable orchestration |
| Excellent use of Jac/Jaseci | Walkers, typed `by llm()` calls, and meaningful `sem` context |
| Creativity and innovation | Constraint-aware recovery with explainable tradeoffs |
| Depth of agentic behaviour | Observation, proposal, specific feedback, genuine revision, verified application |
| Impact and novelty | Critical-demand prioritization supported by computed results |
| Clear presentation/demo video | Readable events, honest execution-mode labels, concise incident account |

Do not substitute a single prompt plus fabricated logs for agent collaboration. Do not claim a real rejection or provider switch that was not observed. Help Member 3 capture a truthful working demo; the recommended two-minute format and 5:00 PM submission buffer are team choices, not official rules.
