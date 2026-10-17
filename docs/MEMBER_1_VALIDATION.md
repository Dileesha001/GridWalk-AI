# Member 1 plan validation handoff

`validate_plan(plan: RecoveryPlan) -> ValidationResult` is the public, non-mutating entry point. It uses the canonical types in `shared/contracts.jac`. The plan must name the current active fault and copy the current `GraphState.generation_id` and `revision`. A reset creates a different generation even when the same fault is reinjected at the same revision. A stale or mismatched plan is rejected before action preview.

`SHED_LOAD` takes a load bus ID and `CLOSE_SWITCH` takes a switch ID. Unsupported kinds, wrong or unknown target IDs, and duplicate actions receive specific reasons. Accepted results contain a copied `CandidateAllocationView` and `candidate_metrics` computed from that candidate. Rejected results contain no candidate or candidate metrics. The result reports the generation and revision checked. Validation never changes the grid, switches, physical faults, or revision.

The typed plan carries actions only; it does not carry a claimed numeric allocation. `validate_plan` therefore uses deterministic `preview_allocation`. The lower-level `validate_candidate` remains available to check a separately claimed complete allocation and to report its numeric violations. Task 5 will implement `apply_approved_plan` with a fresh validation and version check before committing any change.

`grid/validation.jac` provides `validate_candidate(grid, switch_overrides, shed_load_ids, claimed_allocation=None) -> CandidateValidation`. It is deterministic Jac code and does not mutate the graph. `CandidateValidation` contains `accepted`, specific `reasons`, the evaluated `allocation` when references are valid, and the `grid_revision` used for evaluation.

`switch_overrides` maps stable switch IDs to candidate closed/open states. `shed_load_ids` contains stable load IDs deliberately disconnected by the proposed recovery. If `claimed_allocation` is omitted, the validator uses Member 1's deterministic `preview_allocation`. If supplied, it checks the entire claimed source dispatch, served loads, signed line transfers, and bookkeeping lists. This permits an AI-proposed allocation to differ from the greedy fallback while still facing the same constraints.

The validator rejects unknown switch/load IDs, closing a switch on a physically faulted line, invalid or nonfinite numbers, partial service under the chosen whole-load policy, source or line overload, transfer on open/faulted lines, missing conducting supply paths, flow imbalance at any bus, total dispatch mismatch, deliberately shed Tier 1 demand, and a deliberately shed Tier 2 load while Tier 3 demand remains served. It also checks the candidate's graph revision and consistency of recorded shed/unserved IDs. Any remaining unserved Tier 1 demand makes the recovery candidate unacceptable; the caller can report infeasibility rather than claiming restoration.

The tolerance for numerical comparisons is 0.000001 kW. Physical faults remain authoritative regardless of switch choices. A rejected candidate leaves the graph unchanged. Task 5 must recheck the revision and validate again immediately before applying an approved result.

## Examples using the committed fixture

- After `FAULT-LINE-A-H`, closing `SW-TIE-B-H` is a valid preview: the candidate serves hospital and water demand via 60 kW on `TIE-B-H`; `LINE-A-H` remains faulted with zero transfer.
- Closing `SW-A-H` on the faulted `LINE-A-H` is rejected with a physical-fault reason.
- With `FAULT-LINE-A-H` and no alternate tie, the hospital and water loads remain unserved, so validation rejects the recovery candidate and identifies both Tier 1 loads.
- A claimed `SRC-B` dispatch of 120 kW is rejected against its 95 kW rating. A claimed 100 kW transfer on `TIE-B-H` is rejected against its 65 kW rating.

## Verification

Jac 0.16.7: `jac check .` passed for 22 files with warnings in Member 3 client files. `jac test tests/validation_checks.jac -v` passed 12 tests using injected Jac proposals, with no model/provider call. The next Member 1 task is approved application and committed-state metrics.
