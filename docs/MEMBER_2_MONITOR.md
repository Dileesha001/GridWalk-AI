# Member 2 Monitor handoff

`agents/monitor.jac` defines `TelemetryMonitor`, a Jac walker, and `inspect_grid()`, its in-process entry point for the later Planner. `inspect_grid()` asks Member 1's `get_grid_state()` for the current authoritative projection, then spawns the walker from `root`. The walker visits the grid and every bus, reads each outgoing `PowerLine` edge, and reports one typed `MonitorFacts` object. It rejects an incomplete traversal instead of presenting partial facts as complete.

The facts distinguish:

- **Affected loads:** current served kW is below demand in `GraphState`.
- **Isolated loads:** no conducting path from a source with positive available capacity. A connected load can still be unserved because capacity or line ratings prevent allocation.
- **Faulted lines:** physically faulted edges, even if their switch remains closed.
- **Conducting lines:** physically healthy edges with closed switches.
- **Derated sources and overloads:** values observed in the authoritative source and line projections.
- **Backup sources with spare:** current capacity exceeds dispatch. This alone does not prove a feasible transfer path or amount.

All ID lists are sorted for stable Planner inputs. The Monitor does not mutate graph state, propose actions, certify capacity, or claim restored service. Member 1's validator remains responsible for candidate feasibility.

The current `get_grid_state()` reports conservative pre-recovery service: an overloaded source zone may appear entirely unmet. `MonitorFacts` reports that state as observed; it does not reinterpret those readings as final recovery metrics. This branch needs no model credential. The next Planner branch can consume `inspect_grid()` and these typed facts after this branch merges.

Jac 0.16.7 compiled `agents/monitor.jac`. A project-wide Jac check completed with warnings in Member 3 client files; no Monitor runtime scenario was exercised in this branch.
