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

The required build environment is **Jac 0.34.13 in WSL 2**. See [WSL setup and verification](docs/WSL_Setup.md) for the pinned installer, source sync, and exact commands.

Inside WSL, from the Linux build copy:

```bash
jac --version
jac install
bash scripts/verify_wsl.sh
jac start main.jac --port 8011
```

Open `http://localhost:8011` in the Windows browser. Keep Linux build dependencies separate from the old Windows `.venv/` and `.jac/`. After editing the Windows repository, sync its source into the Linux build copy before checking again. The earlier Windows Jac 0.16.7 instructions are superseded.

The checks cover client syntax/types, foundation and topology regressions, simulation regressions, the web shell, and the sealed app artifact. Browser verification covers the preview; it does not establish end-to-end recovery or deployment. See [topology preview notes](docs/Topology_Preview.md) for display states and limitations.

See [progress and checks](docs/Member_3_Progress.md) for historical milestones and the [design review](docs/Design_Review.md) for current checks and limitations.
