"""Run client regressions through `jac run`, preserving sibling test modules."""

import json
from pathlib import Path
import subprocess
import sys

import jaclang  # Registers Jac's import machinery.
from jaclang.runtimelib.cl_test_runner import compile_cl_module
from jaclang.runtimelib.client.bun_installer import get_bun
from jaclang.compiler.passes.ecmascript.jac_runtime_js import stage_jac_prelude_package


def main():
    root = Path(__file__).resolve().parents[1]
    build = root / ".jac" / "foundation-tests"
    build.mkdir(parents=True, exist_ok=True)
    stage_jac_prelude_package(str(build))
    bun = get_bun()
    if not bun:
        raise SystemExit("Run jac install first to install the project-local Bun runtime.")

    suite = sys.argv[1] if len(sys.argv) > 1 else "foundation"
    suites = {
        "foundation": ("models", "preview", "decode"),
        "topology": ("models", "topology_examples", "topology_layout"),
        "live_grid": ("models", "decode", "topology_examples", "grid_decode", "network_geometry"),
        "recovery": ("models", "decode", "topology_examples", "grid_decode", "recovery_decode"),
    }
    if suite not in suites:
        raise SystemExit("Usage: check_foundation.py [foundation|topology|live_grid|recovery]")
    modules = suites[suite]
    for name in modules:
        source, _, _, _ = compile_cl_module(str(root / "client" / f"{name}.cl.jac"))
        (build / f"{name}.js").write_text(source, encoding="utf-8")

    source, tests, _, _ = compile_cl_module(str(root / "client" / f"{suite}_tests.cl.jac"))
    if not tests:
        raise SystemExit("No client tests were discovered; refusing an empty success.")
    entries = ",".join(f'[{json.dumps(t["description"])}, {t["name"]}]' for t in tests)
    runner = """
let failures = 0;
for (const [name, test] of TESTS) {
  try { await test(); console.log('PASS ' + name); }
  catch (error) { failures++; console.error('FAIL ' + name + ': ' + error.stack); }
}
console.log(TESTS.length + ' tests, ' + failures + ' failures');
process.exitCode = failures ? 1 : 0;
""".replace("TESTS", f"[{entries}]")
    harness = build / "harness.mjs"
    harness.write_text(source + "\n" + runner, encoding="utf-8")
    return subprocess.run([str(bun), str(harness)], cwd=root, check=False).returncode


if __name__ == "__main__":
    raise SystemExit(main())
