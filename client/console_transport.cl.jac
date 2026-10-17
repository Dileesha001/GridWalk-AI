"""Same-origin function transport shared by grid and recovery operations."""
import from .decode { object_value, flag }

def:pub function_result(raw: any) -> any {
    envelope = object_value(raw);
    if not flag(envelope, "ok") { raise ValueError("The server rejected the request. Refresh live state before retrying."); }
    payload = object_value(envelope["data"]);
    if "result" not in payload { raise ValueError("The server response is missing its result."); }
    return payload["result"];
}

async def:pub call_function(operation: str, body: dict[str, any], timeout_ms: int = 15000) -> any {
    browser: any = window;
    controller: any = new(browser.AbortController as type);
    timer = browser.setTimeout(lambda { controller.abort(); }, timeout_ms);
    try {
        response = await browser.fetch("/function/" + operation, {
            "method": "POST", "credentials": "same-origin", "cache": "no-store",
            "headers": {"Content-Type": "application/json"},
            "body": JSON.stringify(body), "signal": controller.signal
        });
        if not response.ok { raise ValueError("Server request failed (HTTP " + str(response.status) + "). Refresh live state before retrying."); }
        return function_result(await response.json());
    } except Exception as error {
        if controller.signal.aborted { raise ValueError("Request timed out. The server may still be processing; refresh live state before retrying."); }
        raise error;
    } finally { browser.clearTimeout(timer); }
}
