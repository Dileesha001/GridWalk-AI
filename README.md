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

The dashboard renders twelve labeled buses and twelve physical lines using the canonical graph projection. A read-only selector loads fixed examples of a healthy grid, reduced source capacity, a line fault, and rerouting with shedding. A component inspector shows capacity/dispatch, priority/service, and independent physical-fault/switch states. These are display examples, not simulation or AI results. Live scenario controls remain disabled; metric cards and activity/results remain placeholders.

## Next integration decisions

Agree the graph projection, recovery plan/action schema, validation feedback, event ordering, run IDs, and reset/stale-plan behavior before connecting modules. The open choices and required checks are in [the development guide](docs/GridWalk_AI_Development_Guide.md).

## Local setup

Use Ubuntu in WSL 2 and the native Jac 0.34.13 binary. From the repository root in PowerShell, enter WSL with `wsl`, then run:

```bash
curl -fsSL https://raw.githubusercontent.com/jaseci-labs/jaseci/main/scripts/install.sh | bash -s -- --version 0.34.13
export PATH="$HOME/.local/bin:$PATH"
jac --version                      # must report 0.34.13
jac install                        # project dependencies; Jac itself comes from the binary
jac check . -n
jac start --dev main.jac --port 8001
```

Open `http://localhost:8001`. Development mode recompiles changed client modules and uses port 8002 for the API. Keep the real Gemini key in the ignored root `.env` as `GOOGLE_API_KEY=...`; never commit it. Installation requires network access. The older Windows Python/pip commands in milestone notes document checks done before this migration and are not the current setup.

See [topology preview notes](docs/Topology_Preview.md) for the display states and limitations. Earlier browser and runtime checks were performed on Jac 0.16.7; they are not evidence of end-to-end recovery on 0.34.13.

See [Member 3 progress and checks](docs/Member_3_Progress.md) for the tested foundation and current integration limits.

See [Jac 0.34.13 migration notes](docs/JAC_034_MIGRATION.md) for the WSL compiler and client build results.
