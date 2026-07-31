# AGENTS.md

Guidance for AI agents working in this repository.

## Repository Overview

This repository produces a Docker image that runs [Hermes Agent](https://github.com/NousResearch/hermes-agent) backed by a private [llama.cpp](https://github.com/ggml-org/llama.cpp) server. It is designed for deployment on [Vast.ai](https://vast.ai) GPU instances.

The image extends `vastai/llama-cpp` (pinned to a specific base tag) and adds:
- A pinned Hermes Agent install under `/opt/hermes-agent`
- Supervisor-managed startup scripts for both services
- Runtime config materialisation from environment variables

## Repository Structure

```
.
├── Dockerfile                        # Image definition; two build args: LLAMA_CPP_BASE, HERMES_REF
├── ROOT/                             # Files copied verbatim into the image root (/)
│   ├── LICENSES.md                   # Upstream license texts shipped inside the image
│   ├── etc/
│   │   ├── hermes-agent/
│   │   │   └── config.seed.yaml      # Template config; placeholders replaced at container startup
│   │   ├── supervisor/conf.d/
│   │   │   └── hermes-agent.conf     # Supervisor service definition for hermes-agent
│   │   ├── vast_agents/
│   │   │   └── hermes-agent.md       # Vast.ai agent capability description
│   │   ├── vast_boot.d/
│   │   │   └── 05-llama-env.sh       # Boot hook: sets LLAMA_MODEL / PORTAL_CONFIG defaults
│   │   └── vast_capabilities.d/
│   │       └── 50-hermes-agent.yaml  # Vast.ai capability manifest
│   └── opt/
│       ├── instance-tools/tests/
│       │   └── hermes-agent.d/
│       │       └── 10-hermes-dashboard.sh  # Health-check test for the Hermes dashboard
│       └── supervisor-scripts/
│           ├── hermes-agent.sh       # Hermes service entrypoint (waits for llama, materialises config, starts dashboard)
│           └── llama.sh              # llama-server entrypoint
├── templates/
│   └── default/
│       ├── README.md                 # Template-specific notes
│       └── template.yml              # Vast.ai instance template definition (ports, env defaults, filters)
└── .github/
    └── workflows/
        └── push-hermes-to-ghcr.yml  # CI: builds and pushes ghcr.io/y0ucef/hermes-agent:latest on push to main
```

## Key Concepts

### Build Arguments

| Arg | Default | Purpose |
|-----|---------|---------|
| `LLAMA_CPP_BASE` | `vastai/llama-cpp:b9264-cuda-12.9` | Base image providing llama-server and Vast.ai tooling |
| `HERMES_REF` | `v2026.7.20` | Git tag of Hermes Agent to install |

### Services

Both services run under Supervisor. The llama.cpp supervisor config is inherited from the base image; the Hermes Agent config lives in `ROOT/etc/supervisor/conf.d/hermes-agent.conf`.

| Service | Port | Notes |
|---------|------|-------|
| llama-server | 127.0.0.1:18000 | Internal only; never exposed publicly |
| hermes dashboard | 9119 | Primary user-facing UI |
| Jupyter | 18080 | Inherited from base image |
| Instance Portal | 11111 | Inherited from base image |

### Config Materialisation

At startup, `hermes-agent.sh` writes `$HERMES_HOME/config.yaml` from the first source that matches:

1. `HERMES_CONFIG_URL` — fetched with `curl`
2. `HERMES_CONFIG_B64` — base64-decoded inline
3. `HERMES_CONFIG_INLINE` — written directly as YAML text
4. An existing file at `$HERMES_HOME/config.yaml` — left untouched
5. `ROOT/etc/hermes-agent/config.seed.yaml` — placeholders replaced from env vars

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `LLAMA_MODEL` | (from `HERMES_MODEL`) | HuggingFace GGUF repo for llama-server |
| `LLAMA_ARGS` | `--host 127.0.0.1 --port 18000` | Extra llama-server CLI args |
| `HERMES_DASHBOARD_ARGS` | `--host 127.0.0.1 --port 9119 --no-open` | Args passed to `hermes dashboard` |
| `HERMES_MODEL_BASE_URL` | `http://127.0.0.1:18000/v1` | OpenAI-compatible endpoint Hermes connects to |
| `HERMES_MODEL` | auto-detected | Model name written into the seed config |
| `HERMES_CONFIG_URL` | (none) | URL to download as `config.yaml` |
| `HERMES_CONFIG_B64` | (none) | Base64-encoded `config.yaml` |
| `HERMES_CONFIG_INLINE` | (none) | Literal `config.yaml` content |
| `HERMES_HOME` | `${WORKSPACE:-/workspace}/.hermes` | Hermes runtime directory |

## How to Build

```bash
git clone https://github.com/y0uCeF/vastai-hermes-llamacpp.git
cd vastai-hermes-llamacpp

docker buildx build \
    --build-arg LLAMA_CPP_BASE=vastai/llama-cpp:b9264-cuda-12.9 \
    --build-arg HERMES_REF=v2026.7.20 \
    -t yournamespace/hermes-agent .
```

The CI workflow (`.github/workflows/push-hermes-to-ghcr.yml`) runs this automatically on every push to `main` that touches `Dockerfile`, `ROOT/**`, or the workflow file itself.

## Making Changes

### Dockerfile changes
- Update `HERMES_REF` to pin a new Hermes Agent release.
- Update `LLAMA_CPP_BASE` to pick up a new llama.cpp base image.
- Keep the `env-hash > /.env_hash` final step — it is required by Vast.ai tooling.

### ROOT/ changes
- Files under `ROOT/` are copied into the image at `/` during the build (`COPY ./ROOT /`).
- Paths inside `ROOT/` map 1-to-1 to absolute paths inside the container.
- Startup scripts (`vast_boot.d/`, `supervisor-scripts/`) must be POSIX-compatible bash and must not assume network access before provisioning completes (check for `/.provisioning`).
- The seed config (`ROOT/etc/hermes-agent/config.seed.yaml`) uses `__PLACEHOLDER__` tokens replaced at runtime by `hermes-agent.sh`; do not change the token syntax without updating the replacement logic in that script.

### templates/ changes
- `templates/default/template.yml` defines the Vast.ai instance template (ports, default env vars, GPU filters). Keep port mappings in sync with the `PORTAL_CONFIG` default in `ROOT/etc/vast_boot.d/05-llama-env.sh`.

## Validation

There is no local test suite. To validate changes:

1. **Build the image locally** (see above) and confirm it builds without errors.
2. **Run the container** and inspect `supervisorctl status` to confirm both `llama` and `hermes-agent` start successfully.
3. The CI workflow pushes to GHCR on every qualifying push to `main`; check the Actions tab for build status.

Shell scripts in `ROOT/` can be linted with `shellcheck` if available, but there is no automated lint step in CI.

## Conventions

- Keep `HERMES_REF` pinned to an exact tag (e.g. `v2026.7.20`), not a branch or `latest`.
- Keep `LLAMA_CPP_BASE` pinned to an exact image digest or tag.
- Do not expose `llama-server` on a public port; it must remain on `127.0.0.1`.
- Do not add secrets or credentials to any file tracked by git.
- All user-facing configuration should be driven by environment variables, not hard-coded values or mounted files.
