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

The current dashboard is a responsive layout with metric placeholders, topology and activity empty states, disabled scenario controls, and an incident section. It explicitly shows that no server is connected and does not show simulated values. The Jac files in `grid/`, `agents/`, and `shared/` mark ownership boundaries; their interfaces and behavior still need to be implemented.

## Next integration decisions

Agree the graph projection, recovery plan/action schema, validation feedback, event ordering, run IDs, and reset/stale-plan behavior before connecting modules. The open choices and required checks are in [the development guide](docs/GridWalk_AI_Development_Guide.md).

## Local setup

Verified on Windows with Python 3.14.7, Jac 0.16.7, and jac-client 0.3.25. From the repository root:

```powershell
python -m venv .venv
.venv/Scripts/python.exe -m pip install jaclang==0.16.7 jac-client==0.3.25
.venv/Scripts/jac.exe install
.venv/Scripts/jac.exe start main.jac --port 8001
```

Open `http://localhost:8001`. Installation requires network access, and the client build requires access to Bun's dependency cache. The shell was built, served, and inspected in Chrome at desktop, tablet, and phone widths. This verifies the layout; it does not verify backend operations or deployment.

See [Member 3 progress and checks](docs/Member_3_Progress.md) for the tested foundation and current integration limits.
