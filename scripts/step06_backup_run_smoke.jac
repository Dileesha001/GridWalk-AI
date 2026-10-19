"""Manual end-to-end Groq run with a labeled fixed primary failure."""

import from agents.events { get_agent_events, get_recovery_result }
import from agents.monitor { MonitorFacts }
import from agents.orchestration { _run_triage_with_providers }
import from agents.planner { propose_backup_plan }
import from grid.fixture { FAULT_LINE_A_H }
import from grid.simulation { reset_simulation }
import from shared.contracts { AgentEventKind, RecoveryPlan }

def fixed_primary_failure(_facts: MonitorFacts, _feedback: str) -> RecoveryPlan {
    raise ValueError("Labeled fixed primary failure for backup smoke");
}

with entry:__main__ {
    reset_simulation();
    result = _run_triage_with_providers(
        FAULT_LINE_A_H, fixed_primary_failure, propose_backup_plan
    );
    events = get_agent_events(result.run_id);
    stored = get_recovery_result(result.run_id);
    fallback_events = [event for event in events if event.kind == AgentEventKind.FALLBACK];

    print(f"status={result.status}; proposals={result.proposal_count}");
    print(f"mode={result.recovery_result.execution_mode if result.recovery_result is not None else None}");
    print(f"outcome={result.recovery_result.outcome if result.recovery_result is not None else None}");
    print(f"served_kw={result.before_state.metrics.served_kw}->{result.after_state.metrics.served_kw}");
    print(f"critical_preserved_pct={result.after_state.metrics.critical_preserved_pct}");
    print(f"fallback_events={len(fallback_events)}; stored_result={stored is not None}");
    print(f"revisions={result.before_state.revision}->{result.after_state.revision}");
    print(f"rejections={result.rejection_reasons}");
}
