# Hermes Agent
> **[Create an Instance](https://cloud.vast.ai/?ref_id=68321&creator_id=68321&name=Hermes%20Agent)**

## What is this template?

This template launches **Hermes Agent with a built-in local llama.cpp backend** on Vast.ai. Hermes provides the browser dashboard and agent runtime, while llama.cpp stays private inside the container and serves Hermes over `localhost`.

It is meant for users who want a self-hosted Hermes deployment without separately wiring a model endpoint: launch the template, let llama.cpp download the default GGUF model, and then use Hermes through the dashboard.

---

## What can I do with this?

- Run Hermes Agent from the browser dashboard
- Keep the bundled llama.cpp server private to the container
- Tune Hermes with launch-time environment variables
- Seed or replace the full Hermes `config.yaml` from env data
- Persist Hermes config, sessions, skills, logs, and memories under `${WORKSPACE:-/workspace}/.hermes`
- Use a Vast.ai provisioning script to run `hermes config set ...` before the dashboard starts
- Enable the optional Hermes gateway service for messaging integrations

---

## Quick Start Guide

### Step 1: Launch
Click **"[Rent](https://cloud.vast.ai/?ref_id=68321&creator_id=68321&name=Hermes%20Agent)"** on a GPU instance that fits the model you want to run.

### Step 2: Set required dashboard auth
Before launch, set both of these environment variables:

- `HERMES_DASHBOARD_BASIC_AUTH_USERNAME`
- `HERMES_DASHBOARD_BASIC_AUTH_PASSWORD`

The dashboard will not start without them.

### Step 3: Wait for setup
The image starts `llama-server` first, waits for the local OpenAI-compatible endpoint to become healthy, materializes Hermes' `config.yaml`, and then starts the Hermes dashboard.

### Step 4: Open Hermes Agent
Open the **Hermes Dashboard** entry in the Instance Portal. The dashboard binds to `0.0.0.0` so Vast can publish it through the portal, and the image requires basic auth for protection. llama.cpp remains internal-only on `127.0.0.1:18000`.

---

## How Hermes configuration is created

On startup, the image writes `${HERMES_HOME:-${WORKSPACE:-/workspace}/.hermes}/config.yaml` from the first source that matches:

1. `HERMES_CONFIG_URL`
2. `HERMES_CONFIG_B64`
3. `HERMES_CONFIG_INLINE`
4. an existing `${HERMES_HOME}/config.yaml`
5. the baked seed config

If no custom config is supplied, the seed config points Hermes at the local llama.cpp endpoint on `http://127.0.0.1:18000/v1` and fills in the model name from `HERMES_MODEL` or `LLAMA_MODEL`.

---

## Tuning Hermes without rebuilding

### Option A: launch-time environment variables

Use env vars when you want to change the model download, dashboard binding, default seeded config, or replace the whole `config.yaml` before Hermes starts.

Common patterns:

- Change the bundled model with `HERMES_MODEL` or `LLAMA_MODEL`
- Point the seeded config at another OpenAI-compatible endpoint with `HERMES_MODEL_BASE_URL`
- Replace the entire Hermes config with `HERMES_CONFIG_URL`, `HERMES_CONFIG_B64`, or `HERMES_CONFIG_INLINE`
- Enable the messaging gateway with `HERMES_GATEWAY=1`

### Option B: provisioning script with `hermes config set`

If you want to keep the default generated config and adjust a few keys, use a Vast.ai provisioning script. Example:

```bash
export HERMES_HOME="${WORKSPACE:-/workspace}/.hermes"

hermes config set model.base_url http://127.0.0.1:18000/v1
hermes config set model.default "${HERMES_MODEL:-${LLAMA_MODEL:-local-llama}}"

# Provider-specific secrets belong in $HERMES_HOME/.env, not config.yaml
# echo "OPENAI_API_KEY=..." >> "$HERMES_HOME/.env"
```

Use this approach for targeted config edits. Use `HERMES_CONFIG_URL`, `HERMES_CONFIG_B64`, or `HERMES_CONFIG_INLINE` when you want to supply the full file yourself.

If you set one of the `HERMES_CONFIG_*` variables on every boot, it will overwrite changes made later with `hermes config set`.

For the full list of supported Hermes config keys, see the upstream Hermes documentation:

- https://hermes-agent.nousresearch.com/docs/user-guide/configuration
- https://hermes-agent.nousresearch.com/docs/reference/environment-variables

---

## Key Features

| Feature | Details |
|--------|---------|
| Hermes Dashboard | Primary user-facing web UI on port `19119` |
| Private llama.cpp backend | Local-only OpenAI-compatible server on `127.0.0.1:18000` |
| Workspace persistence | Hermes home, config, sessions, logs, skills, and memories live in `${WORKSPACE:-/workspace}/.hermes` |
| Config materialization | Runtime config can come from env vars, fetched content, an existing config file, or the baked seed config |
| Optional gateway | `hermes gateway run` can be enabled under Supervisor with `HERMES_GATEWAY=1` |
| Shared Vast runtime | Instance Portal, Jupyter, SSH, provisioning, and Supervisor are included |

---

## Ports

| Service | External Port | Internal Port |
|---------|---------------|---------------|
| Instance Portal | 1111 | 11111 |
| Hermes Dashboard | 9119 | 19119 |
| Jupyter | 8080 | 18080 |
| llama.cpp | not exposed | 18000 |

---

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `HERMES_MODEL` | `unsloth/Qwen3.6-27B-GGUF:UD-Q4_K_XL` | Default model name for the template and the seeded Hermes config |
| `LLAMA_MODEL` | inherits `HERMES_MODEL` if unset | HuggingFace GGUF repo loaded by the bundled llama.cpp server |
| `LLAMA_ARGS` | `--host 127.0.0.1 --port 18000` | Extra llama.cpp server arguments |
| `HERMES_DASHBOARD_ARGS` | `--host 0.0.0.0 --port 19119 --no-open` | Arguments passed to `hermes dashboard` |
| `HERMES_DASHBOARD_BASIC_AUTH_USERNAME` | (required) | Username for Hermes dashboard basic authentication |
| `HERMES_DASHBOARD_BASIC_AUTH_PASSWORD` | (required) | Password for Hermes dashboard basic authentication |
| `HERMES_MODEL_PROVIDER` | `custom` | Provider written into the seeded Hermes config |
| `HERMES_MODEL_BASE_URL` | `http://127.0.0.1:18000/v1` | OpenAI-compatible backend URL for the seeded config |
| `HERMES_CONFIG_URL` | (none) | URL to fetch as `config.yaml` |
| `HERMES_CONFIG_B64` | (none) | Base64-encoded `config.yaml` content |
| `HERMES_CONFIG_INLINE` | (none) | Literal `config.yaml` content |
| `HERMES_HOME` | `${WORKSPACE:-/workspace}/.hermes` | Hermes runtime home for config and state data |
| `HERMES_GATEWAY` | (none) | Set to `1` to enable the `hermes-gateway` Supervisor service |
| `HERMES_LLAMA_HEALTH_URL` | `${HERMES_MODEL_BASE_URL%/v1}/health` | Health endpoint checked before Hermes starts |
| `HERMES_LLAMA_TIMEOUT` | `3600` | Seconds to wait for llama.cpp to become healthy |

---

## Service Management

```bash
supervisorctl status llama hermes-agent hermes-gateway
supervisorctl restart llama
supervisorctl restart hermes-agent
supervisorctl restart hermes-gateway
```

---

## Licenses

- **Hermes Agent** — MIT
- **llama.cpp** — MIT

See `/LICENSES.md` in the image for license file paths.
