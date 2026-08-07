# AGENTS.md

## Coding Guidelines

- Always strive for concise, simple solutions.
- If a problem can be solved in a simpler way, propose it.
- Write comments like the reader is new to the codebase but familiar with the goal of the project.
- Before creating code, brainstorm 3 different approaches to solve the problem and sort them by their probable effectiveness. Then, choose the best approach and implement it.
- Use logging to provide insight into failures. Don't use print for debugging. Don't use logging to hide stack traces.
- Use Test Driven Development (TDD) for all code you write. Write tests before writing the implementation code.
- Study how established products solve the problem before designing a solution. Adopt their proven patterns and conventions rather than inventing an approach from scratch.
- Choose the simplest implementation that fully meets the current requirements. Avoid speculative abstractions, configuration and indirection.
- Grow the system in layers. Start from the smallest version that works end to end and add each new capability on top of a product that already works. Never trade a working product for unfinished complexity.
- Keep components modular and concerns clearly separated.
- Prefer established, well-maintained libraries when they reduce overall complexity or improve reliability. Do not reimplement common functionality without a clear reason.
- Lean on the dependency already in the project before writing your own implementation or adding packages. Do not assume a library lacks a capability without checking its documentation and types.
- Make architectural decision for the long term. Do not accept a stopgap that only works for now and is meant to be replaced later.

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
