# Local development with WSL

GridWalk AI uses the [native Jac 0.34.23 release](https://github.com/jaseci-labs/jac/releases/tag/v0.34.23) on Ubuntu under WSL 2. Keep the running project on the Linux filesystem: the simulator stores its graph in SQLite, which can fail when served from a Windows-mounted directory.

## Prepare a Linux working copy

If the repository is already checked out under your WSL home directory, work from that checkout. If you edit a Windows checkout, run this command from its root in WSL to create a Linux build copy:

```bash
bash scripts/sync_wsl.sh "$HOME/GridWalk-AI"
cd "$HOME/GridWalk-AI"
```

The sync script copies source files without Git metadata, generated files, or local secrets. Edit the original checkout and sync again after source changes. It preserves files already in the Linux copy, so remove an obsolete copied file there if you need an exact mirror.

## Install and run

From the Linux checkout or build copy:

```bash
bash scripts/install_jac_wsl.sh
export PATH="$HOME/.local/bin:$PATH"
jac --version                 # 0.34.23
jac install
jac start main.jac --port 8011
```

Open `http://localhost:8011` in a Windows browser. Stop the server with Ctrl+C. Run only one server against a given local `.jac/data` directory at a time.

To use live providers, set `GOOGLE_API_KEY` and `GROQ_API_KEY` in a local `.env` beside `jac.toml`; [.env.example](../.env.example) lists the variables. The Windows-to-WSL sync intentionally excludes `.env`, so configure it in the Linux copy separately. Keep keys out of Git. Recovery can use a deterministic fallback when provider planning does not apply a plan and a feasible candidate remains.

## Verify a checkout

```bash
bash scripts/verify_wsl.sh
```

The script checks Jac source, runs the repository's runtime and scenario checks, and builds the web client and sealed app. It requires Jac 0.34.23 and does not call live model providers. The `Dockerfile` also installs the pinned native Jac release for container deployments.
