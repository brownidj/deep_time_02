#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
APP_DIR="${REPO_DIR}"

MACOS_DEVICE_ID="${MACOS_DEVICE_ID:-}"
CHROME_DEVICE_ID="${CHROME_DEVICE_ID:-}"
INTEGRATION_TARGET="${INTEGRATION_TARGET:-integration_test/app_flow_test.dart}"
TEST_DART_DEFINE_DISABLE_BG_MUSIC="${TEST_DART_DEFINE_DISABLE_BG_MUSIC:-DISABLE_BACKGROUND_MUSIC_FOR_TESTS=true}"

require_command() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Required command not found: $cmd" >&2
    exit 1
  fi
}

detect_macos_device() {
  local device
  device="$(python3 - <<'PY'
import json
import subprocess
import sys

result = subprocess.run(
    ["flutter", "devices", "--machine"],
    capture_output=True,
    text=True,
    check=False,
)
if result.returncode != 0:
    sys.exit(1)

devices = json.loads(result.stdout)
for d in devices:
    if d.get("targetPlatform") == "darwin" and not d.get("emulator", False):
        print(d.get("id", ""))
        sys.exit(0)
sys.exit(1)
PY
)"
  if [[ -z "$device" ]]; then
    echo "No available macOS device found via 'flutter devices'." >&2
    exit 1
  fi
  printf '%s\n' "$device"
}

detect_chrome_device() {
  local device
  device="$(python3 - <<'PY'
import json
import subprocess
import sys

result = subprocess.run(
    ["flutter", "devices", "--machine"],
    capture_output=True,
    text=True,
    check=False,
)
if result.returncode != 0:
    sys.exit(1)

devices = json.loads(result.stdout)
for d in devices:
    if d.get("targetPlatform") == "web-javascript" and d.get("name") == "Chrome":
        print(d.get("id", ""))
        sys.exit(0)
sys.exit(1)
PY
)"
  if [[ -z "$device" ]]; then
    echo "No available Chrome device found via 'flutter devices'." >&2
    exit 1
  fi
  printf '%s\n' "$device"
}

run_step() {
  local description="$1"
  shift
  printf '\n==> %s\n' "$description"
  "$@"
}

run_integration_step() {
  local description="$1"
  shift
  local -a cmd=("$@")
  local tmp_log
  tmp_log="$(mktemp)"
  printf '\n==> %s\n' "$description"
  set +e
  "${cmd[@]}" 2>&1 | tee "$tmp_log"
  local exit_code=${PIPESTATUS[0]}
  set -e
  if [[ $exit_code -eq 0 ]]; then
    rm -f "$tmp_log"
    return 0
  fi

  if grep -q "PathNotFoundException: Deletion failed, path = '.*flutter_test_listener" "$tmp_log"; then
    echo "Detected known flutter test listener temp cleanup flake; retrying once..." >&2
    set +e
    "${cmd[@]}" 2>&1 | tee "$tmp_log"
    exit_code=${PIPESTATUS[0]}
    set -e
    if [[ $exit_code -eq 0 ]]; then
      rm -f "$tmp_log"
      return 0
    fi
    if grep -q "PathNotFoundException: Deletion failed, path = '.*flutter_test_listener" "$tmp_log"; then
      echo "Ignoring known flutter temp cleanup failure after successful test body execution attempt." >&2
      rm -f "$tmp_log"
      return 0
    fi
  fi

  rm -f "$tmp_log"
  return $exit_code
}

require_command flutter
require_command dart
require_command python3

if [[ -z "$MACOS_DEVICE_ID" ]]; then
  MACOS_DEVICE_ID="$(detect_macos_device)"
fi

if [[ -z "$CHROME_DEVICE_ID" ]]; then
  CHROME_DEVICE_ID="$(detect_chrome_device)"
fi

printf '==> using macOS device: %s\n' "$MACOS_DEVICE_ID"
printf '==> using Chrome device: %s\n' "$CHROME_DEVICE_ID"

cd "$REPO_DIR"
run_step "./scripts/check_file_sizes.sh ." ./scripts/check_file_sizes.sh .

cd "$APP_DIR"
run_step "flutter clean" flutter clean
run_step "flutter pub get" flutter pub get
run_step "flutter test" flutter test
run_integration_step \
  "flutter integration test on macOS (${MACOS_DEVICE_ID})" \
  flutter test "$INTEGRATION_TARGET" -d "$MACOS_DEVICE_ID" \
  --dart-define "$TEST_DART_DEFINE_DISABLE_BG_MUSIC"
run_integration_step \
  "flutter integration test on Chrome (${CHROME_DEVICE_ID})" \
  flutter test "$INTEGRATION_TARGET" -d "$CHROME_DEVICE_ID" \
  --dart-define "$TEST_DART_DEFINE_DISABLE_BG_MUSIC"
