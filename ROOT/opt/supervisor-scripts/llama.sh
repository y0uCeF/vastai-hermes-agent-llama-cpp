#!/bin/bash

utils=/opt/supervisor-scripts/utils
. "${utils}/logging.sh"
. "${utils}/cleanup_generic.sh"
. "${utils}/environment.sh"

echo "Starting Llama.cpp"

while [ -f "/.provisioning" ]; do
  echo "$PROC_NAME startup paused until instance provisioning has completed (/.provisioning present)"
  sleep 10
done

cd "${WORKSPACE}/"
if [[ -n "${LLAMA_MODEL:-}" ]]; then
  pty llama-server -hf "$LLAMA_MODEL" --api-key "${LLAMA_API_KEY:-hermes}" ${LLAMA_ARGS:---host 127.0.0.1 --port 18000} 2>&1
else
  echo "Model not specified. Exiting"
  sleep 6
fi
