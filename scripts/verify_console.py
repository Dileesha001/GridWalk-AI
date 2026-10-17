"""Verify the local console with Jac Chrome/CDP; supporting tooling, not app code."""
import base64
import json
import os
import sys
import time
from pathlib import Path
import jaclang
from jaclang.cli import browser_engine as browser

os.environ.setdefault('JACBROWSER_CHROME', 'C:/Program Files/Google/Chrome/Application/chrome.exe')
session = 'gridwalk-console-review'
output = Path(__file__).resolve().parents[1] / '.jac' / 'console-verification'
output.mkdir(parents=True, exist_ok=True)
base_url = sys.argv[1] if len(sys.argv) > 1 else 'http://127.0.0.1:8001'

def evaluate(expression):
    cdp = browser.connect(session)
    try:
        return browser._eval(cdp, expression)
    finally:
        cdp.close()

try:
    browser.cmd_open(session, base_url, '1440x1160')
    browser.cmd_navigate(session, base_url)
    browser.cmd_wait(session, '#network-title')
    time.sleep(2)
    assets = evaluate("[...document.images].map(x=>({loaded:x.complete&&x.naturalWidth>0,w:x.getBoundingClientRect().width,h:x.getBoundingClientRect().height,x:x.getBoundingClientRect().x-x.parentElement.getBoundingClientRect().x,y:x.getBoundingClientRect().y-x.parentElement.getBoundingClientRect().y}))")
    assert len(assets) == 16 and all(x['loaded'] for x in assets), assets
    assert all(x['w'] == 740 and x['h'] == 344 and x['x'] == 0 and x['y'] == 0 for x in assets[:12]), assets
    assert all(x['w'] == 7 and x['h'] == 7 for x in assets[12:]), assets
    assert evaluate("[...document.fonts].filter(f=>f.status==='loaded').length") == 4
    assert evaluate("document.querySelectorAll('.topology-node').length") == 12
    assert evaluate("document.querySelector('[aria-label=\"Fixed snapshot metrics\"]').innerText.includes('205 kW')")
    assert evaluate("document.querySelectorAll('link[rel=stylesheet]').length") == 0
    results = []
    for width, height in [(1440,1160),(1024,900),(768,1024),(375,812)]:
        cdp = browser.connect(session)
        try:
            cdp.call('Emulation.setDeviceMetricsOverride', {'width':width,'height':height,'deviceScaleFactor':1,'mobile':False})
            time.sleep(.15)
            data = browser._eval(cdp, "({width:innerWidth,page:document.documentElement.scrollWidth,diagram:document.querySelector('.topology-scroll').scrollWidth,visible:document.querySelector('.topology-scroll').clientWidth})")
            assert data['width'] == width and data['page'] <= width, data
            assert data['diagram'] >= 740, data
            browser._eval(cdp, 'window.scrollTo(0,0)')
            capture=cdp.call('Page.captureScreenshot', {'format':'png'})
            (output/f'console-{width}.png').write_bytes(base64.b64decode(capture['data']))
            results.append(data)
        finally:
            cdp.close()
    # Clicking a bus must inspect that stable ID, not the last loop item.
    for identity in ['SRC-A','LOAD-DATA','LOAD-LIGHTS']:
        browser.cmd_click(session, f'button[aria-label^="Inspect {identity},"]')
        assert evaluate("document.querySelector('#component-inspection').open")
        assert evaluate("document.querySelector('#topology-component').value") == identity
        assert evaluate("document.activeElement.id") == 'topology-component'
    # Native keyboard navigation changes fixed examples without any backend call.
    browser.cmd_click(session, '#preview-tools summary')
    browser.cmd_click(session, '#topology-example')
    for expected, critical, served in [('source_fault','42.9%','100 kW'),('line_fault','42.9%','145 kW'),('rerouted','100%','180 kW')]:
        browser.cmd_press(session, 'ArrowDown')
        browser.cmd_press(session, 'Enter')
        assert evaluate("document.querySelector('#topology-example').value") == expected
        text = evaluate("document.querySelector('[aria-label=\"Fixed snapshot metrics\"]').innerText")
        assert critical in text and served in text, text
        assert 'Fault retained' in evaluate("document.querySelector('#snapshot-status').innerText")
    assert evaluate("getComputedStyle(document.querySelector('button[aria-label^=\"Inspect LOAD-HOSP,\"]')).backgroundColor") == 'rgb(237, 242, 255)'
    browser.cmd_click(session, '#topology-component')
    browser.cmd_press(session, 'Home')
    for _ in range(12):
        browser.cmd_press(session, 'ArrowDown')
    browser.cmd_press(session, 'Enter')
    assert evaluate("document.querySelector('#topology-component').value") == 'LINE-A-H'
    text=evaluate("document.querySelector('.topology-inspector').innerText")
    assert 'FAULTED' in text and 'Closed' in text and 'No' in text, text
    time.sleep(.2)
    assert evaluate("document.getAnimations().length") == 0
    cdp=browser.connect(session)
    try:
        cdp.call('Emulation.setEmulatedMedia', {'features':[{'name':'prefers-reduced-motion','value':'reduce'}]})
        browser._eval(cdp, "window.__motionCalls=0;window.__animate=Element.prototype.animate;Element.prototype.animate=function(...args){window.__motionCalls++;return window.__animate.apply(this,args)}")
        browser.cmd_click(session, '#topology-example')
        browser.cmd_press(session, 'Home')
        browser.cmd_press(session, 'Enter')
        assert browser._eval(cdp, "window.__motionCalls") == 0
        assert browser._eval(cdp, "document.getAnimations().length") == 0
    finally:
        cdp.close()
    # The skip link becomes visible on focus and moves to the workspace.
    evaluate("document.querySelector('a[href=\"#workspace\"]').focus()")
    assert evaluate("document.activeElement.innerText") == 'Skip to workspace'
    browser.cmd_press(session,'Enter')
    assert evaluate("document.activeElement.id") == 'workspace'
    logs=browser.cmd_console(session, False)
    assert '[error]' not in logs.lower() and '[warning]' not in logs.lower(), logs
    print(json.dumps({'assets':len(assets),'fonts':4,'responsive':results,'bus_clicks':'passed','native_keyboard_snapshots':'passed','physical_fault_inspection':'passed','reduced_motion':'passed','skip_link':'passed','console':'no errors or warnings'},indent=2))
finally:
    browser.cmd_close(session)
