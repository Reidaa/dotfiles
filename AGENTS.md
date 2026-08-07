# AGENTS.md

Instructions for AI coding agents working with this codebase

## Coding Guidelines

- Always strive for concise, simple solutions.
- If a problem can be solved in a simpler way, propose it.
- Write comments like the reader is new to the codebase but familiar with the goal of the project.
- Before creating code, brainstorm 3 different approaches to solve the problem and sort them by their probable effectiveness. Then, choose the best approach and implement it.
- Use logging to provide insight into failures. Don't use print for debugging. Don't use logging to hide stack traces.
- Use Test Driven Development (TDD) for all code you write. Write tests before writing the implementation code.

## Commit Guidelines

- Do not commit unless specifically asked to.
- Use Conventional Commits.
- Avoid overly verbose descriptions or unnecessary details.

## CI / GitHub Actions

- Pin every `uses:` to a full **commit SHA** with an exact version comment: `uses: owner/action@<commit-sha> # vX.Y.Z`.
- Resolve to the commit, not the annotated-tag object: take the `refs/tags/vX^{}` line from `git ls-remote --tags`, or `gh api repos/<owner>/<repo>/git/refs/tags/<tag> --jq .object` peeled to a commit. Check with `git cat-file -t <sha>` → `commit`, not `tag`. Never pin a moving major tag (`v9`).

## Autoimprovement

- Suggest to add new rules to AGENTS.md based on user input or PR comments, when a change request could be generalized as a rule.
- Suggest updates to the README.md file according to feature changes or additions

