# Dashboard implementation task chart

This chart tracks implementation, validation, and remaining work separately.
“Done” means the stated scope is implemented and has the listed evidence; it does
not imply that later steps or deployment are complete.

| Step | Work breakdown | Status and evidence | Remaining work / exit condition |
|---|---|---|---|
| 1. Requirements, ownership, and invariants | Define the demo scope; set server authority for simulation state; require deterministic validation before allocation; keep previews distinct from live state. | **Done.** Recovery decisions remain server-side. Proposed plans are validated before application, and the dashboard distinguishes fixed previews from live simulation. | None for the current scope. Reopen only if requirements or safety invariants change. |
| 2. Jac environment and application setup | Pin Jac and client tooling; establish the supported WSL setup; document reproducible checks; compile web and sealed targets. | **Done.** The repository pins Jac 0.34.13 for WSL 2. Prior full verification recorded 33 static client checks, client runtime tests, server regression tests, web build, and sealed build. The native executable and checksum are documented. | Re-run the pinned checks after the latest fallback commit when WSL is available. The current Windows environment has Jac 0.16.7 and cannot access WSL. |
| 3. Preview foundation and payload validation | Build the fixed preview experience; validate response envelopes and client data before rendering; keep preview data independent of live API state. | **Done for preview.** Nine preview/foundation runtime checks were recorded, including the response-envelope correction. Canonical live payload decoding was completed later in Step 6. | None for the preview scope. |
| 4. Dashboard shell | Implement the healthy-grid console layout; connect sidebar, panels, and responsive states; preserve the Figma reference workflow. | **Done.** The console is authored in Jac, and prior responsive browser checks passed. | Fresh browser review after final recovery wiring remains part of Step 9. |
| 5. Read-only topology and inspection | Render the network; support selection and details for buses, lines, and components; show the fixed fault scenarios without mutating the graph. | **Done.** Four fixed snapshots, twelve buses, component/line inspection, and retained physical-fault visualization are implemented. Six topology runtime checks were recorded. | None for read-only topology. |
| 6. Live grid reads, fault/reset controls, and measured metrics | Read canonical server state; inject each supported fault; reset to a new generation; refresh after mutations; display measured metrics and preserve separate previews. | **Done locally.** Canonical decoding, all three fault scenarios, reset, fresh reads, server metrics, and reset persistence were checked. HTTP verification is documented in [Live Grid Integration](Live_Grid_Integration.md). | Re-run the live HTTP check after the latest commit when the pinned environment is available. |
| 7. Recovery controls, events, and incident outcomes | Submit recovery against the observed generation/revision; validate and apply server-side; persist ordered correlated events and factual outcomes; show committed actions and before/after measurements. | **Implemented.** The dashboard reads canonical recovery results and ordered events. Prior deterministic runtime and HTTP checks passed, including stale-revision rejection and no-commit evidence. Details are in [Recovery Integration](Recovery_Integration.md). | Run the recovery suite and a fresh browser recovery walkthrough after the latest fallback changes. Live-provider behavior remains dependent on configured credentials and provider availability. |
| 8. Busy, rejection, revision, error, fallback, and stale-response handling | Guard duplicate UI requests; reject stale generation/revision; preserve last confirmed state on failed refresh; route primary AI → Groq backup → deterministic proposal; record fallback transitions and actual execution mode. | **Implemented; verification partial.** The deterministic planner now follows provider failure/exhaustion. Its candidate goes through current-snapshot checks, validation, and approved application. A forced-provider-failure runtime test was added. Changed Jac files pass the available local static check; `git diff --check` passed. Commit `e46aff7` is pushed to `origin/dashboard`. | Run the forced-failure test and full suite under Jac 0.34.13. Verify timeout/deadline behavior and assess cross-tab races with a concurrent request test. Existing stale guards are present, but dedicated cross-tab verification is not recorded. |
| 9. End-to-end, performance, and accessibility verification | Exercise live fault/reset/recovery workflows; test responsive layouts, keyboard use, and reduced motion; measure load/render performance under stated conditions. | **Partly covered.** Prior browser checks covered live fault/reset and responsive layouts; preview keyboard and reduced-motion checks passed. | Complete a fresh end-to-end recovery browser run. Measure and record performance; finish accessibility checks for the recovery flow. Do not claim FPS or performance targets until measured. |
| 10. Run instructions, demo, deployment, and submission artifacts | Maintain local setup and run instructions; prepare a demo path and required submission material; optionally deploy and verify hosted behavior. | **Partly prepared.** Local setup instructions exist. Deployment/hosting is not verified. | Complete final run instructions and demo artifacts. If deployment is in scope, deploy and verify the hosted application; otherwise document that hosting is out of scope. |

## Current verification checkpoint

Commit `e46aff7` (`Add deterministic recovery fallback`) is on `dashboard` and
was pushed to `origin/dashboard`. The changed orchestration and test files pass
static checking with the locally available Jac 0.16.7, and `git diff --check`
reported no whitespace errors. The project requires Jac 0.34.13 on WSL 2 for its
authoritative checks. WSL access was denied in this environment, so the new
runtime test and full suite have not been run against that pinned version. Three
untracked client drafts are present in the workspace and are not part of the
commit.

See [live integration verification](Live_Grid_Integration.md),
[recovery integration](Recovery_Integration.md), and
[design review](Design_Review.md) for the supporting implementation notes.
The [WSL setup requirement](WSL_Setup.md) is the supported environment for
reproducing the pinned Jac checks. PR creation remains with the user.
