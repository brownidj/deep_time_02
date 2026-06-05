#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="${1:-.}"
MAX_LINES="${MAX_LINES:-300}"

if ! command -v rg >/dev/null 2>&1; then
  echo "rg (ripgrep) is required." >&2
  exit 1
fi

if [[ ! -d "$ROOT_DIR" ]]; then
  echo "Directory not found: $ROOT_DIR" >&2
  exit 1
fi

violations="$(
  rg --files "$ROOT_DIR" \
    -g '!build/**' \
    -g '!.dart_tool/**' \
    -g '!pubspec.lock' \
    -g '!macos/Flutter/ephemeral/**' \
    -g '!macos/Runner/Base.lproj/**' \
    -g '!macos/Runner.xcodeproj/project.pbxproj' \
    -g '!windows/flutter/ephemeral/**' \
    -g '!**/GeneratedPluginRegistrant.*' \
    -g '!**/generated_plugin_registrant.*' \
    -g '!**/*.g.dart' \
    -g '!**/*.freezed.dart' \
    -g '!data/time_divisions.yaml.bak.20260523_235558' \
    -g '!**/*.yaml' \
    -g '!**/*.yml' \
    -g '!**/*.py' \
    -g '!**/*.md' \
    | while IFS= read -r file; do
      [[ -f "$file" ]] || continue
      if ! file --brief --mime "$file" 2>/dev/null | grep -q 'charset='; then
        continue
      fi
      if file --brief --mime "$file" 2>/dev/null | grep -qi 'charset=binary'; then
        continue
      fi
      line_count="$(wc -l < "$file")"
      if [[ "$line_count" -gt "$MAX_LINES" ]]; then
        printf '%6s %s\n' "$line_count" "$file"
      fi
    done
)"

if [[ -n "$violations" ]]; then
  printf '%s\n' "$violations"
  exit 1
fi

echo "OK: no files above ${MAX_LINES} lines in ${ROOT_DIR}"
