# Step 6: live simulation integration

The console starts with a live server read. No example metrics are substituted
while connecting or after a failed initial read. Fixed display snapshots are an
explicit separate mode that sends no simulator or recovery requests.

## Implementation

- `main.jac` registers `get_grid_state`, `inject_fault`, and `reset_simulation`.
- `client/grid_client.cl.jac` owns same-origin JSON transport and a 15-second
  timeout. `grid_decode.cl.jac` validates the canonical `GraphState` envelope,
  identities, numeric fields, nullable critical percentage, and physical line
  consistency. Signed transfers remain signed; server outcomes are not recomputed.
- `Dashboard.cl.jac` and its implementation annex coordinate the live state,
  scenario selection, injection, reset, and refresh. A synchronous request lock
  prevents duplicate submissions. Each mutation is followed by a fresh read.
  Failed confirmation retains the previous snapshot and blocks mutations until
  refresh succeeds. An unmounted request cannot update the shell.
- The topology uses stable bus IDs and actual line states. Unknown bus IDs receive
  visible positions on an expanded canvas. Supply and metric panels use the
  server projection. Physical faults remain independent from switch closure.
- Reset attaches the replacement fixture before deleting the previous branch.
  Deleting the old branch first produced a generation mismatch on the next HTTP
  request under Jac 0.34.13. Cross-request API verification covers this regression.

All application changes and styles are Jac. Python and Bash files are verification
tooling. Existing untracked draft components and the draft adapter remain excluded.

## Usage

1. Start one WSL server from the synced Linux build copy using Jac 0.34.13.
2. Open the console and wait for “Live state confirmed”.
3. Choose Source capacity, Line failure, or Backup shortage; click Inject fault.
4. Inspect the updated topology, source dispatch, and server metrics.
5. Reset before injecting a different fault. If confirmation fails, use Refresh
   live state before attempting another change.

The anonymous local console uses a shared guest simulation. A second tab can
change it; use refresh to read the current state. Do not run multiple server
processes against the same local database during verification.

## Verification

Native Jac 0.34.13 on Ubuntu WSL 2:

- 28 entry/client static checks pass.
- Nine foundation, six topology, and six canonical live-decoder runtime tests pass.
- All 28 fixture/fault/allocation/validation/application tests pass.
- Web and sealed application builds pass with normal type checking enabled.

Against the running WSL server:

```powershell
.venv/Scripts/python.exe scripts/verify_grid_api.py http://127.0.0.1:8012
.venv/Scripts/python.exe scripts/verify_console.py http://127.0.0.1:8012
.venv/Scripts/python.exe scripts/verify_live_console.py http://127.0.0.1:8012
```

The Python environment in these commands only drives HTTP and Windows Chrome.
It does not build the application. Use a local test server: the API and live UI
checks intentionally inject faults and reset the shared guest simulation.

| Scenario | Served demand | Available capacity |
|---|---:|---:|
| Healthy | 205 kW | 275 kW |
| Source capacity fault | 100 kW | 205 kW |
| Physical line fault | 145 kW | 275 kW |
| Backup shortage | 100 kW | 175 kW |

HTTP checks cover generation persistence, revision changes, idempotent repeated
injection, rejected conflicting/unknown faults, independent switch/fault state,
and reset after every scenario. Browser checks cover all three scenarios, reload
persistence, duplicate-click prevention, malformed confirmation after a committed
mutation, timeout/abort handling, retained values, and successful refresh recovery. Fixed preview changes
send zero requests. Live and preview pages fit 1440, 1024, 768, and 375 pixel widths.
Preview keyboard selection, inspection focus, reduced motion, local assets/fonts,
and the skip link pass. Browser consoles report no errors or warnings.

Screenshots are local under ignored `.jac/console-verification/`. The status
banner uses a 160 ms opacity animation and respects reduced motion. These
checks do not measure FPS or establish a performance budget.

## Remaining work

Run recovery stays disabled. Agent events and recovery incident outcomes are not
fabricated. Step 7 connects real orchestration and ordered events; Step 8 completes
recovery-run concurrency/revision/fallback handling. Full recovery, measured
performance, and deployment are still pending. No provider calls are made in
Step 6 verification.
