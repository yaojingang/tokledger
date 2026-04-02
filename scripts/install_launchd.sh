#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
TOKSTAT_HOME="${TOKSTAT_HOME:-$HOME/.tokstat}"
DB_PATH="${TOKSTAT_DB_PATH:-$TOKSTAT_HOME/usage.sqlite}"
TIMEZONE="${TOKSTAT_TIMEZONE:-Asia/Shanghai}"
REPORT_DIR="${TOKSTAT_REPORT_DIR:-$TOKSTAT_HOME/reports}"
LOG_DIR="${TOKSTAT_LOG_DIR:-$TOKSTAT_HOME/logs}"
SCAN_MODE="${TOKSTAT_SCAN_MODE:-all}"
WITH_KAKU_PROXY="${TOKSTAT_INSTALL_KAKU_PROXY:-0}"
KAKU_UPSTREAM_BASE_URL="${TOKSTAT_KAKU_UPSTREAM_BASE_URL:-}"
KAKU_PROXY_HOST="${TOKSTAT_KAKU_PROXY_HOST:-127.0.0.1}"
KAKU_PROXY_PORT="${TOKSTAT_KAKU_PROXY_PORT:-8765}"

mkdir -p "$LAUNCH_AGENTS_DIR" "$TOKSTAT_HOME" "$REPORT_DIR" "$LOG_DIR"

write_plist() {
  local destination="$1"
  local label="$2"
  local script_path="$3"
  local stdout_path="$4"
  local stderr_path="$5"
  local keep_alive="$6"
  local run_at_load="$7"
  local schedule_kind="$8"
  local schedule_value="$9"

  cat >"$destination" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>$label</string>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/zsh</string>
    <string>$script_path</string>
  </array>
  <key>EnvironmentVariables</key>
  <dict>
    <key>TOKSTAT_DB_PATH</key>
    <string>$DB_PATH</string>
    <key>TOKSTAT_TIMEZONE</key>
    <string>$TIMEZONE</string>
    <key>TOKSTAT_REPORT_DIR</key>
    <string>$REPORT_DIR</string>
    <key>TOKSTAT_SCAN_MODE</key>
    <string>$SCAN_MODE</string>
    <key>TOKSTAT_KAKU_UPSTREAM_BASE_URL</key>
    <string>$KAKU_UPSTREAM_BASE_URL</string>
    <key>TOKSTAT_KAKU_PROXY_HOST</key>
    <string>$KAKU_PROXY_HOST</string>
    <key>TOKSTAT_KAKU_PROXY_PORT</key>
    <string>$KAKU_PROXY_PORT</string>
  </dict>
  <key>RunAtLoad</key>
  <$run_at_load/>
  <key>KeepAlive</key>
  <$keep_alive/>
  <key>StandardOutPath</key>
  <string>$stdout_path</string>
  <key>StandardErrorPath</key>
  <string>$stderr_path</string>
EOF

  if [[ "$schedule_kind" == "interval" ]]; then
    cat >>"$destination" <<EOF
  <key>StartInterval</key>
  <integer>$schedule_value</integer>
EOF
  elif [[ "$schedule_kind" == "calendar" ]]; then
    cat >>"$destination" <<EOF
  <key>StartCalendarInterval</key>
  <dict>
    <key>Hour</key>
    <integer>0</integer>
    <key>Minute</key>
    <integer>5</integer>
  </dict>
EOF
  fi

  cat >>"$destination" <<'EOF'
</dict>
</plist>
EOF
}

SCAN_PLIST="$LAUNCH_AGENTS_DIR/com.laoyao.tokstat.scan.plist"
REPORT_PLIST="$LAUNCH_AGENTS_DIR/com.laoyao.tokstat.daily-report.plist"
KAKU_PLIST="$LAUNCH_AGENTS_DIR/com.laoyao.tokstat.kaku-proxy.plist"

write_plist \
  "$SCAN_PLIST" \
  "com.laoyao.tokstat.scan" \
  "$ROOT_DIR/scripts/run_scan.sh" \
  "$LOG_DIR/scan.out.log" \
  "$LOG_DIR/scan.err.log" \
  false \
  true \
  interval \
  3600

write_plist \
  "$REPORT_PLIST" \
  "com.laoyao.tokstat.daily-report" \
  "$ROOT_DIR/scripts/run_daily_report.sh" \
  "$LOG_DIR/report.out.log" \
  "$LOG_DIR/report.err.log" \
  false \
  true \
  calendar \
  0

launchctl unload "$SCAN_PLIST" >/dev/null 2>&1 || true
launchctl unload "$REPORT_PLIST" >/dev/null 2>&1 || true
launchctl load "$SCAN_PLIST"
launchctl load "$REPORT_PLIST"

if [[ "$WITH_KAKU_PROXY" == "1" ]]; then
  if [[ -z "$KAKU_UPSTREAM_BASE_URL" ]]; then
    echo "TOKSTAT_KAKU_UPSTREAM_BASE_URL is required when TOKSTAT_INSTALL_KAKU_PROXY=1" >&2
    exit 1
  fi

  write_plist \
    "$KAKU_PLIST" \
    "com.laoyao.tokstat.kaku-proxy" \
    "$ROOT_DIR/scripts/run_kaku_proxy.sh" \
    "$LOG_DIR/kaku-proxy.out.log" \
    "$LOG_DIR/kaku-proxy.err.log" \
    true \
    true \
    none \
    0

  launchctl unload "$KAKU_PLIST" >/dev/null 2>&1 || true
  launchctl load "$KAKU_PLIST"
fi

echo "Installed launchd jobs:"
echo "  - com.laoyao.tokstat.scan (hourly)"
echo "  - com.laoyao.tokstat.daily-report (00:05 local time)"
if [[ "$WITH_KAKU_PROXY" == "1" ]]; then
  echo "  - com.laoyao.tokstat.kaku-proxy (always on)"
fi

echo
echo "Database: $DB_PATH"
echo "Reports:  $REPORT_DIR"
echo "Logs:     $LOG_DIR"
