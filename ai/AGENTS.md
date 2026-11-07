# AGENTS.md

- Ask the user before any global install.

- Explain following ASD-STE100
  1. Keep sentences short
  2. One action per step
  3. Say who does what
  4. Give each thing one name and stick to it

- If available, do not hesitate to split tasks between subagents for parallel processing.

## Questions are read-only

- A question is a request for an answer, not for changes.
- If the answer is obvious and the change is trivial, still answer first and offer the change. Ask before making it.

## Coding Guidelines

- **Simplicity**: choose the simplest implementation that fully meets the current requirements. Avoid speculative abstractions, configuration and indirection (YAGNI). If a simpler solution exists, propose it.
- **Comments**: write for a reader new to the codebase but familiar with the project's goal. Above functions and classes, describe concisely how they are used; skip line-by-line comments. Update comments when you change the code.
- **Testing**: use TDD (see the `tdd` skill). Write focused tests; skip smoke tests and "regression tests" for deleted features.
- **Approaches**: for non-trivial design, brainstorm 3 approaches, rank them by probable effectiveness, and implement the best one.
- **Prior art**: study how established products solve the problem and adopt their patterns. Reuse a dependency already in the project, then an established, well-maintained library, before writing your own. Check a library's docs and types before you assume it lacks a capability.
- **Layers**: start from the smallest version that works end to end, and add each capability on top of a working product.
- **Long term**: make architectural decisions for the long term, not stopgaps meant to be replaced later.
- **Logging**: use logging, not print, to give insight into failures. Keep stack traces intact.

## Commit Guidelines

- Commit or push only when the user asks.
- Use Conventional Commits with short messages.

## Autoimprovement

- When a change request generalizes into a rule, add it to the relevant skill, not to AGENTS.md. AGENTS.md stays small and universal. Create a new skill when none fits.
  - Project rules go in the repo's `.agents/skills/`.
  - Personal rules go in the `reidaa/agent-skills` repo, as `reidaa/<name>/SKILL.md`. `npx skills` installs it into `~/.agents/skills/` and overwrites local edits there on update.
- Suggest README.md updates for feature changes or additions.
