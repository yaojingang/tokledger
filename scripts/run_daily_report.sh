#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
. "$ROOT_DIR/scripts/python_env.sh"
PYTHON_BIN="$(find_tokstat_python)"
DB_PATH="${TOKSTAT_DB_PATH:-$HOME/.tokstat/usage.sqlite}"
TIMEZONE="${TOKSTAT_TIMEZONE:-Asia/Shanghai}"
REPORT_DIR="${TOKSTAT_REPORT_DIR:-$HOME/.tokstat/reports}"

mkdir -p "$REPORT_DIR"

REPORT_DATE="$(
  TIMEZONE="$TIMEZONE" "$PYTHON_BIN" - <<'PY'
from datetime import datetime, timedelta
from os import environ
from zoneinfo import ZoneInfo

tz = ZoneInfo(environ["TIMEZONE"])
print((datetime.now(tz).date() - timedelta(days=1)).isoformat())
PY
)"

PYTHONPATH="$ROOT_DIR/src" \
"$PYTHON_BIN" -m tokstat.cli \
  --db "$DB_PATH" \
  --timezone "$TIMEZONE" \
  report-daily \
  --date yesterday \
  --output "$REPORT_DIR/$REPORT_DATE.txt"
