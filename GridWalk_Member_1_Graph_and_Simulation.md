# GridWalk AI — Member 1 Tasks and Instructions

## Role and result

**Role:** Graph and Simulation Engineer.  
**Primary coding tool:** Codex. **Backup:** Antigravity.  
**Deliverable:** A fictional Jac microgrid with repeatable faults, deterministic allocation and validation, approved state updates, reset, and reliable metrics.

Read [the development guide](GridWalk_AI_Development_Guide.md) and [the shared AI-agent guidelines](GridWalk_AI_Agent_Guidelines.md) before implementing your module.

**Core invariant:** AI proposes; deterministic Jac code validates; your simulation core applies approved changes.

## Ownership and boundaries

You own graph entities, the fixture, simulation, allocation, validation, state application, reset, metrics, and the shared graph-state contract. Member 2 owns recovery-plan schemas and orchestration. Member 3 owns the client, integration coordination, and deployment.

- Use native Jac nodes, edges, and traversal where appropriate.
- Keep arithmetic and authoritative graph mutations in deterministic Jac code.
- Provide one canonical state projection consumed by both other members.
- Coordinate shared contract changes with Member 2 and Member 3 before consumers adopt them.
- Do not duplicate the Planner, provider adapter, or client in your module.

## Task checklist

### Phase 1 — Graph foundation

1. [ ] Define nodes for substations/sources, backup sources, and load sectors.
2. [ ] Define power-line edges with capacity, physical fault state, and independently represented switch state.
3. [ ] Build a fictional 10–15-node fixture with documented demand/capacity values and stable IDs.
4. [ ] Implement initialization and traversal; prove the healthy baseline is feasible.
5. [ ] Expose the agreed graph-state projection to Members 2 and 3.

### Phase 2 — Simulation and validation

6. [ ] Implement source-capacity reduction.
7. [ ] Implement line failure and disconnection.
8. [ ] Implement backup availability and priority-aware load shedding.
9. [ ] Compute available supply, demand, conducting paths, affected loads, and allocations.
10. [ ] Implement deterministic validation for references, switch/fault logic, connectivity, capacity, and priorities.

### Phase 3 — Integration and tests

11. [ ] Apply only approved plans, with no authoritative mutation from rejected candidates.
12. [ ] Return consistent before/after graph metrics.
13. [ ] Create the three repeatable core scenarios: source-capacity reduction, line failure, and insufficient backup.
14. [ ] Test infeasible plans, disconnected sections, invalid references, and over-capacity allocations.
15. [ ] Integrate candidate validation, feedback, application, and reset with Member 2's orchestration.

## Engineering instructions

### Graph semantics

- Tier 1 is critical demand; Tier 2 essential; Tier 3 noncritical.
- Reject deliberate Tier 1 shedding. Prefer Tier 3 shedding before Tier 2.
- A line conducts only when physically healthy **and** its switch is closed.
- Closing a switch does not repair a faulted line.
- A source tie cannot bypass every downstream broken line. Restoration requires an actual healthy alternative path.
- Spare backup supply excludes the backup source's existing commitments.
- Keep computed service/allocation fields consistent; do not independently maintain contradictory powered/status values.
- Reserve measured in kW is available power, not battery duration or energy in kWh.

### Candidate validation

Validate the complete candidate allocation, not just the action list or total supply:

```text
0 <= source_dispatch(s) <= available_capacity(s)
abs(line_transfer(e)) <= line_capacity(e)
0 <= served_kw(load) <= demand_kw(load)

At every junction:
    inflow + source_dispatch = outflow + served_demand

Total source dispatch = total served demand in the lossless model.
```

Every served load needs a conducting path to available supply. Reject unknown action types/IDs, wrong target kinds, invalid numbers, faulted paths, source overloads, line overloads, and deliberate Tier 1 shedding. Return specific reasons useful to the Planner.

Keep candidate evaluation separate from application. Recheck current state before applying a plan so a reset or new fault cannot make an old approval valid against the wrong graph. Recompute service, allocation, and metrics after apply. If recovery is infeasible, retain the fault and report unmet demand honestly.

### Metrics you own

| Metric | Meaning |
|---|---|
| Critical demand preserved | `100 * served Tier 1 kW / total Tier 1 demand kW`; N/A for zero demand |
| Shed kW | Demand deliberately disconnected by recovery |
| Unmet kW | All unserved demand, including shed and fault-disconnected demand |
| Available capacity | Source capability, distinct from actual dispatch |
| Compliance and faults | Per-source/per-line violations, connectivity failures, and active physical faults |

## Interfaces and handoffs

Names below are logical interfaces; agree exact installed-version signatures and envelopes.

| Interface | Handoff |
|---|---|
| `get_grid_state()` | Sources, loads, lines/switches, faults, and computed metrics to Members 2 and 3 |
| `inject_fault(fault_id)` | Named repeatable fault application and refreshed state to Member 3 |
| `validate_plan(plan)` | Non-mutating accept/reject result with factual evidence to Member 2 |
| Internal approved-plan apply operation | State update callable by Member 2 after validation; exact name is Open |
| `reset_simulation()` | Known fixture and consistent run-state reset to Member 3 |

Deliver fixture documentation with baseline values, exact scenario changes, and expected numeric results. Provide sample valid and invalid proposals using real fixture IDs for Member 2's tests. Member 3 should receive sample state early, before the complete backend exists.

## Open choices to settle

- Canonical entity/field names and status enums.
- Exact nodes, wiring, ratings, demands, and normally open switches.
- Whole-load shedding versus partial service.
- Allocation/routing method, numeric tolerance, and deterministic fallback ordering.
- Commit semantics, duplicate application prevention, and stale-plan handling.

Record chosen details in the shared contracts/fixture documentation. Do not present illustrative blueprint values as agreed final fixtures.

## Development checkpoints

All times are Sri Lanka time on 17 October 2026; intermediate targets are team recommendations.

| Target | Your contribution |
|---|---|
| 9:00–9:30 AM | Agree graph contract, version, fixture policy, and module boundaries |
| 10:30 AM | Core graph, fault/reset functions, and first shared integration |
| About 11:00 AM | Deterministic fault-to-recovery vertical slice |
| 12:30 PM | One AI proposal checked and applied end to end |
| 1:00 PM | Validation and simulation integration complete |
| 2:30 PM | All core graph behavior connected to the dashboard |
| 3:45 PM | Feature freeze; fix correctness and repeatability defects |

## Completion checks

- [ ] Healthy reset state is feasible and reproducible.
- [ ] Each of the three scenarios has documented expected results.
- [ ] Invalid candidates leave authoritative state unchanged.
- [ ] Capacity checks catch both individual-line and individual-source overloads.
- [ ] Isolated critical loads are not falsely marked restored.
- [ ] Backup supply and load demand are not double-counted.
- [ ] Repeated requests and stale plans cannot duplicate or overwrite state changes.
- [ ] Jac checks and relevant runtime tests pass; handoff includes commands, results, and known limitations.

## Official competition requirements

Source: **AI Hackathon 2026 Sri Lanka.pdf**, schedule p. 4, submission p. 8, eligibility p. 9.

- Every member must register and check in on the day.
- Teams have three people and submit one project.
- All project coding takes place during hacking hours; brainstorming beforehand is allowed and repositories are checked.
- Hacking begins at 9:00 AM; submission and the working demo video are due by **5:30 PM on 17 October 2026**.
- Working software must meaningfully use Jac, with at least **80% of the code in Jac**.
- Submit through the shared organizer link on time; late entries cannot win.
- Provide a GitHub link, working demo video, and written description of Jac/Jaseci usage; star [the official Jac repository](https://github.com/jaseci-labs/jac).
- Build in good faith; misrepresenting the project causes disqualification.
- Jac Hammer sandbox hosting is **encouraged, not required**.

The brief does not define how 80% is measured or explicitly settle AI coding-tool permissions. Confirm those interpretations with organizers; do not treat a file count or GitHub language bar as the official method.

## Your contribution to judging

The official criteria are on p. 7 of the brief; no weights are supplied. The evidence below is a team recommendation, not an extra qualification rule.

| Official criterion | Evidence you should enable |
|---|---|
| Technical execution | Repeatable scenarios, correct arithmetic, rejection tests, consistent reset |
| Excellent use of Jac/Jaseci | Native graph entities and traversal; meaningful Jac simulation logic |
| Creativity and innovation | Constraint-aware recovery instead of an unverified prompt response |
| Depth of agentic behaviour | Specific validator feedback that enables genuine Planner revision |
| Impact and novelty | Measured preservation of critical demand and transparent shedding tradeoffs |
| Clear presentation/demo video | Exact before/after values and a small explainable graph |

Do not claim real power-flow safety, field blackout prevention, optimality, or actual recovery-time improvements from this simplified simulator. Ask the on-site Jaseci team to review graph/walker usage early if needed. Help Member 3 verify the demo's numeric claims before the team's recommended 5:00 PM submission target.
