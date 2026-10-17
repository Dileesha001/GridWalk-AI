# Member 1 — Graph and Simulation Task List

Scope: implement the graph and deterministic simulation core described in [the Member 1 guide](GridWalk_Member_1_Graph_and_Simulation.md). Write all application logic and tests in Jac. Keep configuration and documentation minimal. Do not implement the Planner, model providers, or dashboard in these branches.

The existing `dev` branch provides the Jac 0.16.7 fullstack scaffold and owns the integration baseline. The branches below are separate work branches based on `dev`. Merge them into `dev` in task order; before starting a dependent task, update its branch from the latest integrated `dev`. Do not stage or commit on the user's behalf.

| Existing path | Ownership and task use |
|---|---|
| `grid/graph.jac` | Member 1: typed source/load nodes and power-line edges; Task 1 |
| `grid/fixture.jac` | Member 1: healthy fixture and named fault definitions; Tasks 1–2 |
| `grid/simulation.jac` | Member 1: fault/reset, allocation, and approved application; Tasks 2–3, 5 |
| `grid/validation.jac` | Member 1: non-mutating candidate validation; Task 4 |
| `grid/metrics.jac` | Member 1: server-computed metrics; Tasks 1, 5 |
| `shared/contracts.jac` | Shared: one typed contract home; Member 1 owns `GraphState`, Member 2 owns recovery-plan types |
| `agents/`, `client/`, `main.jac` | Other members' implementation; coordinate interfaces instead of editing their code |
| `docs/` | Team guides, fixture/contract notes, and this task list |

The scaffold files are placeholders, not implemented behavior. Add Jac tests alongside the relevant module or under a `tests/` directory, using the installed Jac test conventions.

| Task | Branch | Depends on | Status |
|---|---|---|---|
| 1. Graph contract and healthy fixture | `member1/01-graph-contract-fixture` | — | Implemented; contract review pending |
| 2. Faults, state projection, and reset | `member1/02-faults-state-reset` | 1 | Implemented; contract review pending |
| 3. Deterministic allocation and routing | `member1/03-allocation-routing` | 2 | To do |
| 4. Candidate validation and feedback | `member1/04-plan-validation` | 3; Member 2 plan contract | To do |
| 5. Approved application and metrics | `member1/05-apply-metrics` | 4 | To do |
| 6. Scenario verification and integration | `member1/06-scenarios-integration` | 5; Member 2 and 3 interfaces | To do |

## 1. Graph contract and healthy fixture

- Use the existing fullstack `jac.toml` and directory structure; record the Jac/plugin versions actually used. Keep `main.jac` and `client/` with Member 3.
- Implement typed source/load nodes and power-line edges with stable IDs in `grid/graph.jac`. Put the canonical `GraphState` projection types in `shared/contracts.jac`; agree graph fields with Members 2 and 3 before they build consumers.
- Implement the fictional 10–15-node healthy fixture in `grid/fixture.jac`, with Tier 1–3 loads, source capacities, line ratings, backup commitments, and a genuine alternate path. Document exact values and wiring under `docs/`.
- Use native Jac nodes and edges. Prove healthy baseline feasibility with a small Jac check/run; keep full allocation logic for Task 3.
- **Done when:** fixture IDs and values are documented; graph construction and healthy baseline capacity/connectivity are reproducible. No placeholder code is presented as a working simulator.

Implementation evidence: `grid/graph.jac`, `grid/fixture.jac`, and `shared/contracts.jac` now hold the Jac graph and projection types; [the fixture notes](MEMBER_1_FIXTURE.md) record exact IDs and healthy flow. `jac check .` passed (13 files) and `jac test tests/fixture_checks.jac -v` passed (1 test). The graph-state fields are proposed for review by Members 2 and 3 before they build consumers.

## 2. Faults, state projection, and reset

- Define named, repeatable source-capacity reduction, line failure, and insufficient-backup scenarios in `grid/fixture.jac`; implement fault/reset mutations in `grid/simulation.jac`.
- Keep physical fault state independent of switch state: a line conducts only when healthy and closed.
- Expose the canonical `get_grid_state()`, `inject_fault(fault_id)`, and `reset_simulation()` behavior from `grid/simulation.jac` through signatures agreed with the other members. Return the `GraphState` projection from `shared/contracts.jac`.
- Recompute derived status after every fault/reset and preserve stable IDs.
- **Done when:** all three faults change the expected entities; unknown fault IDs are rejected; reset exactly restores the healthy fixture and its metrics.

Implementation evidence: `grid/fixture.jac` defines the three fault inputs, `grid/simulation.jac` implements the Jac state/fault/reset functions, and `grid/metrics.jac` computes current readings. [Fixture notes](MEMBER_1_FIXTURE.md) list exact pre-recovery outcomes. `jac check .` passed (14 files) and `jac test tests/fault_checks.jac -v` passed (5 tests). Member 2/3 contract review and client integration remain separate work.

## 3. Deterministic allocation and routing

- Implement lossless kW allocation over conducting paths in `grid/simulation.jac`, including source dispatch and per-line transfer from `grid/graph.jac` entities.
- Include a backup source's existing commitments before calculating spare capacity; prevent double-counting supply or served loads.
- Choose and document whole-load versus partial service, routing/tie behavior, numeric tolerance, and Tier 3 before Tier 2 shedding order.
- Keep candidate calculations separate from authoritative graph mutation.
- **Done when:** allocations obey per-source and per-line capacities and flow conservation; isolated demand stays unserved; all derived values come from one allocation.

## 4. Candidate validation and feedback

- Import Member 2's canonical typed recovery-plan/action contract from `shared/contracts.jac` rather than creating a competing schema in `grid/validation.jac`.
- Implement non-mutating validation in `grid/validation.jac` for the entire candidate state: action types and IDs, target kinds, numbers, switch/fault logic, conducting paths, source and line ratings, conservation, and priority policy.
- Reject deliberate Tier 1 shedding and return specific, factual reasons that support a Planner revision.
- **Done when:** invalid candidates leave authoritative state unchanged; Jac tests cover unknown IDs/actions, faulted and open paths, isolated loads, overloads, and duplicate capacity claims.

## 5. Approved application and metrics

- Apply only a validated candidate in `grid/simulation.jac` whose state/version still matches the current graph. Define duplicate-request and stale-plan behavior with Member 2.
- Commit switch and service changes atomically from the validated candidate, then recompute allocation, status, and metrics. A successful reroute must retain the physical fault.
- Compute before/after metrics in `grid/metrics.jac`: critical demand preserved, deliberate shed kW, total unmet kW, available capacity, dispatch, and active faults/violations.
- **Done when:** rejected or stale candidates do not mutate state; repeated application cannot duplicate changes; metrics match the committed graph.

## 6. Scenario verification and integration

- Write Jac tests for the healthy baseline, each core fault, feasible and infeasible recovery, reset, and stale/duplicate requests.
- Record exact fixture values and expected outcomes for the three scenarios; label injected test proposals separately from live AI output.
- Integrate the `grid/validation.jac` and `grid/simulation.jac` handoff with Member 2 and the state/fault/reset API with Member 3 without taking ownership of `agents/`, `client/`, or `main.jac`.
- Run the installed Jac checker and task-specific runtime tests. Record actual commands, results, remaining limits, and the next integration step.
- **Done when:** the three scenarios are repeatable, failure leaves the fault visible, and the other members can consume the agreed state and validation contracts.

## Shared decisions to settle early

The guides leave the fixture values, field/enumeration names, exact operation envelopes, plan schema, routing policy, service granularity, stale-plan mechanism, and reset/run correlation open. Task 1 should publish the graph-side decisions promptly; Task 4 must use Member 2's plan contract. No illustrative IDs or numeric results in the guides should be treated as final fixture facts.
