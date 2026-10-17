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

## Next milestone

Build and visually verify the dashboard shell, topology, metrics, controls, and
activity views using preview data. Then ratify backend fields/routes, event
delivery, version checks, duplicate requests, and reset semantics before enabling
live integration. Deployment and all three end-to-end scenarios remain pending.
