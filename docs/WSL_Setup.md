# Jac 0.34.13 on WSL

This is the required build environment. The earlier Windows Jac 0.16.7 checks
are historical evidence and do not replace verification with this version.

## Environment installed and migration

- Ubuntu 26.04.1 LTS on WSL 2, x86_64.
- Native `jac 0.34.13 (Linux x86_64)` installed at
  `/opt/gridwalk/jac-0.34.13/jac`, linked from `/usr/local/bin/jac`.
- Release binary SHA-256:
  `cb59ebef48a238762e024a05d192d0743312c9f7818974c8eaeb326acbc4848e`.
- Windows editable sources: `E:\GridWalk-AI` (`/mnt/e/GridWalk-AI` in WSL).
- Linux build copy on this machine: `/root/GridWalk-AI`.
- Linux dependencies and generated output stay in that copy's `.jac/` and
  `dist/`. The existing Windows `.venv/` and `.jac/` are not reused or deleted.

The project now uses `kind = "web-app"`, `jac-version = "==0.34.13"`, and
`[client]` / `[client.app_meta_data]` configuration. Typed lambda parameters are
parenthesized; expression lambdas use braces. The only simulation source change
is the mechanical lambda syntax update in the allocation load-order sort;
priority and stable-ID ordering are unchanged. The removed `global` directive
now follows Jac's nearest-enclosing-binding behavior.

Official references: [0.34.13 release](https://github.com/jaseci-labs/jac/releases/tag/v0.34.13)
and [versioned breaking changes](https://github.com/jaseci-labs/jac/blob/v0.34.13/docs/docs/community/breaking-changes.md).
The native binary bundles its runtime; do not install this release with the old
`pip install jaclang` / `jac-client` instructions.

## Reproduce the setup

For a machine without an Ubuntu distribution, run in PowerShell:

```powershell
wsl.exe --install -d Ubuntu --no-launch
```

Open Ubuntu's Bash from PowerShell:

```powershell
wsl.exe -d Ubuntu --exec bash
```

Then run inside WSL:

```bash
export PATH="$HOME/.local/bin:$PATH"
bash /mnt/e/GridWalk-AI/scripts/install_jac_wsl.sh
bash /mnt/e/GridWalk-AI/scripts/sync_wsl.sh "$HOME/GridWalk-AI"
cd "$HOME/GridWalk-AI"
jac --version
jac install
bash scripts/verify_wsl.sh
jac start main.jac --port 8011
```

Open `http://localhost:8011` in the Windows browser. Add `--dev` to the start
command when hot reload is needed.

The installer pins the release URL, verifies its published checksum, and accepts
only WSL x86_64/aarch64. It leaves an already-correct version alone. Shell helpers
are bootstrap/verification tooling; application implementation remains Jac.

## Editing and syncing

Edit the original repository. Before another WSL build, run the sync command
again, then work from the Linux copy. The script preserves Linux dependencies and
does not delete files. It excludes Windows caches, Git internals, local secrets,
generated artifacts, and the three unfinished local draft components/adapter.
It refuses to overwrite a Git checkout or a different named project. If a source
file is deleted later, remove only that known file from the Linux copy as well;
the sync deliberately does not mirror deletions.

No source edits should be made exclusively in the build copy. A clean Linux Git
checkout can instead be built directly without this Windows-to-Linux sync step.

## Verification commands

Verified with the installed native 0.34.13 compiler:

- 22 client/entry static checks pass.
- Nine foundation and six topology runtime tests pass.
- All eleven existing fixture/fault/allocation tests pass.
- Web client build succeeds.
- The normal whole-program build gate succeeds and seals all thirteen server
  modules into `dist/gridwalk-ai.jab` (2,326,842 bytes).
- A copy of this WSL-built artifact is available locally at
  `E:\GridWalk-AI\.jac\wsl-artifacts\gridwalk-ai.jab`.
- The sealed artifact serves successfully from WSL on port 8011. Chrome checks
  pass at 1440, 1024, 768, and 375 pixel widths, with sixteen loaded SVGs, four
  loaded font faces, correct bus selection, keyboard snapshot changes, retained
  physical fault inspection, reduced motion, and the skip link. The browser
  console has no application errors or warnings.

The compiler reports an optimization fallback for `grid/metrics.jac`: it runs
that module in the server codespace instead of lowering it to native machine
code. This is not a failed check; the simulation tests pass. No allocator or
metric behavior was changed to suppress that compiler note.

`bash scripts/verify_wsl.sh` refuses a non-WSL environment or a different Jac
version, then runs:

```bash
jac check main.jac client -n
jac run scripts/check_foundation.py foundation
jac run scripts/check_foundation.py topology
jac test tests/fixture_checks.jac tests/fault_checks.jac tests/allocation_checks.jac
jac build --client web main.jac
jac build main.jac
```

The native Jac runtime runs the Python test helper and supplies its managed Bun.
Explicit simulation filenames are necessary: directory discovery does not collect
the existing `*_checks.jac` names. A run collecting zero tests is not a success.
`-n` hides warnings; it does not skip errors or type checking. Do not use
`--no_typecheck` to make a failing build pass.

The web shell is emitted under `.jac/client/dist/`. The default `jac build`
also produces a sealed `.jab` application under `dist/`. This is a local build,
not a deployment or live recovery integration result.

On this Windows machine, the existing Chrome verification helper can inspect the
WSL-hosted app from PowerShell:

```powershell
.venv/Scripts/python.exe scripts/verify_console.py http://127.0.0.1:8011
```

That Python process only drives the Windows browser; the application is compiled
and served by Linux Jac 0.34.13. No Windows Jac build is involved.
