default:
    @just --list

fmt:
    shfmt -w -s .
    ruff format .

fmt-check:
    shfmt -l -s .
    ruff format --check .

lint:
    shellcheck ./**/*.sh

new cmd:
    cp -r .template/ "{{cmd}}"