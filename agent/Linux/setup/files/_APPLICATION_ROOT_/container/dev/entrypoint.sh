#!/bin/sh
set -euo pipefail
WORKSPACE=/workspace
INPUT=/input
echo "[sandbox] Cleaning /workspace..."
rm -rf "${WORKSPACE:?}"/*
rm -rf "${WORKSPACE:?}"/.[!.]* 2>/dev/null || true
if [ -d "$INPUT" ] && [ "$(ls -A "$INPUT" 2>/dev/null)" ]; then
    echo "[sandbox] Injecting files from /input into /workspace..."
    cp -r "$INPUT"/. "$WORKSPACE/"
    echo "[sandbox] Injected files:"
    find "$WORKSPACE" -maxdepth 3 -not -path '*/.git/*' | sort | sed 's|^|  |'
else
    echo "[sandbox] No /input files found — starting with empty /workspace."
fi
echo "[sandbox] Ready."
echo ""
exec "$@"
