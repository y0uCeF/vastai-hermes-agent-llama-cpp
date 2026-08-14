ARG LLAMA_CPP_REF=b10331-cuda-12.9
ARG LLAMA_CPP_BASE=vastai/llama-cpp:${LLAMA_CPP_REF}
ARG HERMES_REF=v2026.8.13

FROM ${LLAMA_CPP_BASE}
ARG LLAMA_CPP_BASE
ARG HERMES_REF

LABEL org.opencontainers.image.source="https://github.com/y0uCeF/vastai-hermes-llamacpp"
LABEL org.opencontainers.image.description="Hermes Agent + llama.cpp image suitable for Vast.ai."
LABEL maintainer="Vast.ai Inc <contact@vast.ai>"

COPY ./ROOT /

# Build-time install uses the default workspace path.
RUN \
    set -euo pipefail && \
    apt-get update && \
    apt-get install -y --no-install-recommends ripgrep && \
    rm -rf /var/lib/apt/lists/* && \
    HERMES_COMMIT="$(git ls-remote --tags https://github.com/NousResearch/hermes-agent "refs/tags/${HERMES_REF}^{}" | awk 'NR==1 {print $1}')" && \
    if [[ -z "${HERMES_COMMIT}" ]]; then \
        HERMES_COMMIT="$(git ls-remote --tags https://github.com/NousResearch/hermes-agent "refs/tags/${HERMES_REF}" | awk 'NR==1 {print $1}')"; \
    fi && \
    [[ -n "${HERMES_COMMIT}" ]] || { echo "Unable to resolve Hermes ref ${HERMES_REF}"; exit 1; } && \
    curl -fsSL "https://raw.githubusercontent.com/NousResearch/hermes-agent/${HERMES_REF}/scripts/install.sh" -o /tmp/hermes-install.sh && \
    chmod +x /tmp/hermes-install.sh && \
    HERMES_HOME=/workspace/.hermes \
    HERMES_INSTALL_DIR=/opt/hermes-agent \
    /tmp/hermes-install.sh \
        --non-interactive \
        --skip-setup \
        --skip-browser \
        --dir /opt/hermes-agent \
        --hermes-home /workspace/.hermes \
        --commit "${HERMES_COMMIT}" && \
    rm -f /tmp/hermes-install.sh && \
    find /opt/hermes-agent /workspace/.hermes -type d -name __pycache__ -prune -exec rm -rf '{}' + && \
    rm -rf /root/.cache

ENV PATH="/root/.local/bin:${PATH}"
ENV DATA_DIRECTORY=/workspace
ENV HERMES_HOME=${DATA_DIRECTORY}/.hermes
ENV HERMES_INSTALL_DIR=/opt/hermes-agent

RUN env-hash > /.env_hash
