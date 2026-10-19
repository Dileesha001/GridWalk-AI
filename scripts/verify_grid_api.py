"""Exercise the public grid endpoints on a local test server; no AI calls."""
import json
import sys
from urllib.request import Request, urlopen
from urllib.error import HTTPError

base_url = sys.argv[1] if len(sys.argv) > 1 else 'http://127.0.0.1:8012'

def call(name, body=None, reject=False):
    request = Request(base_url + '/function/' + name,
                      data=json.dumps(body or {}).encode(),
                      headers={'Content-Type': 'application/json'}, method='POST')
    status = 200
    try:
        with urlopen(request, timeout=25) as response:
            payload = json.load(response)
    except HTTPError as error:
        status = error.code
        payload = json.loads(error.read())
    if reject:
        assert status >= 400 or payload.get('ok') is False, payload
        return
    assert status == 200 and payload.get('ok') is True, (status, payload)
    return payload['data']['result']

results = []
connected = False
try:
    baseline = call('reset_simulation')
    connected = True
    assert baseline['revision'] == 0 and baseline['generation_id']
    assert baseline['metrics']['served_kw'] == 205
    assert call('get_grid_state')['generation_id'] == baseline['generation_id']
    for fault, served, capacity in [('FAULT-SOURCE-A',100,205), ('FAULT-LINE-A-H',145,275), ('FAULT-INSUFFICIENT-BACKUP',100,175)]:
        before = call('reset_simulation')
        changed = call('inject_fault', {'fault_id': fault})
        confirmed = call('get_grid_state')
        assert changed['generation_id'] == before['generation_id'] == confirmed['generation_id']
        assert confirmed['revision'] == 1
        assert confirmed['active_fault_ids'] == [fault]
        assert confirmed['metrics']['served_kw'] == served
        assert confirmed['metrics']['available_capacity_kw'] == capacity
        assert confirmed['metrics']['shed_kw'] == 0
        assert call('inject_fault', {'fault_id': fault})['revision'] == 1
        other = 'FAULT-LINE-A-H' if fault != 'FAULT-LINE-A-H' else 'FAULT-SOURCE-A'
        call('inject_fault', {'fault_id': other}, reject=True)
        assert call('get_grid_state')['revision'] == 1
        if fault == 'FAULT-LINE-A-H':
            line = next(x for x in confirmed['lines'] if x['line_id'] == 'LINE-A-H')
            assert line['physically_faulted'] and line['switch_closed'] and not line['conducting'] and line['transfer_kw'] == 0
        reset = call('reset_simulation')
        assert reset['generation_id'] != confirmed['generation_id']
        assert reset['revision'] == 0 and reset['active_fault_ids'] == []
        assert call('get_grid_state')['generation_id'] == reset['generation_id']
        results.append({'fault':fault,'served_kw':served,'available_capacity_kw':capacity,'reset':'passed'})
    before = call('get_grid_state')
    call('inject_fault', {'fault_id':'NOT-A-SCENARIO'}, reject=True)
    after = call('get_grid_state')
    assert before['generation_id'] == after['generation_id'] and before['revision'] == after['revision']
    print(json.dumps({'live_api':results,'invalid_and_conflicting_faults':'rejected without mutation','AI_calls':0},indent=2))
finally:
    if connected:
        call('reset_simulation')
