# GridWalk AI

Jac-first microgrid recovery decision-support simulator. The project is currently an initial full-stack scaffold; simulation, AI planning, and dashboard integration still need implementation.

## Layout

| Path | Owner | Purpose |
| --- | --- | --- |
| `main.jac` | Member 3 | Full-stack client entry point |
| `client/` | Member 3 | Jac dashboard and future client adapter |
| `grid/` | Member 1 | Graph model, fixture, faults, validation, application, metrics |
| `agents/` | Member 2 | Monitor, Planner, Auditor, recovery orchestration |
| `shared/contracts.jac` | Shared | One authoritative location for ratified typed contracts |
| `docs/` | Team | Development guide, agent guidelines, member handoffs |

The current dashboard is a shell and does not show simulated values. The Jac files in `grid/`, `agents/`, and `shared/` mark ownership boundaries; their interfaces and behavior still need to be implemented.

## Next integration decisions

Agree the graph projection, recovery plan/action schema, validation feedback, event ordering, run IDs, and reset/stale-plan behavior before connecting modules. The open choices and required checks are in [the development guide](docs/GridWalk_AI_Development_Guide.md).

## Local setup

The scaffold was based on Jac 0.16.7's `fullstack` template. Install Jac and its client plugin in the development environment, then run `jac install` and `jac start --dev main.jac` from the repository root. Package installation and the live app have not yet been verified in this workspace.
