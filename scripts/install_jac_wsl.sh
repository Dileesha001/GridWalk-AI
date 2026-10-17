#!/usr/bin/env bash
# Bootstrap the exact native Jac release; application source stays in Jac.
set -euo pipefail

if ! grep -qi microsoft /proc/sys/kernel/osrelease; then
    echo "Run this installer inside WSL." >&2
    exit 1
fi
if command -v jac >/dev/null && jac --version | grep -Eq '^jac 0\.34\.23[[:space:]]'; then
    jac --version
    exit 0
fi

case "$(uname -m)" in
    x86_64) architecture=x86_64; checksum=bb93ea1920b776592af2e38f6cd0cb1db1f71c7afdadf7ba841210b645212ce6 ;;
    aarch64) architecture=aarch64; checksum=0e4ada659c89b8be572203109203c84e0b799f5dfcf409be5f4b404da070cfbf ;;
    *) echo "Unsupported WSL architecture." >&2; exit 1 ;;
esac

install_dir="${JAC_INSTALL_DIR:-$HOME/.local/bin}"
download_file="$(mktemp /tmp/gridwalk-jac-0.34.23.XXXXXX)"
trap 'rm -f -- "$download_file"' EXIT
curl --fail --location --show-error \
    "https://github.com/jaseci-labs/jac/releases/download/v0.34.23/jac-0.34.23-linux-$architecture" \
    --output "$download_file"
printf '%s  %s\n' "$checksum" "$download_file" | sha256sum --check --status
mkdir -p -- "$install_dir"
install -m 755 -- "$download_file" "$install_dir/jac"
"$install_dir/jac" --version
printf 'Add this directory to PATH: %s\n' "$install_dir"
