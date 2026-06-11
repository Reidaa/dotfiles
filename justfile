i:
    uv tool install ruff
    go install mvdan.cc/sh/v3/cmd/shfmt@latest

default:
    @just --list

fmt:
    shfmt -w -s .
    ruff format .

fmt-check:
    shfmt -l -s .
    ruff format --check .

lint:
    shellcheck -x ./**/*.sh

new cmd:
    cp -r .template/ "{{cmd}}"
