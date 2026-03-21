default:
    @just --list

fmt:
    shfmt -w -s .

lint:
    shellcheck ./**/*.sh

new cmd:
    cp -r .template/ "{{cmd}}"