---
name: close-issue
description: Use whenever the user asks to merge a PR that closes its driving issue ("close #N", "merge #14", "ship the PR"). Verifies acceptance criteria pass/fail against the diff, confirms the PR auto-closes the issue, waits for green CI (delegated to /check-ci where installed), squash-merges, and cleans up local + remote branch. Invoked as the final step of the /dev orchestrator's composition.
---

# Close issue

Apply these steps whenever invoked to merge a PR that closes its driving issue. The skill verifies acceptance criteria against the diff, confirms the PR auto-closes the issue, waits for green CI (delegated to `/check-ci` where installed), squash-merges, and cleans up the branch.

The `/dev` orchestrator invokes this as its final composed step; humans can also invoke it directly.

## Step 1 — AC-verification gate

Fetch the issue with `gh issue view <number>` and read its **Acceptance criteria** section. Compare each criterion against the PR diff (`git diff main...HEAD`) and the test results.

**List each AC with a pass/fail verdict.** If any AC is **not** covered by the diff, **stop and flag it** — do **not** proceed to merge until the user confirms either:

- the AC is genuinely out of scope and the issue should be updated, or
- the AC needs another pass (loop back to `/tdd`).

This is the single most load-bearing pause at the close end of the workflow.

## Step 2 — verify auto-close link

The PR body must contain `Closes #<issue-number>` (or `Fixes #N` / `Resolves #N`) so the issue auto-closes on merge. If missing, update the PR body with `gh pr edit <pr> --body-file <file>`.

## Step 3 — CI gate

When CI is configured on the target repo, **wait for green checks** before merging.

- If the `check-ci` skill is installed, **delegate** to `/check-ci`. It returns a single verdict: `green` / `failing` / `no-CI-configured`.
- Otherwise, run `gh pr checks` directly. Treat **failing** as a stop (surface the failing-run URLs); treat **no checks reported** as proceed-with-note (the project doesn't have CI set up).

Do **not** proceed to merge on a failing CI verdict. Surface the failures and let the user decide.

## Step 4 — squash-merge

Merge using the **squash and merge** strategy: `gh pr merge <pr> --squash --delete-branch=false`. We delete the branch ourselves in step 7 so the local cleanup is consistent.

## Step 5 — stash any uncommitted changes

Before switching branches, check for uncommitted changes with `git status`. If there are unstaged or staged changes (or untracked files unrelated to the PR), run `git stash --include-untracked` to preserve them. Note this so you can restore them in step 8.

## Step 6 — switch to main and pull

`git checkout main && git pull origin main`.

## Step 7 — clean up the feature branch

- Delete the local branch: `git branch -d <branch>`.
- Delete the remote branch: `git push origin --delete <branch>`.

## Step 8 — restore stashed changes (only if step 5 stashed anything)

`git stash pop`.

## Step 9 — project-board cleanup (when the issue was synced to a project)

If `pickup-issue` synced the issue to "In Progress" on a project board, the issue's GitHub auto-close (from step 4's merge) will close the issue but the project-board status may not transition to "Done" automatically depending on the project's workflow settings. Re-fetch with `gh issue view <number> --json projectItems` — if status is still "In Progress" or similar, transition it to **"Done"** using the same `gh project item-edit` shape as `pickup-issue` step 4.

## Step 10 — report back

Report: PR URL, merge commit SHA, issue number closed, branch deleted (local + remote), AC pass/fail summary from step 1, CI verdict from step 3.
