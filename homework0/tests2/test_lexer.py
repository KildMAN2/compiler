#!/usr/bin/env python3
import os
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
# Keep Path objects for filesystem ops, but maintain string versions for os.* calls (Python 3.5)
BIN_CANDIDATE_PATHS = [ROOT / 'part1', ROOT / 'homework0']
BIN_CANDIDATES = [str(p) for p in BIN_CANDIDATE_PATHS]
INPUT_DIR = Path(__file__).resolve().parent / 'inputs'
EXPECTED_DIR = Path(__file__).resolve().parent / 'expected'


def build():
    # Build only if binary missing; prefer 'part1' as makefile target
    if any(os.path.exists(p) and os.access(p, os.X_OK) for p in BIN_CANDIDATES):
        return
    print('Building with make part1...')
    res = subprocess.run(['make', 'part1'], cwd=str(ROOT), stdout=subprocess.PIPE, stderr=subprocess.PIPE, universal_newlines=True)
    if res.returncode != 0:
        print(res.stdout)
        print(res.stderr, file=sys.stderr)
        raise SystemExit('Build failed')


def find_binary():
    for p in BIN_CANDIDATES:
        if os.path.exists(p) and os.access(p, os.X_OK):
            return p
    return None


def run_lexer_on_text(binary, text: str):
    proc = subprocess.run([binary], input=text, stdout=subprocess.PIPE, stderr=subprocess.PIPE, universal_newlines=True)
    return proc.returncode, proc.stdout, proc.stderr


def run_lexer_on_file(binary, path: Path):
    # Feed via stdin to match assignment spec
    with path.open('r', newline='') as f:
        data = f.read()
    return run_lexer_on_text(binary, data)


def assert_equal(actual: str, expected: str, label: str):
    if actual != expected:
        print('--- FAIL:', label)
        print('Expected:')
        print(repr(expected))
        print('Actual:')
        print(repr(actual))
        return False
    print('PASS  ', label)
    return True


def main():
    build()
    binary = find_binary()
    if not binary:
        raise SystemExit('No lexer binary found (part1 or homework0). Build failed?')

    failures = 0

    # Golden file tests
    for inp in sorted(INPUT_DIR.glob('*.cmm')):
        exp = EXPECTED_DIR / (inp.stem + '.tokens')
        label = inp.name
        rc, out, err = run_lexer_on_file(binary, inp)
        if exp.exists():
            expected = exp.read_text()
            # Check if expected output contains error (should have non-zero exit code)
            if 'Lexical error:' in expected and rc == 0:
                print('--- FAIL: {} expected non-zero exit code for lexical error'.format(label))
                failures += 1
            if not assert_equal(out, expected, label):
                failures += 1
        else:
            print('WARN  {}: no expected file found, skipping compare'.format(label))

    if failures:
        print("\n{} test(s) failed.".format(failures))
        sys.exit(1)
    else:
        print('\nAll tests passed.')


if __name__ == '__main__':
    main()
