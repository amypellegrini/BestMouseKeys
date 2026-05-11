---
name: commit
description: Use whenever creating a git commit in this repo. Enforces atomic commits (one concern per commit) and Conventional Commits 1.0.0 format for the subject line, with guidance on body content and recovery from common mistakes.
---

# Commit conventions

Apply these rules whenever creating a git commit.

## Atomic commits

One concern per commit. If the staged changes mix concerns — scaffolding + behavior, refactor + feature, two unrelated fixes, docs + code — unstage and split before committing.

- Inspect what's staged before writing a message: `git diff --cached --stat`. Group files by what they change; if there's more than one group, split.
- Mixed staging recovery: `git restore --staged <paths>` to unstage, then re-`git add` by concern and commit each group separately.
- A failing pre-commit hook means the commit did *not* land. Fix the underlying issue, re-stage, and create a NEW commit. Do not `git commit --amend` after a failed hook — that modifies the *previous* commit and can destroy work.

## Conventional Commits 1.0.0

Format: `<type>[optional scope]: <subject>`

Spec: <https://www.conventionalcommits.org/en/v1.0.0/>

### Types in use here

| Type | When to use |
|---|---|
| `feat` | New user-visible capability |
| `fix` | Bug fix |
| `chore` | Maintenance, tooling, deps; no production behavior change |
| `docs` | Documentation only (`README`, `SPEC`, `CLAUDE.md`, skills) |
| `test` | Tests only |
| `refactor` | Internal restructure with no behavior change |
| `build` | Build system, package config (`tsconfig.json`, `package.json` deps) |
| `ci` | CI pipeline only |

### Subject line

- Imperative mood: "add", not "added" / "adds" / "adding".
- Lower-case after the colon.
- ≤72 characters.
- No trailing period.

### Body (when needed)

- Explain *why*, not *what* — the diff already shows what.
- Wrap at ~72 columns.
- Reference the iteration, design doc, or constraint that motivated the change only when it isn't obvious from context.

## Examples

Good:

- `feat: add tw-ai doctor subcommand`
- `fix: handle missing package.json in version banner`
- `docs: clarify the three-step setup in SPEC`
- `test: add smoke test for built binary`
- `chore(deps): bump typescript to 5.7`

Bad — and why:

- `Updates` — no type, vague subject.
- `feat: Added new feature` — past tense, capitalized after colon, vague.
- `fix bug` — no colon, no useful subject.
- `chore: tweaks and fixes` — non-atomic ("and" usually signals two concerns).
