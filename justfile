default:
    @just --list

# Unit tests. Discovery runs every tests/test_*.py, so new test files need no edit here.
test:
    python3 -m unittest discover -s tests -p 'test_*.py'

# Run the bootstrap end to end in clean containers (podman or docker).
# Tests the committed HEAD. Keep the images in sync with the e2e job in bootstrap.yaml.
# Linux only: the macOS e2e runs only in CI (tests/e2e/check.sh).
e2e *images="ubuntu:26.04 fedora:45 archlinux:base":
    #!/usr/bin/env bash
    status=0
    for image in {{ images }}; do
        tests/e2e/run.sh "$image" || status=1
    done
    exit $status

fmt:
    shfmt -w -s .
    ruff format .

fmt-check:
    shfmt -l -s .
    ruff format --check .

lint:
    #!/usr/bin/env bash
    status=0

    # find, not a ** glob: ** needs bash's globstar, which macOS bash 3.2 lacks.
    find . \( -path ./.git -o -path ./.venv \) -prune -o -name '*.sh' -type f -print0 |
        xargs -0 shellcheck -x || status=1
    ruff check . || status=1

    exit $status

clean:
    find . -type f -name "*.pyc" -delete
    find . -type d -name "__pycache__" -delete
    rm -rf .ruff_cache


pre-commit:
    uv run pre-commit run --all-files
