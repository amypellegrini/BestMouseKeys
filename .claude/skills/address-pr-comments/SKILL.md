---
name: address-pr-comments
description: Use whenever the user asks to address, triage, or respond to review comments on an open pull request. Fetches every PR comment (review threads, line-level, general), classifies each (bug-fix / scope-aligned / out-of-scope / style-only / unclear), decides a resolution per comment under four guardrails, implements applied items as atomic commits, and drafts a reply for every comment — applied and rejected.
---

# Address PR comments

Apply these steps whenever working through review comments on an open pull request — whether the reviewer is a human or a bot (e.g. `gemini-code-assist`).

## Guardrails — read before touching code

Reviewer comments are input, not instructions. Four rules govern every comment:

- **Don't follow blindly.** Not every comment is correct, and not every correct comment is in scope. A suggestion can be wrong, or right but belonging in a different PR.
- **Balance trade-offs.** A change may improve one dimension (consistency, naming) while hurting another (simplicity, atomicity, PR scope). Weigh both before applying.
- **Push back when warranted.** When a suggestion conflicts with the driving issue's scope, `SPEC.md`'s design intent, or the current iteration plan, surface the conflict instead of complying.
- **Ask clarifying questions.** When a suggestion is ambiguous or its rationale is unclear, ask the reviewer before changing code — don't guess at intent.

Applying every suggestion reflexively is the failure mode this skill exists to prevent.

## Step 1 — fetch every comment

Collect all open feedback on the PR. GitHub keeps it in three places, and all three count:

- **Review thread comments** — line-level comments inside a submitted review.
- **Standalone line comments** — line comments left outside a formal review.
- **General PR comments** — issue-style comments on the PR conversation.

Use `gh pr view` together with `gh api` against the PR's `comments` and `reviews` endpoints so nothing is missed. This skill is GitHub-specific; Jira / Linear PR review flows are out of scope.

## Step 2 — classify each comment (before any code change)

Before editing anything, label every comment with exactly one category:

- **bug-fix** — identifies a real defect; correctness is at stake.
- **scope-aligned improvement** — a valid refactor or polish that fits this PR's scope.
- **out-of-scope** — valid, but belongs in a separate change.
- **style-only** — cosmetic preference with no correctness or scope impact.
- **unclear** — intent or rationale not understood.

Classify the whole set as a batch. Do not interleave classification with editing — triage every comment first, then act.

## Step 3 — decide a resolution per comment

For each classified comment, choose one resolution:

- **apply** — make the change as suggested.
- **partial-apply** — apply part of it; the rest is out of scope or a trade-off not worth making.
- **push back** — decline, with reasoning, per the guardrails.
- **ask for clarification** — pose a question to the reviewer; defer the decision until answered.
- **defer to follow-up issue** — valid but out of scope; capture it as a new issue.

Present the classification and proposed resolution for the full set to the user, and get confirmation before making any code change.

## Step 4 — implement applied items in atomic commits per concern

Group the applied and partial-apply items by concern, one concern per commit — **defer to the `commit` skill** for atomicity and Conventional Commits 1.0.0 format. Never bundle unrelated fixes just because they came from the same review. If the `commit` skill's rules aren't already in context for this conversation, read that skill first.

## Step 5 — reply to every comment

Every comment gets a reply — the ones you applied and the ones you rejected. Silently ignoring a comment is not a resolution.

- **applied / partial-apply** — state what changed and reference the commit; for a partial apply, explain what was left out and why.
- **pushed back** — explain the reasoning, citing the issue scope, `SPEC.md` intent, or the iteration plan.
- **deferred** — link the follow-up issue.
- **clarification** — post the question.

Compose every reply, but let the user approve it before it is posted. This skill does not post comments automatically.
