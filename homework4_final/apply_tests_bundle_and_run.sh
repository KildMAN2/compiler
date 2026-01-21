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

# Extract bundle (overwrites existing files).
# IMPORTANT: this ZIP may be created on Windows and contain backslashes in entry
# names; unzip warns and may not lay out directories correctly. Prefer python3
# extraction that normalizes path separators.
if command -v python3 >/dev/null 2>&1; then
  python3 - <<'PY'
import os
import zipfile

zip_path = 'tests_bundle.zip'

def safe_relpath(name: str) -> str:
    # Normalize Windows separators to POSIX.
    name = name.replace('\\', '/')
    # Remove drive letters just in case.
    if len(name) >= 2 and name[1] == ':':
        name = name[2:]
    name = name.lstrip('/').strip()
    # Normalize and block path traversal.
    norm = os.path.normpath(name)
    if norm.startswith('..') or os.path.isabs(norm):
        raise ValueError(f"unsafe path in zip: {name}")
    return norm

with zipfile.ZipFile(zip_path) as z:
    for info in z.infolist():
        # Skip directory entries.
        if info.is_dir():
            continue
        rel = safe_relpath(info.filename)
        if not rel:
            continue
        os.makedirs(os.path.dirname(rel) or '.', exist_ok=True)
        with z.open(info, 'r') as src, open(rel, 'wb') as dst:
            dst.write(src.read())

print('Extracted', zip_path)
PY
elif command -v unzip >/dev/null 2>&1; then
  # Fallback: unzip. (May warn about backslashes but we attempt anyway.)
  unzip -o "$ZIP"
else
  echo "Error: need python3 (preferred) or unzip to extract $ZIP" >&2
  exit 1
fi

# Ensure scripts are runnable even if extracted with non-exec perms
chmod +x run_all_tests.sh compare_examples_e.sh \
  student_tests/checker.sh student_tests/verify_tests.sh \
  edge_tests/verify_edge_tests.sh error_format_tests/run_error_format_tests.sh \
  2>/dev/null || true

bash ./run_all_tests.sh
