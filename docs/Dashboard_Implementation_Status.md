# Dashboard implementation task chart

This chart tracks implementation, validation, and remaining work separately.
“Done” means the stated scope is implemented and has the listed evidence; it does
not imply that later steps or deployment are complete.

| Step | Work breakdown | Status and evidence | Remaining work / exit condition |
|---|---|---|---|
| 1. Requirements, ownership, and invariants | Define the demo scope; set server authority for simulation state; require deterministic validation before allocation; keep previews distinct from live state. | **Done.** Recovery decisions remain server-side. Proposed plans are validated before application, and the dashboard distinguishes fixed previews from live simulation. | None for the current scope. Reopen only if requirements or safety invariants change. |
| 2. Jac environment and application setup | Pin Jac and client tooling; establish the supported WSL setup; document reproducible checks; compile web and sealed targets. | **Done.** The repository pins Jac 0.34.13 for WSL 2. With WSL available, the updated Jac suite passed (49 tests), tracked client static checks passed (33), and the web build passed. The native executable and checksum are documented. | The sealed build/full client scan is currently blocked by E1032 in the separate untracked `client/adapter.cl.jac` draft. |
| 3. Preview foundation and payload validation | Build the fixed preview experience; validate response envelopes and client data before rendering; keep preview data independent of live API state. | **Done for preview.** Nine preview/foundation runtime checks were recorded, including the response-envelope correction. Canonical live payload decoding was completed later in Step 6. | None for the preview scope. |
| 4. Dashboard shell | Implement the healthy-grid console layout; connect sidebar, panels, and responsive states; preserve the Figma reference workflow. | **Done.** The console is authored in Jac, and prior responsive browser checks passed. | Fresh browser review after final recovery wiring remains part of Step 9. |
| 5. Read-only topology and inspection | Render the network; support selection and details for buses, lines, and components; show the fixed fault scenarios without mutating the graph. | **Done.** Four fixed snapshots, twelve buses, component/line inspection, and retained physical-fault visualization are implemented. Six topology runtime checks were recorded. | None for read-only topology. |
| 6. Live grid reads, fault/reset controls, and measured metrics | Read canonical server state; inject each supported fault; reset to a new generation; refresh after mutations; display measured metrics and preserve separate previews. | **Done locally.** Canonical decoding, all three fault scenarios, reset, fresh reads, server metrics, and reset persistence were checked. HTTP verification is documented in [Live Grid Integration](Live_Grid_Integration.md). | Re-run the live HTTP check after the latest commit when the pinned environment is available. |
| 7. Recovery controls, events, and incident outcomes | Submit recovery against the observed generation/revision; validate and apply server-side; persist ordered correlated events and factual outcomes; show committed actions and before/after measurements. | **Implemented; API/runtime checks pass.** Fixture HTTP checks cover stale rejection, reset evidence, all three outcomes, ordered events, and two concurrent requests with exactly one commit. Details are in [Recovery Integration](Recovery_Integration.md). | A fresh browser recovery walkthrough remains unverified because Chrome and Edge failed to start with DevTools enabled. |
| 8. Busy, rejection, revision, error, fallback, and stale-response handling | Guard duplicate UI requests; reject stale generation/revision; preserve last confirmed state on failed refresh; route primary AI → Groq backup → deterministic proposal; record fallback transitions and actual execution mode. | **Implemented; automated checks pass.** Full Jac suite: 49 passed. Deadline and provider-timeout tests pass, and concurrency verification observed one `applied` and one `stale` result with one revision increment. Tracked client static checks: 33 passed. Web build passed. | The live smoke completed through deterministic fallback after provider requests failed; successful live AI-provider behavior is not verified. The sealed build/full client scan encounters E1032 in the separate untracked `client/adapter.cl.jac` draft. |
| 9. End-to-end, performance, and accessibility verification | Exercise live fault/reset/recovery workflows; test responsive layouts, keyboard use, and reduced motion; measure load/render performance under stated conditions. | **Partly covered.** Prior browser checks covered live fault/reset and responsive layouts; preview keyboard and reduced-motion checks passed. | Complete a fresh recovery browser run; browser startup is unavailable in this environment. Measure performance and finish accessibility checks for the recovery flow. |
| 10. Run instructions, demo, deployment, and submission artifacts | Maintain local setup and run instructions; prepare a demo path and required submission material; optionally deploy and verify hosted behavior. | **Partly prepared.** Local setup instructions exist. Deployment/hosting is not verified. | Complete final run instructions and demo artifacts. If deployment is in scope, deploy and verify the hosted application; otherwise document that hosting is out of scope. |

## Current verification checkpoint

Commit `e46aff7` (`Add deterministic recovery fallback`) is on `dashboard` and
was pushed to `origin/dashboard`. WSL now provides the pinned Jac 0.34.13. All
49 project Jac tests passed; the four foundation suites passed 9, 6, 6, and 8
checks; 33 tracked client static checks passed; and `jac build --client web
main.jac` succeeded. Recovery API verification passed stale-revision rejection,
exactly-once concurrent application, all three scenario outcomes, ordered event
checks, and reset evidence. The live smoke applied a validated recovery through
deterministic fallback (revision 1→2, served load 145→180 kW, critical
preservation 100%, two committed actions). Both configured provider paths failed
during this run, so live AI-provider success is not claimed. Chrome and Edge
could not start with DevTools enabled, leaving the fresh browser walkthrough
outstanding. The canonical whole-client check and sealed build are blocked by
E1032 in the separate untracked `client/adapter.cl.jac` draft; tracked client
sources pass. Three untracked client drafts remain outside this work.
See [live integration verification](Live_Grid_Integration.md),
[recovery integration](Recovery_Integration.md), and
[design review](Design_Review.md) for the supporting implementation notes.
The [WSL setup requirement](WSL_Setup.md) is the supported environment for
reproducing the pinned Jac checks. PR creation remains with the user.
