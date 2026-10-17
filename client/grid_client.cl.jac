"""Single live-grid transport boundary; no recovery or unvalidated apply operation."""
sv import from ..shared.contracts { GraphState }
import from .grid_decode { decode_grid_response }

async def request(operation: str, body: dict[str, any]) -> GraphState {
    browser: any = window;
    controller: any = new(browser.AbortController as type);
    timer = browser.setTimeout(lambda { controller.abort(); }, 15000);
    try {
        response = await browser.fetch("/function/" + operation, {
            "method": "POST", "credentials": "same-origin", "cache": "no-store",
            "headers": {"Content-Type": "application/json"},
            "body": JSON.stringify(body), "signal": controller.signal
        });
        if not response.ok { raise ValueError("Server request failed (HTTP " + str(response.status) + "). Refresh live state before retrying."); }
        return decode_grid_response(await response.json());
    } except Exception as error {
        if controller.signal.aborted { raise ValueError("Request timed out. The server may have changed; refresh live state before retrying."); }
        raise error;
    } finally { browser.clearTimeout(timer); }
}

async def:pub read_live_grid() -> GraphState { return await request("get_grid_state", {}); }
async def:pub inject_live_fault(fault_id: str) -> GraphState { return await request("inject_fault", {"fault_id": fault_id}); }
async def:pub reset_live_grid() -> GraphState { return await request("reset_simulation", {}); }
