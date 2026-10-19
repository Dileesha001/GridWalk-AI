"""Exercise the real dashboard against a local product or fixed-proposal server.

Usage: verify_recovery_console.py http://127.0.0.1:8013 --fixture
The fixture option asserts real rejection/revision evidence. Product mode uses
the actual configured providers/fallback and never substitutes HTTP responses.
"""
import base64
import json
import os
import sys
import time
from pathlib import Path
from urllib.request import Request, urlopen

import jaclang
from jaclang.cli import browser_engine as browser

os.environ.setdefault("JACBROWSER_CHROME", "C:/Program Files/Google/Chrome/Application/chrome.exe")
base = sys.argv[1] if len(sys.argv) > 1 else "http://127.0.0.1:8013"
fixture = "--fixture" in sys.argv
session = "gridwalk-recovery-review"
output = Path(__file__).resolve().parents[1] / ".jac" / "console-verification"
output.mkdir(parents=True, exist_ok=True)


def values(value):
    if isinstance(value, dict):
        return {key: values(item) for key, item in value.items() if not key.startswith("_jac_")}
    if isinstance(value, list):
        return [values(item) for item in value]
    return value


def api(name, **body):
    request = Request(base + "/function/" + name, data=json.dumps(body).encode(),
                      headers={"Content-Type": "application/json"})
    with urlopen(request, timeout=130) as response:
        envelope = json.load(response)
    assert envelope["ok"], name
    return values(envelope["data"]["result"])


def evaluate(expression):
    connection = browser.connect(session)
    try:
        return browser._eval(connection, expression)
    finally:
        connection.close()


def wait(expression, timeout=130):
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        if evaluate(expression):
            return
        time.sleep(.08)
    raise AssertionError("Timed out waiting for " + expression)


def ready():
    wait("!!document.querySelector('#refresh-grid') && !document.querySelector('#refresh-grid').disabled")
    assert not evaluate("!!document.querySelector('#grid-error')"), evaluate("document.body.innerText")


def screenshot(name):
    connection = browser.connect(session)
    try:
        capture = connection.call("Page.captureScreenshot", {"format": "png", "captureBeyondViewport": True})
        (output / name).write_bytes(base64.b64decode(capture["data"]))
    finally:
        connection.close()


def click(selector):
    browser.cmd_click(session, selector)
    ready()


def enter():
    # The older Windows Jac helper omits the virtual key code, so Enter on a
    # button does not activate its native default action. Send a complete key.
    connection = browser.connect(session)
    try:
        event = {"key":"Enter", "code":"Enter", "windowsVirtualKeyCode":13, "nativeVirtualKeyCode":13}
        connection.call("Input.dispatchKeyEvent", {"type":"keyDown", "text":"\r", **event})
        connection.call("Input.dispatchKeyEvent", {"type":"keyUp", **event})
    finally:
        connection.close()


report = {"server": "fixed-proposal fixture" if fixture else "product", "scenarios": [], "performance": []}
try:
    api("reset_simulation")
    browser.cmd_open(session, base, "1440x1160")
    connection = browser.connect(session)
    try:
        connection.call("Page.addScriptToEvaluateOnNewDocument", {"source": """
          window.__shifts=0;window.__longTasks=[];
          new PerformanceObserver(list=>{for(const e of list.getEntries())if(!e.hadRecentInput)window.__shifts+=e.value}).observe({type:'layout-shift',buffered:true});
          new PerformanceObserver(list=>{for(const e of list.getEntries())window.__longTasks.push(e.duration)}).observe({type:'longtask',buffered:true});
        """})
    finally:
        connection.close()
    # Three unthrottled warm-cache local navigations; report observations, no FPS claim.
    for _ in range(3):
        browser.cmd_navigate(session, base)
        ready()
        wait("document.fonts.status === 'loaded' && [...document.fonts].filter(x=>x.status==='loaded').length === 4")
        report["performance"].append(evaluate("""(()=>{const n=performance.getEntriesByType('navigation')[0];return {
          dom_content_loaded_ms:n.domContentLoadedEventEnd,load_ms:n.loadEventEnd,
          first_contentful_paint_ms:performance.getEntriesByName('first-contentful-paint')[0]?.startTime,
          layout_shift:window.__shifts,long_tasks:window.__longTasks,transfer_bytes:performance.getEntriesByType('resource').reduce((n,r)=>n+r.transferSize,0)}})()"""))
    screenshot("recovery-baseline.png")
    for index, fault in enumerate(["FAULT-SOURCE-A", "FAULT-LINE-A-H", "FAULT-INSUFFICIENT-BACKUP"]):
        click("#reset-grid")
        browser.cmd_click(session, "#fault-scenario")
        browser.cmd_press(session, "Home")
        for _ in range(index):
            browser.cmd_press(session, "ArrowDown")
        enter()
        click("#inject-fault")
        before = api("get_grid_state")
        assert before["active_fault_ids"] == [fault]
        screenshot("recovery-" + str(index) + "-fault.png")
        # Delay the real response only: observe pending state and duplicate protection.
        evaluate("""window.__recoveryCalls=0;window.__savedFetch=window.fetch;
          window.fetch=function(url,options){const p=window.__savedFetch.call(this,url,options);
            if(String(url).includes('/function/run_triage')){window.__recoveryCalls++;return p.then(r=>new Promise(resolve=>setTimeout(()=>resolve(r),800)))}return p};
          document.querySelector('#run-recovery').focus();""")
        enter()
        wait("document.querySelector('#workspace').getAttribute('aria-busy') === 'true'", timeout=10)
        assert evaluate("document.querySelector('#reset-grid').disabled && document.querySelector('#preview-mode').disabled && document.querySelector('#inject-fault').disabled")
        evaluate("document.querySelector('#run-recovery').click()")
        assert "awaiting" in evaluate("document.querySelector('#activity').innerText").lower()
        ready()
        assert evaluate("window.__recoveryCalls") == 1
        evaluate("window.fetch=window.__savedFetch")
        wait("!!document.querySelector('#recovery-outcome')")
        events = api("get_agent_events")
        run = api("get_recovery_result", run_id=events[0]["run_id"])
        after = api("get_grid_state")
        assert after["metrics"] == run["after_metrics"]
        sequences = evaluate("[...document.querySelectorAll('#agent-events li')].map(e=>Number(e.dataset.sequence))")
        assert sequences == [event["sequence"] for event in events] == list(range(1, len(events) + 1))
        assert run["run_id"] in evaluate("document.querySelector('#run-identity').innerText")
        assert run["incident_summary"] == evaluate("document.querySelector('#incident-summary').innerText")
        expected_label = {"primary_ai":"Primary AI", "backup_ai":"Backup AI", "deterministic":"Deterministic fallback", "none":"No committed mode"}[run["execution_mode"]]
        assert evaluate("document.querySelector('#execution-mode').innerText") == expected_label
        if fixture and fault == "FAULT-LINE-A-H":
            assert any(event["outcome"] == "rejected" for event in events)
            assert any(event["kind"] == "revision" for event in events)
        if fixture and fault == "FAULT-INSUFFICIENT-BACKUP":
            assert run["outcome"] == "infeasible" and not run["applied_actions"]
            assert after["revision"] == before["revision"]
        else:
            assert run["outcome"] in ["recovered", "partial"] and run["applied_actions"]
            assert after["revision"] == before["revision"] + 1
        assert fault in after["active_fault_ids"]
        screenshot("recovery-" + str(index) + "-result.png")
        # Re-read on navigation must restore the same factual run; reset must clear it.
        browser.cmd_navigate(session, base)
        ready()
        assert run["run_id"] in evaluate("document.querySelector('#run-identity').innerText")
        report["scenarios"].append({"fault":fault,"outcome":run["outcome"],"mode":run["execution_mode"],
                                    "events":len(events),"served_kw":after["metrics"]["served_kw"]})
        print("PASS", fault, run["outcome"], run["execution_mode"], flush=True)

    # Recovery evidence remains within the viewport at each supported breakpoint.
    report["responsive"] = []
    for width, height in [(1440,1160),(1024,900),(768,1024),(375,812)]:
        connection = browser.connect(session)
        try:
            connection.call("Emulation.setDeviceMetricsOverride", {"width":width,"height":height,"deviceScaleFactor":1,"mobile":False})
            time.sleep(.2)
            dimensions = browser._eval(connection, "({width:innerWidth,page:document.documentElement.scrollWidth})")
            assert dimensions["width"] == width and dimensions["page"] <= width, dimensions
            capture = connection.call("Page.captureScreenshot", {"format":"png"})
            (output / ("recovery-result-" + str(width) + ".png")).write_bytes(base64.b64decode(capture["data"]))
        finally:
            connection.close()
        report["responsive"].append(dimensions)
    connection = browser.connect(session)
    try:
        tree = connection.call("Accessibility.getFullAXTree", {})["nodes"]
        names = {node.get("name", {}).get("value", "") for node in tree if not node.get("ignored")}
        assert {"Run recovery", "Reset", "Refresh live state", "Ordered agent evidence"} <= names
        connection.call("Emulation.setEmulatedMedia", {"features":[{"name":"prefers-reduced-motion","value":"reduce"}]})
    finally:
        connection.close()
    evaluate("document.querySelector('#agent-events').focus()")
    assert evaluate("document.activeElement.id") == "agent-events"
    browser.cmd_press(session, "ArrowDown")
    evaluate("document.querySelector('a[href=\"#workspace\"]').focus()")
    enter()
    assert evaluate("document.activeElement.id") == "workspace"
    click("#reset-grid")
    assert not evaluate("!!document.querySelector('#agent-events') || !!document.querySelector('#run-metrics')")
    assert api("get_agent_events") == []
    assert evaluate("document.getAnimations().length") == 0
    logs = browser.cmd_console(session, False)
    assert "[error]" not in logs.lower() and "[warning]" not in logs.lower(), logs
    report["keyboard_recovery_and_evidence"] = "passed"
    report["duplicate_recovery"] = "one request per scenario"
    report["reset_clears_evidence"] = True
    report["console_errors"] = 0
    report["performance_conditions"] = "Chrome headless, local WSL server, warm cache, no CPU/network throttling, three navigations"
    (output / ("recovery-fixture.json" if fixture else "recovery-product.json")).write_text(json.dumps(report, indent=2), encoding="utf-8")
    print(json.dumps(report, indent=2))
finally:
    browser.cmd_close(session)
    api("reset_simulation")
