default:
    @just --list

test:
    python3 .template/test_install_package.py

fmt:
    shfmt -w -s .
    ruff format .

fmt-check:
    shfmt -l -s .
    ruff format --check .

lint:
    #!/usr/bin/env bash
    status=0

    shellcheck -x ./**/*.sh || status=1
    ruff check . || status=1

    exit $status

clean:
    find . -type f -name "*.pyc" -delete
    find . -type d -name "__pycache__" -delete
    rm -rf dist build .egg-info .ruff_cache


pre-commit:
    uv run pre-commit run --all-files
