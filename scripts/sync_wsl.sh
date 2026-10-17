#!/usr/bin/env bash
# Copy editable Windows sources into a Linux-only build directory without caches.
set -euo pipefail
source_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
destination="${1:-$HOME/GridWalk-AI}"
mkdir -p -- "$destination"
destination="$(cd -- "$destination" && pwd -P)"
if [[ "$destination" == / || "$destination" == "$source_root" || "$destination" == "$source_root/"* || -e "$destination/.git" ]]; then
    echo "Choose a separate Linux build directory without a Git checkout." >&2
    exit 1
fi
if [[ ! -f "$destination/jac.toml" ]] && [[ -n "$(find "$destination" -mindepth 1 -maxdepth 1 -print -quit)" ]]; then
    echo "The destination must be empty or an existing GridWalk build copy." >&2
    exit 1
fi
if [[ -f "$destination/jac.toml" ]] && ! grep -q 'name = "gridwalk-ai"' "$destination/jac.toml"; then
    echo "The destination contains another project." >&2
    exit 1
fi

# No deletion: preserve Linux dependencies and generated state between syncs.
# Unfinished local drafts are excluded from this verified milestone.
tar -C "$source_root" \
    --exclude=./.git --exclude=./.jac --exclude=./.venv \
    --exclude=./.uv-cache --exclude=./.uv-python --exclude=./node_modules \
    --exclude=./dist --exclude=./.env --exclude='./.env.*' \
    --exclude='./__pycache__' --exclude='*.pyc' \
    --exclude=./client/Activity.cl.jac --exclude=./client/Metrics.cl.jac \
    --exclude=./client/adapter.cl.jac -cf - . | tar -C "$destination" -xf -
printf 'Synced source into %s; Windows environments and caches were excluded.\n' "$destination"
