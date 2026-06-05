#!/usr/bin/env bash
set -euo pipefail

if ! command -v git >/dev/null 2>&1; then
  echo "git is required to install hooks." >&2
  exit 1
fi

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Not inside a git repository. Initialize git first, then rerun." >&2
  exit 1
fi

repo_root="$(git rev-parse --show-toplevel)"
hooks_path="${repo_root}/.githooks"
hook_file="${hooks_path}/pre-commit"

if [[ ! -f "${hook_file}" ]]; then
  echo "Missing hook file: ${hook_file}" >&2
  exit 1
fi

chmod +x "${hook_file}"
git config core.hooksPath .githooks

echo "Installed git hooks from .githooks"
