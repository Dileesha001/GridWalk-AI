# Topology preview

The notes below describe the original Step 5 renderer. The active dashboard now
uses the healthy Figma console and Jac style dictionaries. Current verification,
inspection controls, and fixed-fixture limitations are recorded in the
[design review](Design_Review.md). The original renderer and layout tests remain
available, including their handling of unknown bus IDs.

Step 5 adds a read-only SVG topology with labeled sources, loads, physical lines,
switches, and kW values. The component selector provides keyboard-accessible text
inspection. It distinguishes capacity from dispatch, demand from service, and
physical faults from open/closed switches. Signed line transfers retain their
direction; the inspector explains negative values.

## Data and ownership

`client/TopologyDiagram.cl.jac`, `client/TopologyDetails.cl.jac`, and the layout
helpers consume the canonical types from `shared/contracts.jac`. No new graph
schema is defined. All graph, allocation, simulation, and agent files remain
unchanged by this step. The branch was first advanced to the merged `dev` state
to consume the shared types and fixture documentation.

`client/topology_examples.cl.jac` contains fixed display data matching the twelve
bus IDs, twelve lines, and healthy values in the fixture documentation. Its
examples are clearly labeled and do not call a simulator, validator, or model:

| Example | What the view demonstrates |
|---|---|
| Healthy baseline | 3 sources, 9 loads, 205 kW dispatch, normally open ties |
| Source capacity reduced | Derated source and unmet loads, without pretending reserve was dispatched |
| Physical line fault | A closed switch on a physically faulted line still does not conduct |
| Rerouted service with shedding | Rerouted critical loads, 25 kW deliberately shed housing, the original physical fault retained |

The rerouted example is an illustrative display allocation, not an approved plan
or recorded recovery. All examples pass arithmetic checks for source and line
capacity, power conservation at each bus, and zero transfer on nonconducting lines.
Those checks do not replace the project's deterministic validator.

## Rendering and interaction

- Positions use stable bus IDs, so reordering a response does not move facilities.
- Unknown bus IDs receive distinct positions below the known fixture; the canvas
  height expands. Live payload validation is part of later adapter integration.
- Diagram labels and the inspector expose IDs, statuses, priority, service, and
  switch/fault states. Color is supplemented by text and dashed open lines.
- Native snapshot and component selectors support keyboard input. Snapshot
  selection remains independent of the disabled simulation controls.
- On phones and tablets, the diagram scrolls horizontally inside its panel; the
  surrounding page does not overflow.

## Verification

The commands and browser results below record the original Jac 0.16.7 milestone. For the current WSL 2 / Jac 0.34.13 setup, use the repository README.

```powershell
.venv/Scripts/jac.exe check main.jac client/Dashboard.cl.jac client/Topology.cl.jac client/TopologyDiagram.cl.jac client/TopologyDetails.cl.jac client/topology_examples.cl.jac client/topology_layout.cl.jac client/topology_tests.cl.jac -n
.venv/Scripts/python.exe scripts/check_foundation.py topology
.venv/Scripts/python.exe scripts/check_foundation.py
.venv/Scripts/jac.exe start --dev main.jac --port 8001
```

Targeted static checks pass. `-n` hides warnings; the installed checker reports
warnings for some native SVG tag names. Six topology runtime tests pass, and the
seven existing foundation tests still pass. The client compiled and served in
development mode at `http://localhost:8001`.

Chrome checks passed at exact viewport widths 1440, 1024, 768, and 375 pixels:
no page overflow, twelve buses and twelve lines, working keyboard selectors,
independent switch/fault inspection, and retained fault state with rerouted loads.
Desktop and phone screenshots were inspected. A list-key warning discovered in
the fault banner was fixed; the final console had no application errors or
warnings. Temporary browser checks and screenshots are under ignored `.jac/`.

Step 6 will connect controls and metrics. No end-to-end recovery, provider access,
or hosting result is claimed by this step.
