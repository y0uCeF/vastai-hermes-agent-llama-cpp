# Hermes Agent Image

A Hermes Agent image derived from the Vast.ai [llama.cpp image](https://hub.docker.com/r/vastai/llama-cpp). It keeps llama.cpp running privately on `127.0.0.1:18000` and exposes Hermes Agent's dashboard as the primary user-facing app.

## How This Image Works

This image extends a concrete `vastai/llama-cpp` base (`b10182-cuda-12.9`) with a pinned Hermes Agent install (`v2026.7.31`) using Hermes' documented Linux installer flow in non-interactive mode.

At runtime:

- `llama-server` remains a Supervisor-managed service, but only on `127.0.0.1:18000`
- `hermes dashboard` is the primary portal app on port `19119`
- Hermes runtime state lives under `${WORKSPACE:-/workspace}/.hermes`
- `config.yaml` is materialized at startup from one of:
  1. `HERMES_CONFIG_URL`
  2. `HERMES_CONFIG_B64`
  3. `HERMES_CONFIG_INLINE`
  4. the baked seed config
- the baked seed config points Hermes at the local llama.cpp OpenAI-compatible endpoint on `http://127.0.0.1:18000/v1`

## Runtime Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `LLAMA_MODEL` | `unsloth/Qwen3.6-27B-GGUF:UD-Q4_K_XL` | HuggingFace GGUF repo to load into the bundled llama.cpp server |
| `LLAMA_ARGS` | `--host 127.0.0.1 --port 18000` | Extra llama.cpp server arguments |
| `HERMES_DASHBOARD_ARGS` | `--host 0.0.0.0 --port 9119 --no-open` | Arguments passed to `hermes dashboard` |
| `HERMES_DASHBOARD_BASIC_AUTH_USERNAME` | (required) | Username for Hermes dashboard basic authentication — dashboard will not start if unset |
| `HERMES_DASHBOARD_BASIC_AUTH_PASSWORD` | (required) | Password for Hermes dashboard basic authentication — dashboard will not start if unset |
| `HERMES_MODEL_BASE_URL` | `http://127.0.0.1:18000/v1` | OpenAI-compatible endpoint Hermes should use by default |
| `HERMES_MODEL` | auto-detected | Model name written into the default Hermes config when no custom config is supplied |
| `HERMES_CONFIG_URL` | (none) | URL to download as `$HERMES_HOME/config.yaml` at startup |
| `HERMES_CONFIG_B64` | (none) | Base64-encoded `config.yaml` content |
| `HERMES_CONFIG_INLINE` | (none) | Literal `config.yaml` content |
| `HERMES_HOME` | `${WORKSPACE:-/workspace}/.hermes` | Hermes runtime home for config/state data |
| `HERMES_GATEWAY` | (none) | Set to `1` to enable the `hermes-gateway` Supervisor service (`hermes gateway run`) |

### Port Reference

| Service | External Port | Internal Port |
|---------|---------------|---------------|
| Instance Portal | 1111 | 11111 |
| Hermes Dashboard | 9119 | 19119 |
| Jupyter | 8080 | 18080 |
| llama.cpp | (internal only) | 18000 |

## Service Management

Both services are Supervisor-managed:

```bash
supervisorctl status llama hermes-agent hermes-gateway
supervisorctl restart llama
supervisorctl restart hermes-agent
supervisorctl restart hermes-gateway
```

## Building From Source

```bash
git clone https://github.com/y0uCeF/vastai-hermes-llamacpp.git
cd vastai-hermes-llamacpp

docker buildx build \
    --build-arg LLAMA_CPP_BASE=vastai/llama-cpp:b10182-cuda-12.9 \
    --build-arg HERMES_REF=v2026.7.30 \
    -t yournamespace/hermes-agent .
```

## Assumptions

- The first version skips Hermes' optional browser install to keep the build non-interactive and container-friendly.
- Hermes is served through the base-image Caddy/portal path; no additional public llama.cpp exposure is enabled.
- Custom Hermes runtime configuration is expected through env-backed generation or a fetched config URL, not a mounted `config.yaml`.

## Licenses

This image ships vendor application(s) under the following license(s):

- **Hermes Agent** — MIT ([upstream](https://github.com/NousResearch/hermes-agent))
- **llama.cpp** — MIT ([upstream](https://github.com/ggml-org/llama.cpp))

See `/LICENSES.md` in the image for license details and file locations.
