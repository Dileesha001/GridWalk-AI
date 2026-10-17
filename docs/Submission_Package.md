# GridWalk AI demo and submission package

Repository: https://github.com/Dileesha001/GridWalk-AI

Implementation branch: `dashboard`. The recorded local walkthrough uses the
product's deterministic fallback and must be described that way. Hosting is
optional; no hosted URL is claimed.

## Written project description

GridWalk AI is a fictional microgrid recovery decision-support simulator. A user
injects a source-capacity reduction, physical line fault, or backup shortage.
Jac walkers inspect the authoritative graph, a typed LLM Planner proposes
switching/shedding actions, deterministic Jac code validates the candidate, and
the simulator applies only an approved plan. An Auditor explains the actual
committed result. The Jac dashboard displays topology, critical service,
capacity versus dispatch, unmet versus deliberately shed demand, ordered agent
evidence, and before/after measurements.

Jac implements the graph nodes/edges, Monitor/Planner/Auditor walkers, typed
`by llm()` calls and `sem` descriptions, validation, bounded deterministic
fallback, server endpoints, and client components. Supporting Python and shell
files verify the app and build demo artifacts. The server stamps proposal
generation/revision, rejects stale requests, and records each run with ordered
events. AI has no direct authoritative mutation tool.

In the verified local fallback runs, all critical demand was preserved. Source
and line scenarios served 180 of 205 kW; backup shortage served 155 kW. Remaining
unmet demand and the physical fault stay visible. The simulation uses simplified
connectivity and lossless kW constraints; it does not model AC/DC power flow,
transient stability, or control real equipment. Live AI generation is awaiting
valid credentials, and optional hosting has not been verified.

## Local demo

Follow [WSL setup](WSL_Setup.md), then run:

```bash
jac --version  # 0.34.13
jac install
bash scripts/verify_wsl.sh
jac start main.jac --port 8011
```

Open `http://localhost:8011`. Reset to a healthy 205 kW baseline. Choose Line
failure, inject it, and inspect the physical fault and unmet critical demand.
Run recovery, then inspect the execution-mode label, correlated events,
validation/application evidence, committed actions, and before/after table.
Reset before showing source capacity or backup shortage. Fixed previews do not
run the simulator or providers.

Suggested narration: explain the problem and Jac graph; show the proposal /
deterministic-validation boundary; run a real scenario; state the actual
execution mode; inspect measured service and remaining demand; explain the
simplified model. Show a rejection only when it actually occurs or identify it
as the fixed-proposal verification fixture.

## Generated video

The local 48-second silent annotated walkthrough is at
`.jac/demo/GridWalk-demo.mp4`. It shows six actual captured product states;
it is a state sequence, not a continuous screen recording. Its captions identify
the observed fallback modes. The full encoded video was decoded successfully.
Generated media stays outside Git.

To reproduce, run the product browser verification first, then:

```powershell
.venv/Scripts/python.exe -m pip install Pillow imageio-ffmpeg
.venv/Scripts/python.exe scripts/make_demo.py
```

Review it for readability and choose whether to add team narration before
uploading. The tool dependencies are for local demo generation only.

## Submission handoff

| Item | State / action |
|---|---|
| Repository and branch | Ready at the link above; verify the judges' access |
| Written Jac/Jaseci explanation | Ready above |
| Local working run and build | Verified; see [evidence](Verification_2026-10-17.md) |
| Local walkthrough video | Generated, silent, fallback labeled; upload using the team's chosen service |
| Public video URL | Team must upload and verify judge access |
| Live AI credential | Replace locally and verify actual typed inference |
| Optional hosting | Not deployed; local execution is the verified delivery path |
| At-least-80% Jac rule | Organizer measurement interpretation remains a team check; no unsupported percentage claim |
| Member registration/check-in and Jac repository star | Team account actions remain unverified |
| Organizer form and receipt | Team must use the actual organizer link and confirm receipt |

Do not mark an upload or form receipt complete until the real destination and
access have been checked. The original brief's deadline and eligibility rules
remain in [the member guide](GridWalk_Member_3_UI_Integration_and_Deployment.md).
