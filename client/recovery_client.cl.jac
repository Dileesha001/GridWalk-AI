sv import from ..shared.contracts { AgentEvent, RecoveryResult }
sv import from ..agents.orchestration { TriageResult }
import from .console_transport { call_function }
import from .recovery_decode { decode_triage, decode_events, decode_recovery }

async def:pub run_live_recovery(fault_id: str) -> TriageResult {
    return decode_triage(await call_function("run_triage", {"fault_id": fault_id}, 120000), fault_id);
}

async def:pub read_agent_events(run_id: str = "") -> list[AgentEvent] {
    return decode_events(await call_function("get_agent_events", {"run_id": run_id}), run_id);
}

async def:pub read_recovery_result(run_id: str) -> RecoveryResult | None {
    raw = await call_function("get_recovery_result", {"run_id": run_id});
    return decode_recovery(raw, run_id) if raw is not None else None;
}
