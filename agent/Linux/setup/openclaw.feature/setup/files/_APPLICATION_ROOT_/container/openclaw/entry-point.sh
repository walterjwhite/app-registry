#!/bin/sh
set -euo pipefail
PROVIDER="${AI_PROVIDER:-}"
echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║           openclaw  •  Ubuntu 24.04           ║"
echo "╚══════════════════════════════════════════════╝"
if [[ -z "$PROVIDER" ]]; then
  echo "⚠  AI_PROVIDER is not set."
  echo "   Available: codex | copilot | gemini | kiro | qwen | opencode | claude"
  echo ""
  exec "$@"
  exit 0
fi
echo "→ Provider : $PROVIDER"
echo ""
case "$PROVIDER" in
codex)
  : "${OPENAI_API_KEY:?ERROR: OPENAI_API_KEY must be set for codex}"
  export OPENAI_API_KEY
  echo "✔  OpenAI / Codex ready  (model: ${OPENAI_MODEL:-gpt-4o})"
  ;;
copilot)
  : "${GITHUB_TOKEN:?ERROR: GITHUB_TOKEN must be set for copilot}"
  export GITHUB_TOKEN
  if command -v github-copilot-cli &>/dev/null; then
    echo "✔  GitHub Copilot CLI ready"
  else
    echo "⚠  github-copilot-cli not found in PATH"
  fi
  ;;
gemini)
  : "${GEMINI_API_KEY:?ERROR: GEMINI_API_KEY must be set for gemini}"
  export GEMINI_API_KEY
  echo "✔  Gemini CLI ready  (model: ${GEMINI_MODEL:-gemini-2.0-flash})"
  ;;
kiro)
  : "${AWS_ACCESS_KEY_ID:?ERROR: AWS_ACCESS_KEY_ID must be set for kiro}"
  : "${AWS_SECRET_ACCESS_KEY:?ERROR: AWS_SECRET_ACCESS_KEY must be set for kiro}"
  export AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY
  export AWS_REGION="${AWS_REGION:-us-east-1}"
  echo "✔  Kiro (AWS) ready  (region: $AWS_REGION)"
  ;;
qwen)
  : "${DASHSCOPE_API_KEY:?ERROR: DASHSCOPE_API_KEY must be set for qwen}"
  export DASHSCOPE_API_KEY
  echo "✔  Qwen agent ready  (model: ${QWEN_MODEL:-qwen-max})"
  ;;
opencode)
  if [[ -n "${OPENCODE_CONFIG:-}" ]]; then
    echo "$OPENCODE_CONFIG" >/root/.config/opencode/config.json
  fi
  echo "✔  OpenCode ready"
  ;;
claude)
  : "${ANTHROPIC_API_KEY:?ERROR: ANTHROPIC_API_KEY must be set for claude}"
  export ANTHROPIC_API_KEY
  echo "✔  Claude Code ready  (model: ${ANTHROPIC_MODEL:-claude-sonnet-4-5})"
  ;;
*)
  echo "✘  Unknown provider: '$PROVIDER'"
  echo "   Valid choices: codex | copilot | gemini | kiro | qwen | opencode | claude"
  exit 1
  ;;
esac
echo ""
exec "$@"
