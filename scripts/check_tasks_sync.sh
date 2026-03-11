#!/usr/bin/env bash
#
# CI check: Ensure TASKS.md is in sync with tasks.yaml
#
# Usage:
#   ./scripts/check_tasks_sync.sh
#
# Exit codes:
#   0 - TASKS.md is in sync
#   1 - TASKS.md is out of sync or missing
#

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$ROOT_DIR"

echo "Checking TASKS.md sync status..."
python3 scripts/generate_tasks.py --check

echo "Sync check passed."
