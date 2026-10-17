# Member 2 Planner handoff

`agents/planner.jac` defines the `TriagePlanner` walker and two in-process entry points:

- `propose_plan(facts: MonitorFacts) -> RecoveryPlan` uses a previously observed Monitor snapshot.
- `propose_current_plan() -> RecoveryPlan` calls `inspect_grid()` first.

The typed `by llm()` call returns only `PlannerDraft` action names as `RecoveryActionType` enum values, paired target IDs, and an explanation. Jac checks the pairs and converts them into shared `RecoveryAction` objects. This flat model-facing shape avoids a nested-object schema error in installed byLLM 0.6.19. The enum also prevents unsupported action names from reaching the shared plan. Jac copies the active fault ID, grid generation ID, and revision from `MonitorFacts.graph_state` into the shared `RecoveryPlan`. It derives the optional affected source ID from a single observed derated source. This prevents a model from supplying the snapshot identifiers used for stale-plan checks.

The Planner rejects healthy or ambiguous snapshots before a provider call. It does not mutate the graph, calculate allocation, or declare a proposal accepted. Action IDs and all candidate feasibility remain for Member 1's `validate_plan`. Empty actions are allowed when the model cannot justify a supported action; the later orchestration must classify that outcome from validator and grid facts.

The primary model setting is in `jac.toml` under `[plugins.byllm.model]`. `gemini/gemini-3.8-flash` passed one real typed-output check with this account. `propose_plan` loads the ignored root `.env` file without overriding existing environment variables. Use `.env.example` as the variable-name template and keep the real key out of git. byLLM accepts `GOOGLE_API_KEY` or `GEMINI_API_KEY`; this project documents `GOOGLE_API_KEY`.

Live smoke evidence: a temporary `jac run` script injected `FAULT-LINE-A-H` at revision 1 and received a typed `RecoveryPlan` proposing `CLOSE_SWITCH` on the real fixture ID `SW-TIE-B-H`. The script checked that fault, generation, revision, action type, and target IDs matched the observed state. The model's explanation said the alternate route might help and required deterministic validation. Earlier attempts exposed the nested-schema error, an invalid initial key, and an unsupported action name; the final enum-constrained attempt passed. This is a typed-output smoke check, not a reliability or feasibility claim. The temporary script was removed after the run; no key or provider response was committed.

`jac check . -n` passed on 28 Jac files after the Member 1 validator merge. Member 1's validator and later application remain separate from this branch. No proposal is represented as an applied recovery. Step 4 must submit the plan for deterministic validation and handle any rejection before application.
