# examples_expected

This folder stores the *runtime output* expected from running the example programs in `../examples/`.

## Generate / Update

On Linux (VBox), from `homework4_final/`:

- Generate or refresh expected outputs from the current compiler build:
  - `./check_examples_e.sh --update`

## Verify

- Compare current outputs against the expected files:
  - `./check_examples_e.sh`

By default, the checker compares **program output only** (it strips VM prompts like `Input integer?:` and the VM trailer `Reached Halt.`), matching the behavior used by `student_tests/checker.sh`.

If you want to compare the *full* VM output (prompts + `Reached Halt.`):
- `./check_examples_e.sh --include-vm`
