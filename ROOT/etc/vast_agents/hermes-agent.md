# Hermes Agent image guide

- Primary user-facing app: **Hermes Dashboard** via the Instance Portal entry on port `9119`.
- The bundled llama.cpp server stays private on `127.0.0.1:18000` and feeds Hermes through an OpenAI-compatible endpoint.
- Hermes runtime state lives under `${HERMES_HOME:-${DATA_DIRECTORY:-/workspace}/.hermes}`.
- If you need to replace the default config, set `HERMES_CONFIG_URL`, `HERMES_CONFIG_B64`, or `HERMES_CONFIG_INLINE` and restart `hermes-agent`.
- Useful service commands:
  - `supervisorctl status llama hermes-agent`
  - `supervisorctl restart llama`
  - `supervisorctl restart hermes-agent`
