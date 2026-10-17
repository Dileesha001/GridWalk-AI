# Member 1 — Graph and Simulation Task List

Scope: implement the graph and deterministic simulation core described in [the Member 1 guide](GridWalk_Member_1_Graph_and_Simulation.md). Write all application logic and tests in Jac. Keep configuration and documentation minimal. Do not implement the Planner, model providers, or dashboard in these branches.

The existing `dev` branch provides the Jac 0.16.7 fullstack scaffold and owns the integration baseline. The branches below are separate work branches based on `dev`. Merge them into `dev` in task order; before starting a dependent task, update its branch from the latest integrated `dev`. Do not stage or commit on the user's behalf.

| Existing path | Ownership and task use |
|---|---|
| `grid/graph.jac` | Member 1: typed source/load nodes and power-line edges; Task 1 |
| `grid/fixture.jac` | Member 1: healthy fixture and named fault definitions; Tasks 1–2 |
| `grid/simulation.jac` | Member 1: fault/reset and approved application; Tasks 2, 5 |
| `grid/allocation.jac` | Member 1: pure allocation/routing preview; Task 3 |
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
| 3. Deterministic allocation and routing | `member1/03-allocation-routing` | 2 | Implemented; review pending |
| 4. Candidate validation and feedback | `member1/04-plan-validation` | 3; Member 2 plan contract | Implemented; ready for review |
| 5. Approved application and metrics | `member1/05-apply-metrics` | 4 | Implemented; ready for review |
| 6. Scenario verification and integration | `member1/06-scenarios-integration` | 5; Member 2 and 3 interfaces | Member 1 fallback and scenario checks implemented; joint integration pending |

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

- Implement lossless kW allocation over conducting paths in `grid/allocation.jac`, including source dispatch and per-line transfer from `grid/graph.jac` entities.
- Include a backup source's existing commitments before calculating spare capacity; prevent double-counting supply or served loads.
- Choose and document whole-load versus partial service, routing/tie behavior, numeric tolerance, and Tier 3 before Tier 2 shedding order.
- Keep candidate calculations separate from authoritative graph mutation.
- **Done when:** allocations obey per-source and per-line capacities and flow conservation; isolated demand stays unserved; all derived values come from one allocation.

Implementation evidence: `grid/allocation.jac` previews whole-load allocations without graph mutation. `tests/allocation_checks.jac` checks conservation at every bus, source/line ratings, physical faults, open switches, alternate routes, reverse tie flow, and backup commitments. The preview remains separate from `get_grid_state()` until validated application is implemented in Tasks 4–5.

## 4. Candidate validation and feedback

- The [Member 2 handoff](MEMBER_2_CONTRACTS.md#member-1-task-45-handoff-ready-to-implement) specifies action target IDs, `validate_plan` and application signatures, allocation projection, and the generation/revision stale-plan rule. Member 2's other tasks do not block this validator.
- Import Member 2's canonical typed recovery-plan/action contract from `shared/contracts.jac` rather than creating a competing schema in `grid/validation.jac`.
- Implement non-mutating validation in `grid/validation.jac` for the entire candidate state: action types and IDs, target kinds, numbers, switch/fault logic, conducting paths, source and line ratings, conservation, and priority policy.
- Reject deliberate Tier 1 shedding and return specific, factual reasons that support a Planner revision.
- **Done when:** invalid candidates leave authoritative state unchanged; Jac tests cover unknown IDs/actions, faulted and open paths, isolated loads, overloads, and duplicate capacity claims.

Implementation evidence: `grid/validation.jac` now exposes `validate_plan(RecoveryPlan) -> ValidationResult` using the merged Member 2 contract. It checks the active fault, generation, and revision before translating typed actions into a non-mutating allocation preview. The existing complete-state validator checks capacities, paths, flow conservation, whole-load service, and priority policy. Accepted results include copied candidate allocation and metrics calculated from that candidate. `tests/validation_checks.jac` covers accepted rerouting and shedding, stale/reset plans, invalid action kinds and targets, duplicate actions, physical faults, critical shedding, and forged allocations. [Validation handoff](MEMBER_1_VALIDATION.md) records the API and limits. `jac check .` passed for 22 Jac files with existing Member 3 client warnings; `jac test tests/validation_checks.jac -v` passed 12 tests.

## 5. Approved application and metrics

- Apply only a validated candidate in `grid/simulation.jac` whose state/version still matches the current graph. Define duplicate-request and stale-plan behavior with Member 2.
- Commit switch and service changes atomically from the validated candidate, then recompute allocation, status, and metrics. A successful reroute must retain the physical fault.
- Compute before/after metrics in `grid/metrics.jac`: critical demand preserved, deliberate shed kW, total unmet kW, available capacity, dispatch, and active faults/violations.
- **Done when:** rejected or stale candidates do not mutate state; repeated application cannot duplicate changes; metrics match the committed graph.

Implementation evidence: `grid/simulation.jac` now exposes `apply_approved_plan(RecoveryPlan) -> GraphState`. It calls the current validator, commits only an accepted candidate's switch, dispatch, service, shed, and line transfer values, increments the revision once, and projects authoritative metrics from those committed values. `grid/graph.jac` carries the committed readings and `grid/validation.jac` preserves earlier deliberate sheds during a later plan preview. `tests/application_checks.jac` covers accepted rerouting, physical-fault retention, rejected/infeasible plans, duplicate application, reset generation, deliberate shedding, projection/metric agreement, and reset after recovery. See [application handoff](MEMBER_1_APPLICATION.md). `jac check grid/` and `jac check tests/` passed; `jac test -d tests/ -v` passed 28 tests.

## 6. Scenario verification and integration

- Write Jac tests for the healthy baseline, each core fault, feasible and infeasible recovery, reset, and stale/duplicate requests.
- Record exact fixture values and expected outcomes for the three scenarios; label injected test proposals separately from live AI output.
- Integrate the `grid/validation.jac` and `grid/simulation.jac` handoff with Member 2 and the state/fault/reset API with Member 3 without taking ownership of `agents/`, `client/`, or `main.jac`.
- Run the installed Jac checker and task-specific runtime tests. Record actual commands, results, remaining limits, and the next integration step.
- **Done when:** the three scenarios are repeatable, failure leaves the fault visible, and the other members can consume the agreed state and validation contracts.

Implementation evidence: `grid/fallback.jac` supplies a snapshot-bound, non-mutating deterministic `RecoveryPlan` proposal for Member 2. `tests/scenario_checks.jac` checks all three fixed fault outcomes, a blocked-route failure, stale reset, and the fixed-proposal Member 2 triage handoff. [Scenario handoff](MEMBER_1_SCENARIOS.md) records exact actions, metrics, limits, and the remaining Member 2/3 work. Task 6 remains open until those consumers exercise the agreed interfaces and the joint live scenario run is recorded.

## Shared decisions to settle early

The guides leave the fixture values, field/enumeration names, exact operation envelopes, plan schema, routing policy, service granularity, stale-plan mechanism, and reset/run correlation open. Task 1 should publish the graph-side decisions promptly; Task 4 must use Member 2's plan contract. No illustrative IDs or numeric results in the guides should be treated as final fixture facts.
