#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
. "$ROOT_DIR/scripts/python_env.sh"
PYTHON_BIN="$(find_tokstat_python)"
DB_PATH="${TOKSTAT_DB_PATH:-$HOME/.tokstat/usage.sqlite}"
TIMEZONE="${TOKSTAT_TIMEZONE:-Asia/Shanghai}"
PORT="${TOKSTAT_KAKU_PROXY_PORT:-8765}"
HOST="${TOKSTAT_KAKU_PROXY_HOST:-127.0.0.1}"
UPSTREAM_BASE_URL="${TOKSTAT_KAKU_UPSTREAM_BASE_URL:-}"

if [[ -z "$UPSTREAM_BASE_URL" ]]; then
  echo "TOKSTAT_KAKU_UPSTREAM_BASE_URL is required" >&2
  exit 1
fi

mkdir -p "$(dirname "$DB_PATH")"

PYTHONPATH="$ROOT_DIR/src" \
"$PYTHON_BIN" -m tokstat.cli \
  --db "$DB_PATH" \
  --timezone "$TIMEZONE" \
  serve-proxy \
  --host "$HOST" \
  --port "$PORT" \
  --upstream-base-url "$UPSTREAM_BASE_URL"
