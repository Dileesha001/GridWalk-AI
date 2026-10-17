# Jac 0.34.13 migration

The project now targets the native Jac 0.34.13 Linux binary in WSL 2. The exact toolchain version is recorded in `jac.toml`; the repository README contains the current setup commands. Install Jac through its native binary installer, then use `jac install` to resolve this project's optional dependencies. Do not install `jaclang` or `jac-client` with pip.

The port changed the project kind to `web-app`, moved client and byLLM settings out of the old plugin namespace, removed the separate byLLM dependency, updated the byLLM exception import, and changed lambdas to 0.34.13 syntax. The existing graph, recovery contracts, and UI behavior were otherwise left as they were.

Checks completed in Ubuntu 24.04 under WSL 2 with `jac --version` reporting 0.34.13:

- `jac install` completed, including optional Python packages and npm dependencies.
- `jac check . -n` passed all 29 Jac files.
- `jac build --client web` built the client bundle.

These checks establish installation, compilation, and client bundling. The prior live Gemini proposal, browser inspection, and runtime milestone checks were performed under Jac 0.16.7. Repeat the relevant runtime checks under 0.34.13 as the team connects the remaining features. Historical milestone documents retain their original environment and results.
