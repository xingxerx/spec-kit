#!/usr/bin/env bash
set -euo pipefail

# Smoke test for spec-kit
# Usage: ./smoke_test_spec_kit.sh [venv-dir]
# Defaults to .venv-spec-kit-test in the repository root.

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VENV_DIR="${1:-$REPO_ROOT/.venv-spec-kit-test}"
LOG_DIR="$REPO_ROOT/.spec_kit_smoke_logs"
mkdir -p "$LOG_DIR"

echo "Repository: $REPO_ROOT"
echo "Virtualenv: $VENV_DIR"
echo "Logs: $LOG_DIR"

if [ -d "$VENV_DIR" ]; then
  echo "Reusing existing venv at $VENV_DIR"
else
  echo "Creating venv..."
  python3 -m venv "$VENV_DIR"
fi

source "$VENV_DIR/bin/activate"
python -m pip install --upgrade pip setuptools wheel >/dev/null

INSTALL_LOG="$LOG_DIR/pip_install.log"
echo "Installing project and dependencies (editable)..." | tee "$INSTALL_LOG"
pip install -e "$REPO_ROOT" >>"$INSTALL_LOG" 2>&1 || { echo "pip install failed — see $INSTALL_LOG"; exit 2; }

SMOKE_LOG="$LOG_DIR/specify_check.log"
echo "Running: specify check (non-interactive)" | tee "$SMOKE_LOG"
# Run check via module to avoid shell entrypoint differences
python -c "import sys, specify_cli; sys.argv=['specify','check']; specify_cli.main()" >>"$SMOKE_LOG" 2>&1 || RC=$?

echo
echo "=== Smoke Test Summary ==="
echo "Install log: $INSTALL_LOG"
echo "CLI log: $SMOKE_LOG"
if [ -n "${RC-}" ]; then
  echo "specify command exited with code $RC"
  echo "Tail of CLI log:"
  tail -n 120 "$SMOKE_LOG"
  exit $RC
else
  echo "specify check completed successfully"
  tail -n 80 "$SMOKE_LOG"
fi
