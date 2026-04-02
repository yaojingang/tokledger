#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
. "$ROOT_DIR/scripts/python_env.sh"
PYTHON_BIN="$(find_tokstat_python)"
DB_PATH="${TOKSTAT_DB_PATH:-$HOME/.tokstat/usage.sqlite}"
TIMEZONE="${TOKSTAT_TIMEZONE:-Asia/Shanghai}"
SCAN_MODE="${TOKSTAT_SCAN_MODE:-all}"

mkdir -p "$(dirname "$DB_PATH")"

case "$SCAN_MODE" in
  codex)
    PYTHONPATH="$ROOT_DIR/src" \
    "$PYTHON_BIN" -m tokstat.cli \
      --db "$DB_PATH" \
      --timezone "$TIMEZONE" \
      scan-codex
    ;;
  warp)
    PYTHONPATH="$ROOT_DIR/src" \
    "$PYTHON_BIN" -m tokstat.cli \
      --db "$DB_PATH" \
      --timezone "$TIMEZONE" \
      scan-warp
    ;;
  all)
    PYTHONPATH="$ROOT_DIR/src" \
    "$PYTHON_BIN" -m tokstat.cli \
      --db "$DB_PATH" \
      --timezone "$TIMEZONE" \
      scan-all
    ;;
  *)
    echo "Unsupported TOKSTAT_SCAN_MODE: $SCAN_MODE" >&2
    exit 1
    ;;
esac
