#!/bin/bash

utils=/opt/supervisor-scripts/utils
. "${utils}/logging.sh"
. "${utils}/cleanup_generic.sh"
. "${utils}/environment.sh"
. "${utils}/exit_portal.sh" "Hermes Dashboard"

export HERMES_INSTALL_DIR="${HERMES_INSTALL_DIR:-/opt/hermes-agent}"
export HERMES_HOME="${HERMES_HOME:-${WORKSPACE:-/workspace}/.hermes}"
export HERMES_MODEL_PROVIDER="${HERMES_MODEL_PROVIDER:-custom}"
export HERMES_MODEL_BASE_URL="${HERMES_MODEL_BASE_URL:-http://127.0.0.1:18000/v1}"

mkdir -p "$HERMES_HOME" "$HERMES_HOME/cron" "$HERMES_HOME/logs" "$HERMES_HOME/sessions" "$HERMES_HOME/skills" "$HERMES_HOME/memories"

while [ -f "/.provisioning" ]; do
    echo "$PROC_NAME startup paused until instance provisioning has completed (/.provisioning present)"
    sleep 10
done

wait_for_llama() {
    local health_url="${HERMES_LLAMA_HEALTH_URL:-${HERMES_MODEL_BASE_URL%/v1}/health}"
    local timeout="${HERMES_LLAMA_TIMEOUT:-3600}"
    local elapsed=0

    while (( elapsed < timeout )); do
        if curl -sf -H "Authorization: Bearer ${LLAMA_API_KEY:-hermes}" "$health_url" >/dev/null 2>&1; then
            echo "llama.cpp is healthy at $health_url"
            return 0
        fi
        sleep 5
        elapsed=$((elapsed + 5))
    done

    echo "Timed out waiting for llama.cpp at $health_url"
    return 1
}

fetch_llama_model_id() {
    curl -sf -H "Authorization: Bearer ${LLAMA_API_KEY:-hermes}" "${HERMES_MODEL_BASE_URL%/}/models" 2>/dev/null | python3 -c 'import json,sys; data=json.load(sys.stdin); models=data.get("data") or []; print((models[0] or {}).get("id", "") if models else "")'
}

materialize_config() {
    local config_path="$HERMES_HOME/config.yaml"

    if [[ -n "${HERMES_CONFIG_URL:-}" ]]; then
        echo "Fetching Hermes config from HERMES_CONFIG_URL"
        curl -fsSL "$HERMES_CONFIG_URL" -o "$config_path"
        return 0
    fi

    if [[ -n "${HERMES_CONFIG_B64:-}" ]]; then
        echo "Decoding Hermes config from HERMES_CONFIG_B64"
        printf '%s' "$HERMES_CONFIG_B64" | base64 -d > "$config_path"
        return 0
    fi

    if [[ -n "${HERMES_CONFIG_INLINE:-}" ]]; then
        echo "Writing Hermes config from HERMES_CONFIG_INLINE"
        printf '%s\n' "$HERMES_CONFIG_INLINE" > "$config_path"
        return 0
    fi

    if [[ -f "$config_path" ]]; then
        echo "Using existing Hermes config at $config_path"
        local resolved_model="${HERMES_MODEL:-$(fetch_llama_model_id)}"
        resolved_model="${resolved_model:-${LLAMA_MODEL:-local-llama}}"

        echo "No HERMES_CONFIG_* provided; configuring Hermes model defaults via CLI"
        pty hermes config set model.default "$resolved_model"
        pty hermes config set model.provider "custom"
        pty hermes config set model.base_url "${HERMES_MODEL_BASE_URL}"
        pty hermes config set model.api_key "${LLAMA_API_KEY:-hermes}"
        return 0
    fi
}

wait_for_llama
materialize_config

echo "📁 Your files:"
echo
echo "   Config:    $HERMES_HOME/config.yaml"
echo "   API Keys:  $HERMES_HOME/.env"
echo "   Data:      $HERMES_HOME/cron/, sessions/, logs/"
echo "   Code:      /opt/hermes-agent"

if [[ -z "${HERMES_DASHBOARD_BASIC_AUTH_USERNAME:-}" || -z "${HERMES_DASHBOARD_BASIC_AUTH_PASSWORD:-}" ]]; then
    echo "ERROR: Required environment variables HERMES_DASHBOARD_BASIC_AUTH_USERNAME and HERMES_DASHBOARD_BASIC_AUTH_PASSWORD are not set. The Hermes dashboard requires basic authentication."
    exit 1
fi

cd "$HERMES_HOME"
pty hermes dashboard ${HERMES_DASHBOARD_ARGS:---host 0.0.0.0 --port 19119 --no-open}
