"""Single live-grid transport boundary; no recovery or unvalidated apply operation."""
sv import from ..shared.contracts { GraphState }
import from .grid_decode { decode_grid }
import from .console_transport { call_function }

async def request(operation: str, body: dict[str, any]) -> GraphState {
    return decode_grid(await call_function(operation, body));
}

async def:pub read_live_grid() -> GraphState { return await request("get_grid_state", {}); }
async def:pub inject_live_fault(fault_id: str) -> GraphState { return await request("inject_fault", {"fault_id": fault_id}); }
async def:pub reset_live_grid() -> GraphState { return await request("reset_simulation", {}); }
