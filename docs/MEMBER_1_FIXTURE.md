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

`shared/contracts.jac` defines the canonical `GraphState` projection using `SourceView`, `LoadView`, `LineView`, and `GridMetrics`. Status strings and `conducting` are server-derived fields for the dashboard. `grid/graph.jac` defines persistent entities. The projection types are ready for Member 2/3 review; `get_grid_state()` and live derived metrics are Task 2/5 work, so these values are not yet served by the application.

The graph-side fields and IDs should be ratified with the consumers before they implement against them. Recovery-plan and agent-event types remain Member 2's contract work.
