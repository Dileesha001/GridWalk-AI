"""Run Jac client tests with sibling modules preserved (Jac 0.16.7 workaround)."""

import json
from pathlib import Path
import subprocess
import sys

import jaclang  # Registers Jac's import machinery.
from jaclang.runtimelib.cl_test_runner import compile_cl_module


def main():
    root = Path(__file__).resolve().parents[1]
    build = root / ".jac" / "foundation-tests"
    build.mkdir(parents=True, exist_ok=True)
    bun = root / ".jac" / "bin" / ("bun.exe" if sys.platform == "win32" else "bun")
    if not bun.is_file():
        raise SystemExit("Run jac install first to install the project-local Bun runtime.")

    suite = sys.argv[1] if len(sys.argv) > 1 else "foundation"
    if suite not in ("foundation", "topology"):
        raise SystemExit("Usage: check_foundation.py [foundation|topology]")
    modules = ("models", "preview", "decode") if suite == "foundation" else ("models", "topology_examples", "topology_layout")
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
