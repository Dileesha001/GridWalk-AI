#!/usr/bin/env bash
set -euo pipefail
if ! grep -qi microsoft /proc/sys/kernel/osrelease; then
    echo "Run these checks inside WSL." >&2
    exit 1
fi
if ! jac --version | grep -Eq '^jac 0\.34\.13[[:space:]]'; then
    echo "This project requires native Jac 0.34.13." >&2
    exit 1
fi
cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."
jac --version
jac check main.jac client -n
jac run scripts/check_foundation.py foundation
jac run scripts/check_foundation.py topology
jac run scripts/check_foundation.py live_grid
# These historical *_checks filenames are not found by directory discovery.
jac test tests/*_checks.jac
jac build --client web main.jac
jac build main.jac
