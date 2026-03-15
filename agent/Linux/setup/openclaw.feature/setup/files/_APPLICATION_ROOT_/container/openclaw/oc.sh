#!/bin/sh
set -euo pipefail
PROVIDERS=(codex copilot gemini kiro qwen opencode claude)
_oc_usage() {
  echo ""
  echo "  Usage: ./oc.sh <provider> [extra podman-compose args]"
  echo ""
  echo "  Providers:"
  for p in "${PROVIDERS[@]}"; do
    echo "    • $p"
  done
  echo ""
  exit 1
}
PROVIDER="${1:-}"
[[ -z "$PROVIDER" ]] && _oc_usage
VALID=false
for p in "${PROVIDERS[@]}"; do
  [[ "$p" == "$PROVIDER" ]] && VALID=true && break
done
[[ "$VALID" == false ]] && echo "✘  Unknown provider: $PROVIDER" && usage
shift # remaining args passed straight to podman-compose
if command -v podman-compose &>/dev/null; then
  COMPOSE="podman-compose"
elif command -v docker &>/dev/null; then
  COMPOSE="docker compose"
else
  echo "✘  Neither podman-compose nor docker found in PATH."
  exit 1
fi
echo "→ Starting openclaw with provider: $PROVIDER"
echo "→ Compose backend: $COMPOSE"
echo ""
$COMPOSE --profile "$PROVIDER" up "$@"
