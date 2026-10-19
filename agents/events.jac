"""Per-root recovery run records for ordered event and result polling."""

import from grid.simulation { get_grid_state }
import from shared.contracts { AgentEvent, RecoveryResult }
import from time { time_ns }


node AgentRunRecord {
    has run_id: str;
    has generation_id: str;
    has recorded_at_ns: int;
    has events: list[AgentEvent];
    has result: RecoveryResult;
}


def record_agent_run(
    run_id: str, generation_id: str,
    events: list[AgentEvent], result: RecoveryResult
) {
    for existing in [root -->[?:AgentRunRecord]] {
        if existing.run_id == run_id {
            raise ValueError("Duplicate recovery run ID");
        }
    }
    root ++> AgentRunRecord(
        run_id=run_id, generation_id=generation_id,
        recorded_at_ns=time_ns(),
        events=events.copy(), result=result
    );
}


def:pub get_agent_events(run_id: str = "") -> list[AgentEvent] {
    if run_id != "" {
        for recorded in [root -->[?:AgentRunRecord]] {
            if recorded.run_id == run_id { return recorded.events.copy(); }
        }
        return [];
    }
    generation_id = get_grid_state().generation_id;
    latest_at_ns = -1;
    latest_events: list[AgentEvent] = [];
    for recorded in [root -->[?:AgentRunRecord]] {
        if recorded.generation_id == generation_id and recorded.recorded_at_ns > latest_at_ns {
            latest_at_ns = recorded.recorded_at_ns;
            latest_events = recorded.events.copy();
        }
    }
    return latest_events;
}


def:pub get_recovery_result(run_id: str) -> RecoveryResult | None {
    for recorded in [root -->[?:AgentRunRecord]] {
        if recorded.run_id == run_id { return recorded.result; }
    }
    return None;
}
