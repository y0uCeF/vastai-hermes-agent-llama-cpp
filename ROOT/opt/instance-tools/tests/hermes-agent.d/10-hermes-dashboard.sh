#!/bin/bash
# Test: Hermes dashboard + private llama.cpp integration.
# TEST_TIMEOUT=7200
source "$(dirname "$0")/../lib.sh"

LLAMA_INTERNAL_PORT=18000
HERMES_INTERNAL_PORT=9119
LLAMA_HEALTH_TIMEOUT="${LLAMA_HEALTH_TIMEOUT:-3600}"
HERMES_HEALTH_TIMEOUT="${HERMES_HEALTH_TIMEOUT:-600}"

portal_config_has() {
    local pattern="$1"
    [[ -n "${PORTAL_CONFIG:-}" ]] && echo "$PORTAL_CONFIG" | tr '|' '\n' | grep -qiE "$pattern"
}

[[ -n "${LLAMA_MODEL:-${HERMES_MODEL:-}}" ]] || test_skip "HERMES_MODEL not set"
echo "  HERMES_MODEL=${HERMES_MODEL:-} LLAMA_MODEL=${LLAMA_MODEL:-}"

echo ""
echo "  -- services --"
assert_service_running llama
assert_service_running hermes-agent
echo "  llama: supervisor service running"
echo "  hermes-agent: supervisor service running"

echo ""
echo "  -- llama health --"
elapsed=0
while (( elapsed < LLAMA_HEALTH_TIMEOUT )); do
    status=$(curl -s --max-time 5 -o /dev/null -w '%{http_code}' "http://127.0.0.1:${LLAMA_INTERNAL_PORT}/health" 2>/dev/null)
    if [[ "$status" == "200" ]]; then
        echo "  llama healthy after ${elapsed}s"
        break
    fi
    sleep 5
    elapsed=$((elapsed + 5))
done
[[ "${status:-}" == "200" ]] || test_fail "llama health endpoint unavailable"

models_json=$(curl -sf --max-time 10 "http://127.0.0.1:${LLAMA_INTERNAL_PORT}/v1/models" 2>/dev/null)
[[ -n "$models_json" ]] || test_fail "llama /v1/models returned empty response"
echo "  llama /v1/models reachable"

echo ""
echo "  -- hermes dashboard --"
elapsed=0
status=""
while (( elapsed < HERMES_HEALTH_TIMEOUT )); do
    status=$(curl -s --max-time 5 -o /tmp/hermes-status.json -w '%{http_code}' "http://127.0.0.1:${HERMES_INTERNAL_PORT}/api/status" 2>/dev/null)
    if [[ "$status" == "200" ]]; then
        echo "  Hermes dashboard healthy after ${elapsed}s"
        break
    fi
    sleep 5
    elapsed=$((elapsed + 5))
done
[[ "$status" == "200" ]] || test_fail "Hermes dashboard /api/status not reachable"

python3 - <<'PY'
import json
from pathlib import Path
payload = json.loads(Path('/tmp/hermes-status.json').read_text())
print(f"  auth_required={payload.get('auth_required')}")
providers = payload.get('auth_providers') or []
if providers:
    print(f"  auth_providers={providers}")
PY

if is_serverless; then
    echo "  skip: external port check (serverless)"
elif portal_config_has "Hermes Dashboard"; then
    if ss -tln | grep -q ":9119 "; then
        echo "  Hermes Dashboard port listening on 9119"
    else
        fail_later "port-9119" "Hermes Dashboard in PORTAL_CONFIG but port 9119 not listening"
    fi
else
    echo "  skip: Hermes Dashboard not in PORTAL_CONFIG"
fi

test_pass "Hermes dashboard and private llama.cpp integration verified"
