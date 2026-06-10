---
name: commit-and-push
description: Use whenever the user asks to commit AND push in a single step ("commit and push", "ship it"). Composes the commit skill's rules (atomic commits, Conventional Commits 1.0.0) with a `git push` afterwards. Refuses to push when the commit didn't land, when the branch has no upstream tracking, when the user said "commit only", or when the target is `main` / a protected branch without explicit authorization.
---

# Commit and push

Composes the `commit` skill with a push. Use this only when the user has explicitly asked for both — "commit and push", "ship it", or similar. If the user said only "commit", use the `commit` skill alone.

## Steps

1. Apply the `commit` skill end-to-end. If its rules aren't already in context for this conversation, read them from `.claude/skills/commit/SKILL.md` first.
2. Once the commit has landed successfully, run `git push`.

## Refuse to push when

- The commit failed (pre-commit hook, merge conflict, missing identity, etc.). Surface the error; do not push.
- The local branch has no upstream tracking. Surface the `git push --set-upstream <remote> <branch>` suggestion and let the user authorize before retrying.
- The user said "commit only", "don't push", or similar — use the `commit` skill alone instead.
- The push target is `main` (or another protected branch) AND the user hasn't explicitly authorized pushing to it in this conversation.

## After a successful push

Report the pushed commit hash and the remote ref it landed on. Keep it terse — one line is enough.
