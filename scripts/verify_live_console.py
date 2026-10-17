"""Check live UI/API consistency with Chrome; no recovery or provider calls."""
import base64
import json
import os
import sys
import time
from pathlib import Path
from urllib.request import Request, urlopen

import jaclang
from jaclang.cli import browser_engine as browser

os.environ.setdefault('JACBROWSER_CHROME', 'C:/Program Files/Google/Chrome/Application/chrome.exe')
session = 'gridwalk-live-review'
base_url = sys.argv[1] if len(sys.argv) > 1 else 'http://127.0.0.1:8012'
output = Path(__file__).resolve().parents[1] / '.jac' / 'console-verification'
output.mkdir(parents=True, exist_ok=True)


def api(name):
    with urlopen(Request(base_url + '/function/' + name, data=b'{}',
                         headers={'Content-Type': 'application/json'}), timeout=20) as response:
        return json.load(response)['data']['result']


def evaluate(expression):
    cdp = browser.connect(session)
    try:
        return browser._eval(cdp, expression)
    finally:
        cdp.close()


def wait(expression):
    deadline = time.monotonic() + 20
    while time.monotonic() < deadline:
        if evaluate(expression):
            return
        time.sleep(.05)
    raise AssertionError('Timed out: ' + expression)


ready = "!document.querySelector('#refresh-grid').disabled"
metrics = "document.querySelector('[aria-label=\"Live grid metrics\"]').innerText"

try:
    api('reset_simulation')
    browser.cmd_open(session, base_url, '1440x1160')
    browser.cmd_navigate(session, base_url)
    browser.cmd_wait(session, '#inject-fault')
    wait(ready)
    assert '205 kW' in evaluate(metrics)
    assert evaluate("document.querySelectorAll('.topology-wire').length") == 12
    assert evaluate("document.querySelectorAll('.topology-node').length") == 12
    assert evaluate("document.querySelector('#run-recovery').disabled")
    assert 'NOT STARTED' in evaluate("document.querySelector('#activity').innerText")

    # Delay mutation response to make busy/duplicate-click behavior observable.
    evaluate("""window.__requests=[];window.__originalFetch=window.fetch;
      window.fetch=function(url,options){
        window.__requests.push(String(url));
        if(window.__breakRead && String(url).includes('/function/get_grid_state'))
          return Promise.resolve(new Response(JSON.stringify({ok:true,data:{result:{}}}),{status:200}));
        const result=window.__originalFetch.call(this,url,options);
        return String(url).includes('/function/inject_fault')
          ? result.then(response=>new Promise(resolve=>setTimeout(()=>resolve(response),400))) : result;
      };document.querySelector('#inject-fault').click();document.querySelector('#inject-fault').click();""")
    assert evaluate("document.querySelector('#reset-grid').disabled && document.querySelector('#preview-mode').disabled")
    wait(ready)
    assert evaluate("window.__requests.filter(x=>x.endsWith('/inject_fault')).length") == 1
    assert '100 kW' in evaluate(metrics)
    assert evaluate("document.querySelector('#inject-fault').disabled")
    state = api('get_grid_state')
    assert state['active_fault_ids'] == ['FAULT-SOURCE-A']
    browser.cmd_navigate(session, base_url)
    browser.cmd_wait(session, '#refresh-grid')
    wait(ready)
    assert '100 kW' in evaluate(metrics)
    assert api('get_grid_state')['generation_id'] == state['generation_id']

    # Native keyboard selection and each remaining fault reach actual endpoints.
    for arrows, fault, served in [(1,'FAULT-LINE-A-H','145 kW'), (2,'FAULT-INSUFFICIENT-BACKUP','100 kW')]:
        browser.cmd_click(session, '#reset-grid')
        wait(ready)
        assert '205 kW' in evaluate(metrics)
        browser.cmd_click(session, '#fault-scenario')
        browser.cmd_press(session, 'Home')
        for _ in range(arrows):
            browser.cmd_press(session, 'ArrowDown')
        browser.cmd_press(session, 'Enter')
        browser.cmd_click(session, '#inject-fault')
        wait(ready)
        assert served in evaluate(metrics)
        assert api('get_grid_state')['active_fault_ids'] == [fault]
        if fault == 'FAULT-LINE-A-H':
            assert evaluate("document.querySelector('[data-line-id=\"LINE-A-H\"]').getAttribute('stroke-dasharray')")

    # A committed mutation followed by an invalid read must retain the last
    # confirmed snapshot, block further mutations, and offer an explicit refresh.
    browser.cmd_click(session, '#reset-grid')
    wait(ready)
    evaluate("""window.__originalFetch=window.fetch;window.__breakRead=true;
      window.fetch=function(url,options){
        if(window.__breakRead && String(url).includes('/function/get_grid_state'))
          return Promise.resolve(new Response(JSON.stringify({ok:true,data:{result:{}}}),{status:200}));
        return window.__originalFetch.call(this,url,options);
      };""")
    browser.cmd_click(session, '#inject-fault')
    wait(ready)
    assert evaluate("!!document.querySelector('#grid-error[role=alert]')")
    assert '205 kW' in evaluate(metrics)
    assert api('get_grid_state')['metrics']['served_kw'] == 100
    assert evaluate("document.querySelector('#inject-fault').disabled && document.querySelector('#reset-grid').disabled")
    evaluate('window.__breakRead=false')
    browser.cmd_click(session, '#refresh-grid')
    wait(ready)
    assert evaluate("!document.querySelector('#grid-error')")
    assert '100 kW' in evaluate(metrics)

    # Exercise AbortController timeout without a 15-second test delay.
    evaluate("""window.__timeoutFetch=window.fetch;window.__timeoutTimer=window.setTimeout;
      window.setTimeout=function(fn,delay,...args){return window.__timeoutTimer(fn,delay===15000?25:delay,...args)};
      window.fetch=function(url,options){
        if(String(url).includes('/function/get_grid_state'))
          return new Promise((resolve,reject)=>options.signal.addEventListener('abort',()=>reject(new DOMException('Aborted','AbortError'))));
        return window.__timeoutFetch.call(this,url,options);
      };""")
    browser.cmd_click(session, '#refresh-grid')
    wait(ready)
    assert 'Request timed out' in evaluate("document.querySelector('#grid-error').innerText")
    assert '100 kW' in evaluate(metrics)
    assert evaluate("document.querySelector('#reset-grid').disabled")
    evaluate('window.fetch=window.__timeoutFetch;window.setTimeout=window.__timeoutTimer')
    browser.cmd_click(session, '#refresh-grid')
    wait(ready)
    assert evaluate("!document.querySelector('#grid-error')")

    # Fixed previews must not send any simulator requests.
    evaluate('window.__previewCalls=0;window.__savedFetch=window.fetch;window.fetch=function(...args){window.__previewCalls++;return window.__savedFetch.apply(this,args)}')
    browser.cmd_click(session, '#preview-mode')
    browser.cmd_click(session, '#topology-example')
    browser.cmd_press(session, 'End')
    browser.cmd_press(session, 'Enter')
    assert evaluate('window.__previewCalls') == 0
    assert evaluate("document.querySelector('#inject-fault').disabled && document.querySelector('#reset-grid').disabled")
    browser.cmd_click(session, '#live-mode')
    wait(ready)
    browser.cmd_click(session, '#reset-grid')
    wait(ready)
    assert '205 kW' in evaluate(metrics)

    responsive = []
    for width, height in [(1440,1160),(1024,900),(768,1024),(375,812)]:
        cdp = browser.connect(session)
        try:
            cdp.call('Emulation.setDeviceMetricsOverride', {'width':width,'height':height,'deviceScaleFactor':1,'mobile':False})
            time.sleep(.15)
            dimensions = browser._eval(cdp, '({width:innerWidth,page:document.documentElement.scrollWidth})')
            assert dimensions['page'] <= width, dimensions
            capture = cdp.call('Page.captureScreenshot', {'format':'png'})
            (output / f'live-{width}.png').write_bytes(base64.b64decode(capture['data']))
            responsive.append(dimensions)
        finally:
            cdp.close()
    logs = browser.cmd_console(session, False)
    assert '[error]' not in logs.lower() and '[warning]' not in logs.lower(), logs
    print(json.dumps({'fault_scenarios':3,'reload_persistence':'passed','duplicate_submission':'blocked',
                      'uncertain_state_and_refresh':'passed','timeout_and_refresh':'passed','preview_requests':0,
                      'responsive':responsive,'console':'no errors or warnings','AI_calls':0},indent=2))
finally:
    browser.cmd_close(session)
    api('reset_simulation')
