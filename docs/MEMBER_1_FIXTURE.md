# Member 1 fixture and graph contract

This is a fictional, lossless kW network for decision-support simulation. It has 12 buses: three sources and nine loads. `GRID-01` is a container node and is not an electrical bus. Every ID is stable; display labels are never used as references.

## Sources

| ID | Capacity (kW) | Healthy dispatch (kW) | Healthy spare (kW) | Role |
|---|---:|---:|---:|---|
| `SRC-A` | 120 | 105 | 15 | North substation |
| `SRC-B` | 95 | 75 | 20 | South substation |
| `SRC-R` | 60 | 25 | 35 | Reserve generator; 25 kW already committed locally |

Total capacity is 275 kW; healthy dispatch is 205 kW. The reserve's 35 kW spare already accounts for its clinic and lighting load.

## Loads

| ID | Tier | Demand (kW) | Healthy source |
|---|---:|---:|---|
| `LOAD-HOSP` | 1 | 35 | `SRC-A` |
| `LOAD-WATER` | 1 | 25 | `SRC-A` |
| `LOAD-LAB` | 2 | 20 | `SRC-A` |
| `LOAD-OFFICE` | 3 | 25 | `SRC-A` |
| `LOAD-DATA` | 1 | 30 | `SRC-B` |
| `LOAD-PUMP` | 2 | 20 | `SRC-B` |
| `LOAD-HOMES` | 3 | 25 | `SRC-B` |
| `LOAD-CLINIC` | 1 | 15 | `SRC-R` |
| `LOAD-LIGHTS` | 3 | 10 | `SRC-R` |

Healthy Tier 1 demand is 105 kW and all of it has a conducting supply path. Total demand is 205 kW.

## Physical lines and switches

| Line ID | From → to | Rating (kW) | Healthy transfer (kW) | Initial switch |
|---|---|---:|---:|---|
| `LINE-A-H` | `SRC-A` → `LOAD-HOSP` | 65 | 60 | Closed |
| `LINE-H-W` | `LOAD-HOSP` → `LOAD-WATER` | 30 | 25 | Closed |
| `LINE-A-L` | `SRC-A` → `LOAD-LAB` | 50 | 45 | Closed |
| `LINE-L-O` | `LOAD-LAB` → `LOAD-OFFICE` | 30 | 25 | Closed |
| `LINE-B-D` | `SRC-B` → `LOAD-DATA` | 55 | 50 | Closed |
| `LINE-D-P` | `LOAD-DATA` → `LOAD-PUMP` | 25 | 20 | Closed |
| `LINE-B-HM` | `SRC-B` → `LOAD-HOMES` | 30 | 25 | Closed |
| `LINE-R-C` | `SRC-R` → `LOAD-CLINIC` | 30 | 25 | Closed |
| `LINE-C-LT` | `LOAD-CLINIC` → `LOAD-LIGHTS` | 15 | 10 | Closed |
| `TIE-B-H` | `SRC-B` → `LOAD-HOSP` | 65 | 0 | Open |
| `TIE-B-A` | `SRC-B` → `SRC-A` | 40 | 0 | Open |
| `TIE-R-A` | `SRC-R` → `SRC-A` | 40 | 0 | Open |

Each switch ID is `SW-` followed by the line suffix, e.g. `SW-A-H`, `SW-TIE-B-H`. The `PowerLine` edge stores physical fault and switch state independently; it conducts only when healthy and closed. The `TIE-B-H` route can reach the hospital and water treatment plant after `LINE-A-H` fails, subject to source and line capacities. Opening a tie is not a repair action.

The table gives one feasible healthy reference flow, not an allocation algorithm. The Jac test checks source dispatch, line ratings, and flow conservation at every load. Task 3 will compute allocations dynamically.

## Shared graph projection

`shared/contracts.jac` defines the canonical `GraphState` projection using `SourceView`, `LoadView`, `LineView`, and `GridMetrics`. Status strings and `conducting` are server-derived fields for the dashboard. `grid/graph.jac` defines persistent entities. `grid/simulation.jac` provides `get_grid_state()`, `inject_fault(fault_id)`, and `reset_simulation()` as Jac server functions. The client entry point has not yet imported or called them.

The graph-side fields and IDs should be ratified with the consumers before they implement against them. Recovery-plan and agent-event types remain Member 2's contract work.

## Named fault scenarios and current-state readings

These readings are **before recovery**. All switches keep their baseline positions. The Task 2 projection uses a conservative source-zone trip: if the unchanged demand reachable from a source exceeds its current capacity, that entire source zone is shown as unmet. This avoids reporting overloaded dispatch or pretending a transfer occurred. Task 3 will add allocation and routing; these figures are not recovery targets.

| Fault ID | Deterministic change | Current served / unmet (kW) | Available capacity / actual dispatch (kW) | Tier 1 preserved |
|---|---|---:|---:|---:|
| `FAULT-SOURCE-A` | `SRC-A` capacity 120 → 50 kW | 100 / 105 | 205 / 100 | 45 / 105 kW |
| `FAULT-LINE-A-H` | `LINE-A-H` physically faulted; switch stays closed | 145 / 60 | 275 / 145 | 45 / 105 kW |
| `FAULT-INSUFFICIENT-BACKUP` | `SRC-A` 120 → 50 kW and `SRC-R` 60 → 30 kW | 100 / 105 | 175 / 100 | 45 / 105 kW |

For the last case, `SRC-R` still dispatches 25 kW to its own loads, leaving only 5 kW spare. `SRC-B` has 20 kW spare. Their combined 25 kW spare is less than the 55 kW deficit between `SRC-A`'s unchanged 105 kW zone demand and its 50 kW capacity.

`shed_kw` is zero in these readings because no deliberate recovery shedding has occurred. `unmet_kw` includes demand disconnected by a fault or the conservative pre-recovery trip. An active fault remains in `active_fault_ids` and counts as one scenario fault; a physical line fault also remains on its `LineView`.

`inject_fault` accepts one of the three exact IDs. Repeating the same ID returns the unchanged state/revision. An unknown ID or a different fault before reset raises `ValueError` without mutation. `reset_simulation` rebuilds the baseline, clears the fault, and returns revision 0. A successful new injection increments the revision to 1. The graph projection fields and these reset semantics should be reviewed with Members 2 and 3 before their consumers depend on them.
