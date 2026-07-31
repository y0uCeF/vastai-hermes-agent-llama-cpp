#!/bin/bash

if [[ -z $PORTAL_CONFIG ]]; then
    export PORTAL_CONFIG="localhost:1111:11111:/:Instance Portal|localhost:9119:9119:/:Hermes Dashboard|localhost:8080:18080:/:Jupyter|localhost:8080:8080:/terminals/1:Jupyter Terminal"
fi

# If the user supplied HERMES_MODEL but not LLAMA_MODEL, derive LLAMA_MODEL from it
# so a single variable controls both the model download and Hermes configuration.
export LLAMA_MODEL="${LLAMA_MODEL:-${HERMES_MODEL:-}}"
export MODEL_NAME="${LLAMA_MODEL:-$MODEL_NAME}"
export LLAMA_MODEL="$MODEL_NAME"

llama_cache="${WORKSPACE:-/workspace}/llama.cpp"
mkdir -p "${llama_cache}"
default_cache="${HOME}/.cache/llama.cpp"
mkdir -p "${HOME}/.cache"
ln -sf "${llama_cache}" "${default_cache}" 2>/dev/null || true
