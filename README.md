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

The required build environment is **Ubuntu on WSL 2 with native Jac 0.34.13**. See [WSL setup and verification](docs/WSL_Setup.md) for the pinned, checksum-verified installer and source sync. Jac itself comes from the native binary; the earlier Windows Python/pip setup is superseded.

Inside WSL, from the Linux build copy:

```bash
jac --version                      # must report 0.34.13
jac install                        # install project dependencies
bash scripts/verify_wsl.sh
jac start main.jac --port 8011
```

Open `http://localhost:8011` in the Windows browser. Keep Linux dependencies separate from the old Windows `.venv/` and `.jac/`. After editing the Windows repository, sync its source into the Linux build copy before checking again. Installation requires network access and access to Bun's dependency cache.

For hot reload, use `jac start --dev main.jac --port 8001`; open `http://localhost:8001`, with the API on port 8002. To build the web client separately, stop the dev server and run `jac build --client web`.

For live recovery calls, keep `GOOGLE_API_KEY` and optional Groq backup `GROQ_API_KEY` in the ignored `.env` at the running project's root. Do not commit keys. The preview checks do not require a live model call. See [Member 2's provider budgets and pending fallback handoff](docs/MEMBER_2_FALLBACK_BUDGETS.md).

The verification script covers client syntax/types, foundation and topology regressions, simulation/validation/application regressions, the web shell, and the sealed app artifact. Current WSL results are recorded in the [setup guide](docs/WSL_Setup.md). Historical Windows checks remain in earlier milestone notes; neither preview checks nor a successful build establish end-to-end recovery or deployment.

See [topology preview notes](docs/Topology_Preview.md) for display states and limitations, [progress and checks](docs/Member_3_Progress.md) for historical milestones, the [design review](docs/Design_Review.md) for console checks, and the [Jac 0.34.13 migration notes](docs/JAC_034_MIGRATION.md) for the upstream migration results.
