# GridWalk AI — Instructions and Guidelines for AI Coding Agents

## Purpose and use

This file guides AI coding assistants implementing GridWalk. It is distinct from the application's Monitor, Planner, and Auditor walkers.

Read [the development guide](GridWalk_AI_Development_Guide.md), the instruction file for your assigned member, and the actual repository instructions before changing project code:

- [Member 1 — Graph and Simulation](GridWalk_Member_1_Graph_and_Simulation.md)
- [Member 2 — Agents and AI](GridWalk_Member_2_Agents_and_AI.md)
- [Member 3 — UI, Integration, and Deployment](GridWalk_Member_3_UI_Integration_and_Deployment.md)

These files are handoff documents. This file does not replace an existing repository `AGENTS.md`, authorize unrelated actions, or grant access to other members' accounts. In the current ChatGPT project mirror, files under `sources/` are read-only; do not edit, move, rename, or delete them. Work in the implementation location designated by the human team.

## 1. Product objective and fixed boundaries

Build a compact Jac microgrid recovery decision-support simulator. The application should detect simulated faults, propose recovery actions, validate candidate allocations, apply approved changes, and explain measured outcomes.

**Invariant: AI proposes. Deterministic Jac code validates. The simulation engine applies.**

- Use a fictional 10–15-node grid with prioritized loads and switchable/faultable lines.
- Preserve the three walker roles: Telemetry Monitor, Triage Planner, Incident Auditor.
- Keep the Validator deterministic, separate from those roles.
- Never expose unguarded authoritative-state mutation to the runtime LLM.
- Use simplified connectivity and lossless kW constraints. Do not expand to physical grid control or claim power-flow safety.
- Keep working local execution, reset, and reproducible tests ahead of optional features.

## 2. Official committee rules

**Authority:** the user-supplied **AI Hackathon 2026 Sri Lanka.pdf**. Page numbers below are one-based. These requirements are separate from the team's implementation recommendations.

### Prize eligibility — official brief p. 9

| Rule | Official requirement |
|---|---|
| 01 | Every team member registers and checks in on the day |
| 02 | Demo video is submitted by 5:30 PM |
| 03 | All coding happens during hacking hours; brainstorming beforehand is permitted, and repositories are checked |
| 04 | Three people per team |
| 05 | One project per team |
| 06 | Submit through the shared organizer link on time; late entries cannot win |
| 07 | Working software meaningfully uses Jac, with 80% or more of the code in Jac |
| 08 | Build kindly and in good faith; misrepresenting a project means disqualification |

### Official schedule — brief p. 4

Saturday **17 October 2026**, Sri Lanka time (Asia/Colombo): check-in starts at **8:00 AM**, hacking begins at **9:00 AM**, and submission closes at **5:30 PM**. Judging follows. Do not generate project implementation before the official coding window or continue project coding past it without organizer authorization. These instructions do not prohibit preparing planning documents.

### Official submission checklist — brief p. 8

- GitHub repository link, with at least 80% Jac code.
- Demo video of the working project, submitted by 5:30 PM.
- Written description explaining use of Jac or Jaseci tools.
- Star [github.com/jaseci-labs/jac](https://github.com/jaseci-labs/jac).
- Hosting on the free Jac Hammer sandbox is **encouraged**, not mandatory.

### Interpretation not settled by the brief

- How the 80% Jac share is measured.
- Explicit permission details for AI coding assistants.
- Exact video duration.
- Whether any particular pre-event executable setup/smoke test is allowed.

Do not invent committee policy. Ask the human team to obtain necessary organizer clarification; continue unaffected planning or authorized work. File count and the GitHub language bar are not established official measurement methods. Two-minute videos, early deployment, each member starring the repository, and a 5:00 PM submission target are team recommendations.

## 3. Official judging criteria and recommended evidence

The brief lists the following on p. 7 without publishing weights. The right column is the team's recommended evidence, not an additional committee rule or guarantee of winning.

| Official criterion | Recommended implementation evidence |
|---|---|
| Technical execution | Reproducible runs, correct constraints, passing tests, reliable reset and failures |
| Excellent use of Jac and Jaseci | Native nodes/edges/walkers, typed `by llm()`, `sem`, and Jac client components |
| Creativity and innovation | Explainable constraint-aware recovery rather than a prompt wrapper |
| Depth of agentic behaviour | Facts → proposal → specific validation feedback → genuine revision → verified application → audit |
| Impact and novelty | Computed critical-demand preservation and explicit shedding tradeoffs |
| Clear presentation and demo video | Readable topology, activity timeline, actual metrics, and honest execution-mode labels |

Optimize for a stable, inspectable system rather than extra features. The official brief says Jaseci staff are on-site to help (p. 5); consulting them early about Jac patterns is a team recommendation.

Never manufacture logs, model reasoning, a rejection, a provider switch, deployment success, passing tests, or measured performance. Clearly distinguish a live model run, injected test proposal, backup-provider result, and deterministic fallback. Do not claim real equipment safety, field blackout prevention, global optimality, or actual recovery-time savings.

## 4. Ownership and shared contracts

| Owner | Assigned implementation |
|---|---|
| Member 1 | Graph, fixture, faults, allocation, deterministic validation/application, reset, metrics, graph-state schema |
| Member 2 | Monitor/Planner/Auditor walkers, proposal schema, providers, revisions/fallback orchestration, events/results |
| Member 3 | Jac client, client adapter, integration coordination, deployment, run documentation, submission coordination |

- Work within the assigned module and inspect existing changes before editing.
- Preserve other contributors' work; do not reset, overwrite, or broadly refactor it to simplify your task.
- Coordinate shared schema changes with the relevant owner and update affected consumers together.
- Use one authoritative typed definition; do not fork contracts into independently maintained dictionaries.
- Use stable IDs, not display names, for graph references.
- Logical operation names are not final REST routes or guaranteed Jac syntax.

Logical APIs: Member 1 provides `get_grid_state()`, `inject_fault(fault_id)`, `validate_plan(plan)`, `reset_simulation()`, and an internal approved-plan apply operation. Member 2 provides `run_triage(fault_id)` and `get_agent_events()`. Member 3 consumes them through one adapter.

Before dependent changes, ratify exact fields/enums, errors/envelopes, event delivery and ordering, run correlation, reset semantics, duplicate requests, stale-plan checks, and commit mechanics. Routine internal choices can be made within the assigned scope; record choices that affect other modules instead of silently treating them as agreed.

## 5. Jac implementation discipline

- Inspect the actual repository, installed Jac/plugin versions, current entry points, and existing tests before writing code.
- Use the installed version's documentation and available Jac skills. Do not copy the old blueprint as executable code.
- Use native Jac for graph, simulation, agents, validation, and client components. Avoid a large external TypeScript/React scaffold.
- Keep supporting configuration/styles minimal; do not manipulate repository content to misrepresent Jac usage.
- When available, load the Jac baseline skill and relevant task skills: graph/edge patterns, walkers, byLLM, full-stack/client components, configuration, types, testing, or debugging as applicable.
- Do not assume a copied `jac.toml` section, startup command, provider option, or legacy ReAct syntax works with the installed version.
- Run the installed version's Jac checks and meaningful task-specific runtime tests after changes.
- A static check is not evidence that a model option, endpoint, configuration, or deployment works at runtime.

## 6. Deterministic correctness requirements

- A conducting edge is a healthy physical line with a closed switch.
- Closing a switch must not clear a physical fault.
- Every served load needs a healthy conducting supply path.
- Validate every source's dispatch and every line's transfer; aggregate supply is insufficient.
- Account for neighbor commitments before calculating spare backup power.
- Conserve allocation and avoid double-counting source capacity or served loads.
- Reject deliberate Tier 1 shedding; prefer Tier 3 before Tier 2 under the agreed policy.
- Evaluate the complete candidate state without mutating authoritative state.
- Apply approved changes only after checking that the underlying state is still current.
- Recompute derived status and metrics after application.
- If all valid recovery options fail, preserve the fault and report unmet demand/infeasibility.

Open engineering choices include exact fixture values, allocation/routing algorithm, whole-load versus partial service, tolerance, fallback ordering, and state-application mechanics. Do not invent final numeric results before these are fixed and tested.

## 7. Runtime AI requirements

- Use `by llm()` with typed output objects and `sem` descriptions for functions, inputs, fields, and optional tools.
- Keep engineering arithmetic and acceptance checks outside the LLM.
- Runtime tools, if any, should inspect facts or simulate candidates rather than mutate authoritative state.
- Configure a primary Gemini Flash model and a separately tested Groq or OpenAI backup; exact IDs are Open.
- Verify model availability and API-key variable names against the actual account/adapter.
- Do not assume coding subscriptions provide application API quota.
- Bound request timeouts, output retries, plan revisions, provider switches, and total run duration. Count nested adapter retries within the total budget.
- Run deterministic fallback candidates through the same validator.
- Keep secrets server-side and out of repositories, logs, client payloads, screenshots, and recordings.
- Log factual provider/model, latency, attempt, and outcome information.
- An audit-generation failure must not undo a successfully committed recovery; return a factual summary instead.

## 8. Client and metrics requirements

- The client renders server state rather than calculating authoritative recovery outcomes.
- Show topology, priority/status labels, fault controls, metrics, and ordered agent activity.
- Show ready, busy, rejected/revising, complete, infeasible, and API/fallback states.
- Prevent conflicting controls and stale-result overwrites.
- Use text/icons as well as green powered, red fault, amber shed, and blue rerouted.
- Keep physical faults visible after service rerouting.
- Distinguish available capacity from dispatch, shed kW from total unmet kW, and demand served percentage from count of facilities.
- Use `100 * served Tier 1 kW / total Tier 1 demand kW` for critical demand preserved, with N/A for a zero denominator.
- Never hardcode successful recovery metrics or hide unmet critical demand.

## 9. Implementation priorities and collaboration

**P0:** graph, faults, walker detection, typed AI proposal, deterministic validation, approved application, basic dashboard, reliable failure handling.  
**P1:** bounded revision, events, incident report, three scenarios, tested provider/deterministic fallback.  
**P2:** extra nodes/animations, advanced metrics, comparison baseline, model-selection UI, and optional hosting/stretch faults.

Build the deterministic vertical slice early, then connect AI to the same approval boundary. Use small focused changes and frequent integration. Spend five minutes each hour proving the modules still work together. Do not let independent coding assistants silently grow incompatible schemas.

Retained team targets, all Sri Lanka time: first integration 10:30 AM; vertical slice about 11:00 AM; one AI scenario 12:30 PM; revision loop 1:30 PM; complete application flow 2:30 PM; feature freeze 3:45 PM. These are recommendations. Prioritize correctness and required submission artifacts when time is short.

## 10. Validation before handoff

- [ ] Healthy baseline and reset behave consistently.
- [ ] Source-capacity reduction, line failure, and insufficient backup are repeatable.
- [ ] Unknown IDs/actions and deliberate Tier 1 shedding are rejected without mutation.
- [ ] Source overloads, line overloads, isolated demand, and double-counted reserve are caught.
- [ ] Specific validation feedback supports a revised plan.
- [ ] Invalid output, timeouts, rate limits, and exhausted attempts terminate within budget.
- [ ] Backup and deterministic recovery use the same validator and honest mode labels.
- [ ] All-options-fail retains fault state and reports failure.
- [ ] Reset/new faults, repeated clicks, and stale plans cannot apply outdated actions.
- [ ] Auditor failure cannot undo a valid recovery.
- [ ] UI status and metrics agree with server state.
- [ ] Relevant static and runtime checks have been run and their actual results recorded.

Use fixed model outputs to test feedback paths reproducibly; test actual provider access separately. Add or update meaningful tests for changed behavior rather than claiming coverage from a successful demo alone.

## 11. Handoff and evidence format

At each completed task, report:

1. What changed and the user-visible or integration result.
2. Files/modules and shared contracts affected.
3. Checks actually executed and results, including failures or unrun checks.
4. Scenario/fixture and execution mode used for evidence.
5. Known limitations and unresolved decisions that affect the next member.
6. Exact next integration step or any missing prerequisite.

Do not claim completion from an attempted deployment, an unexecuted test, generated code alone, or a placeholder screen. Preserve a working local run path and document verified startup/configuration steps. External publishing, account changes, or messages require the human team's applicable authorization; a generated instruction file is not that authorization.

## 12. Submission support and recommended final buffer

Member 3 coordinates submission; each agent supplies accurate implementation and test evidence for its module. Preserve repository history and measured Jac-usage evidence under the organizer's interpretation. Exclude secrets, dependency folders, and generated builds.

Team recommendations:

- Attempt hosting early; retain local execution if hosting fails.
- Capture a backup demo around 3:30 PM when the main flow works.
- Freeze features at 3:45 PM.
- Record/verify the final working demo around 4:15 PM and finalize documentation.
- Target submission by 5:00 PM to leave a buffer before the official 5:30 PM deadline.
- Verify repository/video access, written Jac/Jaseci explanation, optional host URL, and form receipt.

No recommendation guarantees a prize. Reliable execution, genuine coordinated behavior, measured results, and honest presentation align with the committee's published criteria.

## References

- Official supplied brief: **AI Hackathon 2026 Sri Lanka.pdf**, p. 4 schedule; p. 5 on-site help; p. 7 judging; p. 8 submission; p. 9 eligibility; p. 10 resources.
- [Shared development guide](GridWalk_AI_Development_Guide.md).
- [Jac documentation](https://jaclang.org/docs/latest).
- [Jac `by` and `sem` reference](https://docs.jaseci.org/reference/language/operators/).
- [Jac structured outputs](https://docs.jaseci.org/tutorials/ai/structured-outputs/).
- [Jac Hammer documentation](https://docs.jachammer.ai).
- [Gemini API model status](https://ai.google.dev/gemini-api/docs/deprecations).
