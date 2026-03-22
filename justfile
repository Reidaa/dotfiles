default:
    @just --list

fmt:
    shfmt -w -s .

fmt-check:
    shfmt -l -s .

lint:
    shellcheck ./**/*.sh

new cmd:
    cp -r .template/ "{{cmd}}"