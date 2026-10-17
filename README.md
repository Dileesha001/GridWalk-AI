# GridWalk AI

Jac-first microgrid recovery decision-support simulator. Graph and fault foundations and a read-only topology preview are available; recovery orchestration and live dashboard integration are still in progress.

## Layout

| Path | Owner | Purpose |
| --- | --- | --- |
| `main.jac` | Member 3 | Full-stack client entry point |
| `client/` | Member 3 | Jac dashboard and future client adapter |
| `grid/` | Member 1 | Graph model, fixture, faults, validation, application, metrics |
| `agents/` | Member 2 | Monitor, Planner, Auditor, recovery orchestration |
| `shared/contracts.jac` | Shared | One authoritative location for ratified typed contracts |
| `docs/` | Team | Development guide, agent guidelines, member handoffs |

The dashboard follows the healthy Figma recovery console, using Jac components and style dictionaries with locally bundled design assets and fonts. Twelve labeled buses and twelve physical lines use the canonical graph projection. A read-only selector loads fixed examples of a healthy grid, reduced source capacity, a line fault, and rerouting with shedding. Click a bus or use the component selector to inspect capacity/dispatch, priority/service, and independent physical-fault/switch states. Metric cards show the selected fixed snapshot; live scenario controls remain disabled and activity cards describe waiting roles. These are display examples, not simulation or AI results.

See the [implementation order and current task statuses](docs/Dashboard_Implementation_Status.md). The healthy console refresh is verified locally; remaining Figma workflow screens and live integration are pending.

## Next integration decisions

Agree the graph projection, recovery plan/action schema, validation feedback, event ordering, run IDs, and reset/stale-plan behavior before connecting modules. The open choices and required checks are in [the development guide](docs/GridWalk_AI_Development_Guide.md).

## Local setup

Verified on Windows with Python 3.14.7, Jac 0.16.7, and jac-client 0.3.25. From the repository root:

```powershell
python -m venv .venv
.venv/Scripts/python.exe -m pip install jaclang==0.16.7 jac-client==0.3.25
.venv/Scripts/jac.exe install
.venv/Scripts/jac.exe start --dev main.jac --port 8001
```

Open `http://localhost:8001`. Development mode recompiles changed client modules and uses port 8002 for the API. Installation requires network access, and the client build requires access to Bun's dependency cache. The console was compiled, served, and inspected in Chrome at desktop, tablet, and phone widths. This verifies the preview; it does not verify end-to-end recovery or deployment.

To check the built app, stop the dev server first, then run `.venv/Scripts/jac.exe build main.jac` and `.venv/Scripts/jac.exe start main.jac --port 8001`. On Windows a running dev server can lock esbuild during a build. With a local server running, `.venv/Scripts/python.exe scripts/verify_console.py` checks asset/font loading, responsive overflow, bus and keyboard inspection, all four fixed snapshots, fault retention, reduced motion, and the skip link. It uses the installed Jac browser engine and Chrome; set `JACBROWSER_CHROME` if needed.

Run topology checks with `.venv/Scripts/python.exe scripts/check_foundation.py topology`. See [topology preview notes](docs/Topology_Preview.md) for the display states and limitations.

See [progress and checks](docs/Member_3_Progress.md) for historical milestones and the [design review](docs/Design_Review.md) for current checks and limitations.
