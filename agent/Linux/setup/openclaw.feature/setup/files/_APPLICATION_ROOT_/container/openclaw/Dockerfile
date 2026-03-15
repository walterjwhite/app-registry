FROM ubuntu:24.04
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    wget \
    git \
    unzip \
    ca-certificates \
    gnupg \
    lsb-release \
    build-essential \
    python3 \
    python3-pip \
    python3-venv \
    jq \
    vim \
    nano \
    tmux \
    less \
    && rm -rf /var/lib/apt/lists/*
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
  && apt-get install -y --no-install-recommends nodejs \
  && rm -rf /var/lib/apt/lists/*
RUN npm install -g \
    @openai/codex \
    @github/copilot \
    @google/gemini-cli \
    opencode-ai \
    @qwen-code/qwen-code
RUN curl -fsSL https://desktop-release.q.us-east-1.amazonaws.com/latest/kirocli-x86_64-linux.zip \
      -o /tmp/kirocli.zip \
  && unzip /tmp/kirocli.zip \
  && mv kirocli/bin/kiro-cli /usr/local/bin \
  && mv kirocli/bin/kiro-cli-chat /usr/local/bin \
  && mv kirocli/bin/kiro-cli-term /usr/local/bin \
  && chmod +x /usr/local/bin/kiro-cli /usr/local/bin/kiro-cli-chat /usr/local/bin/kiro-cli-term \
  && rm /tmp/kirocli.zip \
  && rm -rf kirocli
RUN mkdir -p /workspace
WORKDIR /workspace
COPY entry-point.sh /entry-point.sh
RUN chmod +x /entry-point.sh
ENTRYPOINT ["/entry-point.sh"]
CMD ["bash"]
