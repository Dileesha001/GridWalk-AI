"""Manual live recovery smoke; accepts a fictional fault ID, defaulting to line failure."""

import from agents.orchestration { run_triage }
import from agents.events { get_agent_events }
import from grid.fixture { FAULT_LINE_A_H }
import from grid.simulation { reset_simulation }
import from sys { argv }

with entry:__main__ {
    reset_simulation();
    fault_id = argv[1] if len(argv) > 1 else FAULT_LINE_A_H;
    result = run_triage(fault_id);
    print(f"status={result.status}; proposals={result.proposal_count}");
    if result.recovery_result is not None {
        print(f"execution_mode={result.recovery_result.execution_mode}; outcome={result.recovery_result.outcome}");
        events = get_agent_events(result.run_id);
        print(f"run_id={result.run_id}; ordered_events={len(events)}; committed_actions={len(result.recovery_result.applied_actions)}");
    }
    print(f"revisions={result.before_state.revision}->{result.after_state.revision}");
    print(f"served_kw={result.before_state.metrics.served_kw}->{result.after_state.metrics.served_kw}");
    print(f"critical_preserved_pct={result.after_state.metrics.critical_preserved_pct}");
    if result.last_plan is not None {
        print(f"actions={[(action.action_type, action.target_id) for action in result.last_plan.actions]}");
    }
    if result.last_validation is not None {
        print(f"validator_accepted={result.last_validation.accepted}");
    }
    if len(result.rejection_reasons) > 0 {
        print(f"rejections={result.rejection_reasons}");
    }
    if result.failure_reason is not None {
        print(f"failure={result.failure_reason}");
    }
}
