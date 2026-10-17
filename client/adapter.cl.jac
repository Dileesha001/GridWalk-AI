"""Canonical facade for live operations; transport and decoding remain centralized."""
sv import from ..shared.contracts { GraphState, AgentEvent }
sv import from ..agents.orchestration { TriageResult }
import from .grid_client { read_live_grid, inject_live_fault, reset_live_grid }
import from .recovery_client { read_agent_events, run_live_recovery }

async def:pub read_grid() -> GraphState { return await read_live_grid(); }
async def:pub read_events(run_id: str = "") -> list[AgentEvent] { return await read_agent_events(run_id); }
async def:pub fault_grid(fault_id: str) -> GraphState { return await inject_live_fault(fault_id); }
async def:pub reset_grid() -> GraphState { return await reset_live_grid(); }
async def:pub recover_grid(fault_id: str, generation_id: str, expected_revision: int) -> TriageResult {
    return await run_live_recovery(fault_id, generation_id, expected_revision);
}
