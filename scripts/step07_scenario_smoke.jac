"""Reproducible three-scenario handoff with labeled fixed AI failures."""

import from agents.events { get_agent_events }
import from agents.monitor { MonitorFacts }
import from agents.orchestration { _run_triage_with_providers }
import from grid.fixture {
    FAULT_SOURCE_A, FAULT_LINE_A_H, FAULT_INSUFFICIENT_BACKUP
}
import from grid.simulation { reset_simulation }
import from shared.contracts { RecoveryPlan }


def fixed_provider_failure(_facts: MonitorFacts, _feedback: str) -> RecoveryPlan {
    raise ValueError("Labeled fixed AI failure for deterministic scenario smoke");
}


with entry:__main__ {
    for fault_id in [FAULT_SOURCE_A, FAULT_LINE_A_H, FAULT_INSUFFICIENT_BACKUP] {
        reset_simulation();
        result = _run_triage_with_providers(
            fault_id, fixed_provider_failure, fixed_provider_failure
        );
        recovery = result.recovery_result;
        if recovery is None { raise ValueError("Recovery result missing"); }
        events = get_agent_events(result.run_id);
        print(
            f"fault={fault_id}; status={result.status}; mode={recovery.execution_mode}; " +
            f"outcome={recovery.outcome}; proposals={recovery.proposal_count}; " +
            f"revision={result.before_state.revision}->{result.after_state.revision}; " +
            f"served_kw={recovery.before_metrics.served_kw}->{recovery.after_metrics.served_kw}; " +
            f"unmet_kw={recovery.before_metrics.unmet_kw}->{recovery.after_metrics.unmet_kw}; " +
            f"critical_pct={recovery.before_metrics.critical_preserved_pct}->{recovery.after_metrics.critical_preserved_pct}; " +
            f"events={len(events)}"
        );
    }
}
