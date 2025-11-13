#!/usr/bin/env python3
import os
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BIN_CANDIDATES = [ROOT / 'homework0', ROOT / 'part1']
INPUT_DIR = ROOT / 'tests' / 'inputs'
EXPECTED_DIR = ROOT / 'tests' / 'expected'


def build():
    # Build only if binary missing; prefer 'homework0' as makefile target
    if any(p.exists() and os.access(p, os.X_OK) for p in BIN_CANDIDATES):
        return
    print('Building with make part1...')
    res = subprocess.run(['make', 'part1'], cwd=ROOT, capture_output=True, text=True)
    if res.returncode != 0:
        print(res.stdout)
        print(res.stderr, file=sys.stderr)
        raise SystemExit('Build failed')


def find_binary():
    for p in BIN_CANDIDATES:
        if p.exists() and os.access(p, os.X_OK):
            return str(p)
    return None


def run_lexer_on_text(binary, text: str):
    proc = subprocess.run([binary], input=text, text=True, capture_output=True)
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
        raise SystemExit('No lexer binary found (homework0/part1). Build failed?')

    failures = 0

    # Golden file tests
    for inp in sorted(INPUT_DIR.glob('*.cmm')):
        exp = EXPECTED_DIR / (inp.stem + '.tokens')
        label = inp.name
        rc, out, err = run_lexer_on_file(binary, inp)
        if exp.exists():
            expected = exp.read_text()
            if not assert_equal(out, expected, label):
                failures += 1
        else:
            print(f'WARN  {label}: no expected file found, skipping compare')

    # Negative test: 06_error.cmm should produce lexical error and non-zero rc
    err_inp = INPUT_DIR / '06_error.cmm'
    if err_inp.exists():
        rc, out, err = run_lexer_on_file(binary, err_inp)
        if rc == 0:
            print('--- FAIL: 06_error.cmm expected non-zero exit code')
            failures += 1
        # Expect the error line
        needle = "Lexical error: '@' in line number 1"
        if needle not in out:
            print('--- FAIL: 06_error.cmm missing error line')
            print('Output:')
            print(out)
            failures += 1
        else:
            print('PASS  06_error.cmm (error handling)')

    if failures:
        print(f"\n{failures} test(s) failed.")
        sys.exit(1)
    else:
        print('\nAll tests passed.')


if __name__ == '__main__':
    main()
