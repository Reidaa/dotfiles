default:
    @just --list

fmt:
    shfmt -w -s .

new cmd:
    cp -r .template/ "{{cmd}}"