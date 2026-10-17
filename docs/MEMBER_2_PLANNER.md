# Member 2 Planner handoff

`agents/planner.jac` defines the `TriagePlanner` walker and two in-process entry points:

- `propose_plan(facts: MonitorFacts) -> RecoveryPlan` uses a previously observed Monitor snapshot.
- `propose_current_plan() -> RecoveryPlan` calls `inspect_grid()` first.

The typed `by llm()` call returns only `PlannerDraft` actions and an explanation. Jac copies the active fault ID, grid generation ID, and revision from `MonitorFacts.graph_state` into the shared `RecoveryPlan`. It derives the optional affected source ID from a single observed derated source. This prevents a model from supplying the snapshot identifiers used for stale-plan checks.

The Planner rejects healthy or ambiguous snapshots before a provider call. It does not mutate the graph, calculate allocation, or declare a proposal accepted. Action IDs and all candidate feasibility remain for Member 1's `validate_plan`. Empty actions are allowed when the model cannot justify a supported action; the later orchestration must classify that outcome from validator and grid facts.

The primary model setting is in `jac.toml` under `[plugins.byllm.model]`. `gemini/gemini-3.8-flash` is the current candidate, subject to a real typed-output check with this account. `propose_plan` loads the ignored root `.env` file without overriding existing environment variables. Use `.env.example` as the variable-name template and keep the real key out of git. byLLM accepts `GOOGLE_API_KEY` or `GEMINI_API_KEY`; this project documents `GOOGLE_API_KEY`.

The Jac compiler accepts the Planner. A live Gemini proposal, model access, response quality, and any metrics or recovery result are **not yet verified**. The next check is a single live proposal against an injected fixture fault once the local key is available. Member 1's validator/application are separate from this branch; no proposal should be represented as an applied recovery.
