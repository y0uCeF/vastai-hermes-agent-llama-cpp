#!/bin/bash

utils=/opt/supervisor-scripts/utils
. "${utils}/logging.sh"
. "${utils}/cleanup_generic.sh"
. "${utils}/environment.sh"

export HERMES_INSTALL_DIR="${HERMES_INSTALL_DIR:-/opt/hermes-agent}"
export HERMES_HOME="${HERMES_HOME:-${DATA_DIRECTORY:-/workspace}/.hermes}"

if [[ "${HERMES_GATEWAY:-}" != "1" ]]; then
    echo "HERMES_GATEWAY is not set to 1; skipping gateway service"
    exit 0
fi

while [ -f "/.provisioning" ]; do
    echo "$PROC_NAME startup paused until instance provisioning has completed (/.provisioning present)"
    sleep 10
done

cd "$HERMES_HOME"
hermes gateway run 2>&1
