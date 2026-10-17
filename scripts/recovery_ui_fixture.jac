"""Local API test entry only: fixed proposals through real validation/application.

Never use this entry for production or a live AI demonstration. No provider is
called; applied results are labeled deterministic. The product entry is main.jac.
"""
import from agents.monitor { MonitorFacts }
import from agents.orchestration { _run_triage_with_planner, _finalize_triage, TriageResult }
import from agents.events { get_agent_events, get_recovery_result }
import from grid.simulation { get_grid_state, inject_fault, reset_simulation }
import from shared.contracts { ExecutionMode, RecoveryPlan, RecoveryAction, RecoveryActionType }
import from time { perf_counter, sleep }
import from uuid { uuid4 }

def fixture_proposal(facts: MonitorFacts, feedback: str) -> RecoveryPlan {
    fault_id = facts.graph_state.active_fault_ids[0];
    actions: list[RecoveryAction] = [];
    if fault_id == "FAULT-LINE-A-H" {
        # Prove rejection/revision with an actual invalid switch proposal first.
        actions = [RecoveryAction(action_type=RecoveryActionType.CLOSE_SWITCH,
            target_id="SW-A-H" if feedback == "" else "SW-TIE-B-H")];
    } elif fault_id == "FAULT-SOURCE-A" {
        actions = [RecoveryAction(action_type=RecoveryActionType.CLOSE_SWITCH, target_id="SW-TIE-B-A"),
            RecoveryAction(action_type=RecoveryActionType.SHED_LOAD, target_id="LOAD-OFFICE")];
    } else {
        actions = [RecoveryAction(action_type=RecoveryActionType.CLOSE_SWITCH, target_id="SW-TIE-R-A")];
    }
    return RecoveryPlan(fault_id=fault_id, grid_generation_id=facts.graph_state.generation_id,
        grid_revision=facts.graph_state.revision, actions=actions,
        explanation="Fixed verification proposal, not AI output");
}
def:pub run_triage(fault_id: str) -> TriageResult {
    started = perf_counter();
    sleep(0.35);
    triage = _run_triage_with_planner(fault_id, fixture_proposal);
    return _finalize_triage(triage, str(uuid4()), started, ExecutionMode.DETERMINISTIC);
}
