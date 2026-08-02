# 🚀 Hermes Agent + llama.cpp on Vast.ai

<p align="center">
  <!-- Replace these with real files in /assets/logos -->
  <img src="./assets/logos/hermes-agent.png" alt="Hermes Agent" height="72" />
  &nbsp;&nbsp;
  <img src="./assets/logos/llama-cpp.png" alt="llama.cpp" height="72" />
  &nbsp;&nbsp;
  <img src="./assets/logos/vast-ai.png" alt="Vast.ai" height="72" />
</p>

<p align="center">
  <b>A Vast.ai-focused image template for Hermes Agent, backed by a private llama.cpp server.</b>
</p>

---

## ✨ What this repository provides

This repository produces a container image intended to run on **Vast.ai** with:

- 🧠 **Hermes Agent dashboard** (user-facing)
- 🦙 **llama.cpp server** (private, internal-only)
- 🧰 **Vast.ai runtime integrations** (portal + startup hooks + capabilities)

> 📌 **Scope:** This project is intended for **Vast.ai usage**, not for general local Docker usage by end users.

---

## 🧭 Quick Start (Vast.ai)

1. Click **[Create an Instance](https://cloud.vast.ai/?ref_id=68321&creator_id=68321&name=Hermes%20Agent)**.
2. Open the Hermes dashboard on port **`19119`** from the Instance Portal.

For template-specific fields and advanced configuration options, see:
- [`templates/default/README.md`](./templates/default/README.md)

---

## 🔌 Services & Ports

| Service | Bind | Port | Public? |
|---|---|---:|---|
| llama-server | `127.0.0.1` | `18000` | ❌ No (internal only) |
| Hermes dashboard | template-mapped | `19119` | ✅ Yes |
| Jupyter (inherited) | base image default | `18080` | optional |
| Instance Portal (inherited) | base image default | `11111` | optional |

> 🔒 `llama-server` must remain private and bound to localhost.

---

## ⚙️ Runtime Configuration

Hermes config is materialized at startup with this precedence:

1. `HERMES_CONFIG_URL`
2. `HERMES_CONFIG_B64`
3. `HERMES_CONFIG_INLINE`
4. Existing `$HERMES_HOME/config.yaml`
5. Seed config (`ROOT/etc/hermes-agent/config.seed.yaml`)

This allows per-instance configuration via environment variables without rebuilding the image.

### Key environment variables

| Variable | Default | Purpose |
|---|---|---|
| `LLAMA_MODEL` | from `HERMES_MODEL` | GGUF model repo for llama.cpp |
| `LLAMA_ARGS` | `--host 127.0.0.1 --port 18000` | Extra llama-server args |
| `HERMES_DASHBOARD_ARGS` | dashboard launch args | Hermes dashboard startup flags |
| `HERMES_MODEL_BASE_URL` | `http://127.0.0.1:18000/v1` | OpenAI-compatible endpoint |
| `HERMES_MODEL` | auto-detected | Model name written into Hermes config |
| `HERMES_CONFIG_URL` | _(none)_ | Download config YAML |
| `HERMES_CONFIG_B64` | _(none)_ | Base64-encoded config YAML |
| `HERMES_CONFIG_INLINE` | _(none)_ | Inline config YAML |
| `HERMES_HOME` | `${WORKSPACE:-/workspace}/.hermes` | Hermes runtime directory |

---

## 🏗 Repository Layout

```text
.
├── Dockerfile
├── ROOT/
│   ├── etc/
│   │   ├── hermes-agent/config.seed.yaml
│   │   ├── supervisor/conf.d/hermes-agent.conf
│   │   ├── vast_boot.d/05-llama-env.sh
│   │   └── vast_capabilities.d/50-hermes-agent.yaml
│   └── opt/supervisor-scripts/
│       ├── hermes-agent.sh
│       └── llama.sh
├── templates/
│   └── default/
│       ├── README.md
│       └── template.yml
└── .github/workflows/push-hermes-to-ghcr.yml
```

---

## 🤖 CI / Publishing

GitHub Actions builds and publishes the image on qualifying pushes to `main`.

Workflow:
- `.github/workflows/push-hermes-to-ghcr.yml`

Published image:
- `ghcr.io/y0ucef/hermes-agent:latest`

---

## 🩺 Validation (maintainers)

- [ ] Image builds successfully in CI
- [ ] `supervisorctl status` shows both `llama` and `hermes-agent` as running
- [ ] Hermes dashboard is reachable on mapped port `19119`
- [ ] Hermes connects to `http://127.0.0.1:18000/v1`

---

## 🛠 Troubleshooting

### Dashboard unavailable
- Verify the template maps/exposes port `19119`
- Check `hermes-agent` supervisor logs

### Hermes cannot reach model endpoint
- Confirm `llama` process is healthy on `127.0.0.1:18000`
- Confirm `HERMES_MODEL_BASE_URL=http://127.0.0.1:18000/v1`

### Unexpected model/config behavior
- Set `LLAMA_MODEL` and/or `HERMES_MODEL` explicitly
- Inspect effective runtime env and generated config

---

## 📄 License & Notices

See:
- `ROOT/LICENSES.md`
- Upstream project licenses (`Hermes Agent`, `llama.cpp`, base image dependencies)
