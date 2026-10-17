# Design review and implementation audit

Reference: [GridWalk recovery console in Figma](https://www.figma.com/design/MBDQDKSfBy0ybXnNvlkMKE/GridWalk-AI-%C2%B7-Recovery-Console?node-id=0-1).

## Current access

Figma integration access is working. The healthy screen (`6:15`) was inspected
through design context and its 1440 × 1160 reference screenshot. The Figma
design-to-code and UI/UX Pro Max skills guide this milestone. The implemented
scope is the shared console and healthy baseline; the remaining Figma workflow
screens still need their own implementation and comparison.

## Review from Step 1

| Step | Review result | Next action |
|---|---|---|
| 1: Requirements | Server authority, deterministic approval, honest preview labels, and fault visibility remain required | Preserve these through live integration |
| 2: Environment | Jac 0.16.7 and the existing development setup are available | Keep the verified Jac build path |
| 3: Foundation | Original preview decoder uses draft fields; Jac function envelope handling had a concrete defect | Envelope fix added; adapt draft fields to canonical contracts before live integration |
| 4: Shell | Healthy console rebuilt using Jac style dictionaries, Fira fonts, teal sidebar, metric cards, activity waiting states, and supply/incident panels | Integrate live operations in Step 6 |
| 5: Topology | Canonical fixed snapshots, original Figma baseline SVG assets, clickable buses, native keyboard inspection, and separate physical fault/switch state | Adapt the remaining workflow screens as integration proceeds |

## Fix identified independently of visual design

Jac function responses carry the return value in `data.result`, alongside
`data.reports`. The legacy decoder previously returned the whole `data` object.
It now returns `data.result`, accepts legitimate falsy results, and rejects missing
results. New Jac regression tests cover these cases. The decoder remains marked
as a draft presentation decoder; fixing the envelope does not make its old graph
field names compatible with the shared server schema.

## Language and styling direction

Use Jac components and Jac style dictionaries for new product implementation.
Avoid new standalone CSS, JavaScript, or TypeScript source files. Browser style
properties still govern web presentation even when authored inside Jac. Any
necessary supporting-language exception must have a concrete reason. The active
dashboard no longer imports the old CSS file. Fonts load through the browser
FontFace API called from Jac. All new application implementation is Jac;
`scripts/verify_console.py` is supporting browser verification tooling.

Keep the UI/UX checks for keyboard access, visible focus, contrast, readable
labels, responsive layouts, and reduced motion during the migration. Do not remove
working accessibility behavior merely to reduce CSS file count.

## Verification and fixes

- Fourteen targeted Jac static checks pass; the production client bundle builds.
- Nine foundation and six topology runtime tests pass.
- Chrome verification covers 1440, 1024, 768, and 375 pixel widths without page
  overflow. The fixed-size diagram scrolls within its own panel when necessary.
- All sixteen Figma SVGs load locally at their original dimensions: twelve
  740 × 344 line layers aligned at the diagram origin and four 7 × 7 legend dots.
  All four local font faces load. No temporary Figma URLs are used at runtime.
- Bus clicks select the correct stable ID and move keyboard focus to inspection.
  Native keyboard selection updates all four fixed examples and their metrics.
  Rerouting retains the physical fault and distinguishes blue rerouted service
  from amber shedding. Physical line inspection still reports fault, closed
  switch, nonconducting state, and signed transfer independently.
- The skip link works. Reduced motion prevents the short opacity transition.
  Transitions finish without a continuing animation loop; the browser console
  has no application errors or warnings. This is not a measured FPS guarantee.
- Preview objects are memoized by selected example. Layout listeners update
  only at breakpoints, clean up on unmount, and do not set state each animation
  frame. Motion uses opacity, cancels on replacement/unmount, and observes
  changes to the reduced-motion preference.
- Browser checks found and fixed missing asset imports. The normal Jac server
  also required imported build font URLs to use its `/static` mount; development
  URLs stay unchanged. Stop the dev server before building on Windows to avoid
  an esbuild executable file lock.

Run the browser checks against a running local server:

```powershell
.venv/Scripts/python.exe scripts/verify_console.py
```

This uses Chrome through the installed Jac browser engine. On Windows the default
Chrome path is used; set `JACBROWSER_CHROME` if Chrome is installed elsewhere.
An optional first argument selects another local server URL. Screenshots are
written under ignored `.jac/console-verification/`.

## Intentional milestone differences from the reference

Live Reset and Inject buttons remain disabled and explain why. Activity cards
describe waiting roles rather than fabricated events. Additional disclosure
sections expose fixed snapshots and detailed inspection below the main console.
The sidebar offers fixed source/line examples; backup shortage is unavailable
until integration. Responsive layouts stack panels and keep the original SVG
dimensions. The original renderer remains in the repository; its unknown-bus
layout tests do not establish unknown-bus support in the new fixed-fixture view.

No reusable Button implementation or Simple Design System package matching the
Figma Code Connect mapping exists in the repository or installed UI libraries.
Native Jac-rendered buttons provide the current controls.

## Scope still outstanding

Live controls and server-derived metrics, actual agent events, recovery results,
remaining Figma workflow states, request concurrency, end-to-end recovery, and
deployment remain later work. The original draft adapter and draft activity/metric
components are not imported by the dashboard. This milestone belongs on the
`dashboard` branch; PR creation remains with the user.
