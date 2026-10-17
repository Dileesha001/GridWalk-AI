# Recovery dashboard integration

The live dashboard calls `run_triage`, then reads canonical grid state, recorded
events, and results. The entry explicitly imports all three recovery endpoints
because the client uses raw fetch. The UI displays ordered evidence, execution
mode, committed actions, proposal/revision counts, and server-measured before/after
metrics. Fixed previews remain separate.

Controls block duplicate requests and conflicting mutations. Generation, revision,
run identity, complete event sequence, and metric checks reject mismatched evidence.
Failed confirmation retains the last confirmed grid and requires refresh. Recovery
uses a 120-second client timeout; timing out does not cancel server processing.
Events are displayed together after completion, not streamed during execution.

Verification on 2026-10-17 with native Jac 0.34.13 on WSL:

- 33 entry/client static checks passed.
- 29 client runtime tests passed: nine foundation, six topology, six grid, eight recovery.
- 39 server regression tests passed, including three recovery event persistence tests.
- Web client and sealed application builds passed, including the corrected
  endpoint registration entry.
- HTTP checks against the fixed-proposal fixture passed all three faults. Line
  recovery produced eight ordered events including rejection and revision, with
  partial recovery; source recovery produced five events and partial recovery;
  insufficient backup produced seven events and an infeasible outcome with no
  committed actions. Results matched fresh server metrics. Reset cleared the
  current-generation event feed.

Reproduce the HTTP checks using a separate local test server:

```bash
jac start scripts/recovery_ui_fixture.jac --port 8013
python scripts/verify_recovery_api.py http://127.0.0.1:8013
```

The fixture is API-only and supplies fixed proposals through real validation and
application. It makes no live AI calls and labels applied results deterministic.
Run the verification helper only against that fixture. Product startup remains
`jac start main.jac --port 8011`.

Browser automation was unavailable in this session. Fresh recovery browser checks,
live-provider access, provider fallback, measured performance, and deployment are
not established by these checks.
