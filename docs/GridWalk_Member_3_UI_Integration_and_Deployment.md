# GridWalk AI — Member 3 Tasks and Instructions

## Role and result

**Role:** Frontend, Integration, and Deployment Engineer.  
**Primary coding tool:** Antigravity.  
**Deliverable:** A functional Jac dashboard with current topology, controls, measured results, and agent activity; a reproducible local run path; optional verified deployment; complete submission artifacts.

Read [the development guide](GridWalk_AI_Development_Guide.md) and [the shared AI-agent guidelines](GridWalk_AI_Agent_Guidelines.md) before implementation.

**Core invariant:** The server graph is authoritative. The client requests operations and displays results; it never bypasses deterministic validation.

## Ownership and boundaries

You own the Jac client, topology view, client/server adapter, interaction states, integration coordination, deployment, run instructions, recording, and submission coordination. Member 1 owns graph-state schemas and simulation. Member 2 owns proposal schemas, agent events, and recovery orchestration.

- Start the client at kickoff using agreed sample state rather than waiting for a finished backend.
- Use Jac client components and SVG/simple connections rather than a large external TypeScript/React application.
- Centralize transport/response-envelope handling in one adapter.
- Coordinate field changes with the schema owner instead of inventing UI-specific aliases.
- Keep application API credentials on the server.

## Task checklist

### Phase 1 — Dashboard foundation

1. [ ] Initialize the Jac full-stack application structure using the installed version.
2. [ ] Build the dashboard shell in Jac client components.
3. [ ] Create a readable topology using SVG or simple connected nodes.
4. [ ] Implement source, load, fault, and switch indicators with text labels.
5. [ ] Create scenario selection, fault injection, run recovery, and reset controls.

### Phase 2 — Agent visualization and integration

6. [ ] Connect graph-state reads from Member 1.
7. [ ] Connect fault/reset operations and Member 2's recovery orchestration.
8. [ ] Build an ordered timeline showing observations, proposals, validation, revisions, and outcomes.
9. [ ] Display critical demand preserved, shed/unmet kW, available capacity, and active faults.
10. [ ] Implement ready, busy, error, rejected/revising, complete, infeasible, and fallback states.

### Phase 3 — Deployment and submission

11. [ ] Run end-to-end checks with both other members.
12. [ ] Attempt early Jac Hammer deployment while preserving a local working path.
13. [ ] Check Jac usage against the organizer's interpretation of the 80% rule.
14. [ ] Coordinate and verify a working-project demo video; retain an early backup recording.
15. [ ] Prepare local run instructions, README, Jac/Jaseci description, repository/video links, and the submission form.

## Dashboard specification

```text
Header: GridWalk AI | Simulation/run state | AI / backup / deterministic mode

Critical demand served | Shed kW | Available capacity | Active faults

Live topology                          Scenario and recovery controls
Sources, loads, lines, switches         Agent activity timeline

Outcome / incident summary / before-and-after metrics / unmet demand
```

- Keep topology and agent activity prominent.
- Display names, stable IDs where useful, priorities, kW units, and line/switch/fault state.
- Retain green powered, red fault, amber shed, and blue rerouted as the visual direction, with words/icons in addition to color.
- Distinguish a physically faulted component from recovered load service.
- Distinguish capacity from dispatch, deliberate shedding from total unmet demand, and critical demand percentage from facility count.
- Do not hardcode success metrics or copy the illustrative 100%/100 kW values from planning mockups.
- Label deterministic or backup execution; never present it as primary AI output.

### Interaction and state consistency

- Disable conflicting controls while a run is active.
- Show progress and failure reasons rather than leaving the UI apparently frozen.
- Refresh from server-derived state after mutations.
- Use the agreed run/order mechanism so older responses cannot overwrite newer state.
- Resolve reset during planning, duplicate recovery clicks, and second-fault behavior with Members 1 and 2.
- Never call an unvalidated authoritative-state mutation operation directly from the client.
- If recovery is infeasible, keep the fault and unmet demand visible instead of displaying a success animation.

## Interfaces and handoffs

| Provider | Operations/data you consume |
|---|---|
| Member 1 | `get_grid_state()`, `inject_fault(fault_id)`, `reset_simulation()`, computed metrics |
| Member 2 | `run_triage(fault_id)`, `get_agent_events()`, recovery result, execution mode, incident account |

These names are logical, not final REST routes or verified Jac signatures. Agree exact envelopes and error handling early. Event polling versus streaming, run correlation, canonical enums, and lifecycle details are **Open**.

Give both members a small shared sample state and the fields the client needs. Report schema mismatches with exact field/ID examples; do not silently create competing contracts.

## Development and integration checkpoints

All times are Sri Lanka time on 17 October 2026. Only the official start/deadline are committee requirements; other milestones are team recommendations.

| Time | Your target |
|---|---|
| 9:00–9:30 AM | Scaffold, agree version/contracts, and establish the client adapter |
| 10:30 AM | First graph/fault/recovery/client integration |
| By 11:00 AM | Dashboard skeleton; attempt a small hosted deployment if viable |
| 12:30 PM | Display one AI recovery scenario passing through validation |
| 2:30 PM | Full fault-to-updated-dashboard flow, with events and metrics |
| Around 3:30 PM | Early backup recording once the main flow works |
| 3:45 PM | Feature freeze; no frontend redesign |
| 4:15–4:45 PM | Record and verify polished demo; finish written artifacts |
| By 5:00 PM | Team submission target, leaving a 30-minute buffer |
| 5:30 PM | Official submission deadline |

Spend five minutes each hour proving the three modules still integrate. Use small commits and review shared schema changes with their owner.

## Deployment and local execution

- Verify installed-version startup/build steps locally before deployment.
- Keep local reset and the three core scenarios working throughout.
- Configure secrets through the host's supported server-side mechanism; do not embed them in the client or repository.
- Verify the final deployed build, provider access, reset, and scenario behavior from its actual URL.
- If hosting fails, prioritize the local working application and required submission artifacts; hosting is not mandatory.
- Document actual dependencies, startup commands, environment-variable names, and any limitations after verification. Do not copy untested blueprint commands.

## Completion checks

- [ ] Topology and metrics update from server results after fault, recovery, and reset.
- [ ] Busy, rejection, API failure, fallback, and infeasible states are usable.
- [ ] Old events/results cannot overwrite the current run.
- [ ] All three scenarios work end to end or show their correct infeasible outcome.
- [ ] No client response/log/build contains API secrets.
- [ ] Local run instructions are tested; hosting status is described accurately.
- [ ] Jac checks and relevant runtime checks pass.
- [ ] Final repository, video, written description, and optional host link are accessible to judges.

## Official qualification and submission rules

Source: **AI Hackathon 2026 Sri Lanka.pdf**, pp. 4, 8–9.

| Official requirement | Coordination action |
|---|---|
| Every member registers and checks in | Confirm all three have done so |
| Three people per team; one project per team | Submit one GridWalk entry for the team |
| All coding during hacking hours; repositories checked | Preserve genuine project history beginning during the official coding period |
| Hacking starts at 9:00 AM | Keep advance preparation to planning under the rules |
| Working software meaningfully uses Jac, at least 80% | Verify interpretation with organizers; avoid unsupported percentage claims |
| Demo video due by 5:30 PM | Upload and test the actual video link before the deadline |
| Submit through shared link on time; late entries cannot win | Confirm form receipt, not just an upload attempt |
| Good faith; misrepresentation means disqualification | Accurately label simulation, tests, fallback, deployment, and measured results |

Official submission checklist: GitHub link, working demo video, written explanation of Jac/Jaseci usage, and star [the official Jac repository](https://github.com/jaseci-labs/jac). The brief encourages free Jac Hammer hosting; it does not require it.

**Not specified in the brief:** the 80% measurement method, an exact video duration, and explicit AI coding-tool policy. Ask organizers about necessary interpretation. Two minutes and submission by 5:00 PM are team recommendations.

## Presentation aligned with official judging

The official criteria are technical execution, excellent use of Jac/Jaseci, creativity/innovation, depth of agentic behaviour, impact/novelty, and clear presentation/demo video (brief p. 7). No scoring weights are published.

Recommended two-minute story:

1. **0:00–0:20:** Explain the simulated critical-load recovery problem.
2. **0:20–0:40:** Show Jac nodes/edges, walkers, and the deterministic approval boundary.
3. **0:40–1:25:** Run a real scenario; show proposal, validation, and applied result. Show revision only if observed, or clearly label an invalid-plan test.
4. **1:25–1:45:** Show measured critical service, shedding/unmet demand, and constraint compliance.
5. **1:45–2:00:** Summarize the incident and simplified-model limitations.

Play the final uploaded video completely and verify readability, audio, access, and ending. Do not claim over 90% Jac, successful hosting, field reliability, or actual recovery-time savings without evidence. The written description should identify implemented Jac features, genuine agent coordination, tests, fallback, and limitations.

### Final submission checklist

- [ ] All three members registered/checked in; one project entry.
- [ ] GitHub link works and the code meets the at-least-80% Jac requirement under organizer interpretation.
- [ ] Working demo video uploaded, playable, and judge-accessible.
- [ ] Written description explains actual Jac/Jaseci use.
- [ ] Official Jac repository starred; team recommendation is that each member does so.
- [ ] Optional Jac Hammer URL included only if verified.
- [ ] No secrets, unsupported claims, stale links, or mislabeled fallback output.
- [ ] Submission through the shared organizer link is confirmed before 5:30 PM.
