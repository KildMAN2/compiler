#!/bin/bash

# Apply the shared tests bundle into this homework4_final folder and run all tests.
# Usage (Linux/VBox):
#   cd homework4_final
#   bash ./apply_tests_bundle_and_run.sh
#
# Expects: tests_bundle.zip in the current directory.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT_DIR"

ZIP="tests_bundle.zip"

if [ ! -f "$ZIP" ]; then
  echo "Error: missing $ZIP in $ROOT_DIR" >&2
  exit 1
fi

# Extract bundle (overwrites existing files)
if command -v unzip >/dev/null 2>&1; then
  unzip -o "$ZIP" >/dev/null
elif command -v python3 >/dev/null 2>&1; then
  python3 - <<'PY'
import os, zipfile
zip_path = 'tests_bundle.zip'
with zipfile.ZipFile(zip_path) as z:
    z.extractall('.')
print('Extracted', zip_path)
PY
else
  echo "Error: need unzip or python3 to extract $ZIP" >&2
  exit 1
fi

# Ensure scripts are runnable even if extracted with non-exec perms
chmod +x run_all_tests.sh compare_examples_e.sh \
  student_tests/checker.sh student_tests/verify_tests.sh \
  edge_tests/verify_edge_tests.sh error_format_tests/run_error_format_tests.sh \
  2>/dev/null || true

bash ./run_all_tests.sh
