#!/bin/bash

# Verify a submission .tar.bz2 by extracting it into a temp folder,
# building rx-cc there, and running the full test runner.
#
# Usage (VBox/Linux):
#   cd homework4_final
#   bash ./verify_submission_archive_and_run_tests.sh proj-part3-....tar.bz2
#
# Notes:
# - The submission archive typically contains ONLY source files.
# - This script copies the local test runner + tools (rx-linker/rx-vm/runtime)
#   into the temp folder for verification.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [ "$#" -ne 1 ]; then
  echo "Usage: bash ./verify_submission_archive_and_run_tests.sh <proj-part3-...tar.bz2>" >&2
  exit 2
fi

ARCHIVE="$1"
if [ ! -f "$ARCHIVE" ]; then
  echo "Error: archive not found: $ARCHIVE" >&2
  exit 1
fi

TMP_DIR="$ROOT_DIR/_verify_submission_tmp"
rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"

# Extract submission sources
# (GNU tar on Linux supports -j for bzip2)
tar -xjf "$ARCHIVE" -C "$TMP_DIR"

# Copy local tools + tests needed for running run_all_tests.sh
copy_if_exists() {
  local src="$1"
  if [ -e "$ROOT_DIR/$src" ]; then
    cp -a "$ROOT_DIR/$src" "$TMP_DIR/"
  fi
}

copy_if_exists "rx-linker"
copy_if_exists "rx-vm"
copy_if_exists "rx-runtime.rsk"
copy_if_exists "run_all_tests.sh"
copy_if_exists "compare_examples_e.sh"
copy_if_exists "student_tests"
copy_if_exists "edge_tests"
copy_if_exists "error_format_tests"
copy_if_exists "examples"
copy_if_exists "examples_reference"

# Ensure scripts are runnable even if permissions were lost
chmod +x "$TMP_DIR"/*.sh 2>/dev/null || true
chmod +x "$TMP_DIR"/student_tests/*.sh 2>/dev/null || true
chmod +x "$TMP_DIR"/edge_tests/*.sh 2>/dev/null || true
chmod +x "$TMP_DIR"/error_format_tests/*.sh 2>/dev/null || true

# Build and run tests in the temp folder
(
  cd "$TMP_DIR"
  make clean >/dev/null 2>&1 || true
  make
  bash ./run_all_tests.sh
)

echo "OK: archive builds and all tests passed in $TMP_DIR"