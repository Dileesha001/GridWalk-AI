# Member 3 progress

## Milestone 1: dashboard data foundation

This milestone supplies client presentation types, payload validation, fixed preview
snapshots, and client-runtime tests. The existing dashboard shell is unchanged.
It does not implement a simulation, agents, live API integration, or deployment.

### Files

- `client/models.cl.jac`: typed presentation objects, metric formatting, honest
  execution labels, and run-filtered, ordered, deduplicated activity.
- `client/decode.cl.jac`: JSON boundary checks for numeric values, IDs, references,
  flags, priorities, recovery outcomes, and execution modes.
- `client/preview.cl.jac`: explicitly labeled display examples for a healthy grid,
  reduced source capacity, line failure, and insufficient backup. The 12 fictional
  nodes and their numbers are provisional UI examples, not Member 1's fixture.
- `client/foundation_tests.cl.jac`: seven runtime checks; no model/API access.
- `scripts/check_foundation.py`: compiles the Jac tests and sibling client modules,
  then executes them using project-local Bun. Jac 0.16.7's normal client test
  harness does not copy sibling modules into its temporary directory, so invoking
  `jac test client/foundation_tests.cl.jac` currently fails before assertions run.

The presentation types are draft client types, **not ratified shared server
contracts**. Members 1 and 2 retain ownership of graph and recovery schemas in
`shared/contracts.jac`. Replace or adapt these presentation types at the single
adapter boundary when the authoritative contracts arrive.

### Verified environment and checks

Windows; Python 3.14.7; Jac 0.16.7; jac-client 0.3.25; project-local Bun 1.3.11.
The Jac client plugin migrated the old npm meta-packages in `jac.toml` to its
individual supported dependencies. `jac install` completed successfully.

From the repository root, using the project virtual environment:

```powershell
python -m venv .venv
.venv/Scripts/python.exe -m pip install jaclang==0.16.7 jac-client==0.3.25
.venv/Scripts/jac.exe install
.venv/Scripts/jac.exe check client/models.cl.jac client/preview.cl.jac client/decode.cl.jac client/foundation_tests.cl.jac -n
.venv/Scripts/python.exe scripts/check_foundation.py
```

Static check: all four files pass. `-n` hides warnings; dynamic JSON boundary
annotations still produce `any` warnings without that flag. Runtime: seven tests
pass, covering preview consistency/labels, physical fault retention, unmet demand,
event ordering/run isolation, invalid payload rejection, unavailable critical
percentage, and prevention of preview results being accepted as live results.

Runtime tests caught and fixed missing client exports, positional construction of
client objects, and the difference between plain JSON objects and Jac's dictionary
runtime type. Passing these tests does not verify backend arithmetic or safety.

## Step 4: responsive dashboard shell — complete

`client/Dashboard.cl.jac`, `client/ShellPanel.cl.jac`, and `client/dashboard.css`
provide the header and section navigation, metric placeholders, topology area,
disabled scenario controls, activity empty state, and incident empty state.
The shell explicitly says "Layout preview" and "Not connected". No preview
numbers, fake activity, or live operations are wired into this milestone.

Verified with:

```powershell
.venv/Scripts/jac.exe check main.jac client/Dashboard.cl.jac client/ShellPanel.cl.jac -n
.venv/Scripts/jac.exe start main.jac --port 8001
```

All three static checks passed. The client bundle built successfully and served
at `http://localhost:8001`. Chrome CDP viewport checks at 1440, 1024, 768, and 375
pixels confirmed no horizontal overflow, four panels, three disabled action
buttons, a disabled scenario selector, and valid description links. Desktop,
tablet, and phone screenshots were inspected. The keyboard skip link focuses the
main workspace; reduced-motion removes transitions; the browser console was clean.
Screenshots and temporary browser verification output live under ignored `.jac/`.

No changes were made to Members 1/2's modules. Draft components and the draft
adapter for later steps remain separate from the shell's imports.

## Step 5: topology preview — complete

The dashboard now renders a read-only topology and component inspector using
`GraphState` and related types imported from `shared/contracts.jac`. Stable IDs,
baseline numbers, and wiring match the fixture documentation. The earlier draft
decoder and live adapter have not been integrated; they need alignment with the
canonical contracts in the live integration step.

Display examples cover the baseline, source derating, a physical line fault, and
rerouted service with deliberate shedding. Selecting a snapshot never calls
simulation mutation or AI endpoints. Fault state stays visible after rerouting.
See [topology preview notes](Topology_Preview.md) for files and validation evidence.

## Next: Step 6

Connect scenario controls and metrics to server operations, preserving server
authority. Activity, incident output, recovery orchestration integration,
concurrency handling, end-to-end scenario checks, and deployment remain pending.
