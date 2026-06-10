---
name: qa-test
description: Use whenever the user asks to QA-test or verify a feature that's being worked, by issue number or feature reference — `qa-test #N`. Locates and checks out the feature branch (refusing to clobber uncommitted work, never testing main or a fabricated branch), fetches the issue, builds a test plan covering every acceptance criterion with happy-path, edge, and negative scenarios, posts the plan to the issue, runs the feature to execute the plan, and posts the final assessment to both the issue and the PR with a close-or-address-gaps recommendation. Dynamic verification, but strictly read-only on the code under test — failing scenarios are recorded as gaps, never fixed (that's /dev). Posts the test plan and assessment autonomously without per-action confirmation; they're the skill's deliverable.
---

# QA test a feature

Verify a feature that's being worked, end-to-end, against the acceptance criteria of its driving issue. Given an issue number (or a feature reference), locate and check out the feature branch, fetch the issue, build a test plan that covers every AC — including edge cases and negative scenarios — post the plan to the issue, execute it against the running feature, and post a final assessment to the PR with a clear recommendation to **close** or **address gaps**.

This is **dynamic verification**, not a static assessment. You will run the feature. But you remain QA, not DEV: **never modify the code under test to make a scenario pass.** A failing scenario is a recorded gap, not something you fix — recommending the fix is QA; applying it is `/dev`.

## Inputs

`qa-test [ISSUE NUMBER OR FEATURE]`:

- An **issue reference** — `#N`, a bare number (GitHub), or a Jira key (`PROJ-123`). The primary path.
- A **feature reference** — free text describing the feature. Resolve it to an issue and/or branch (search the tracker, scan branch names). If it maps to more than one candidate, **ask via AskUserQuestion** — do not guess.

If you can't resolve the input to a concrete issue, stop and ask.

## 1. Locate the feature branch

You can't test a feature that isn't on a branch yet. Find the branch for the issue, in order:

- The PR that closes the issue: `gh pr list --state open --search "<issue ref>"` (or look for `Closes #N` in PR bodies). Its head branch is the target.
- A local/remote branch whose name encodes the issue number (`git branch -a` / `git branch --list "*<N>*"`). `pickup-issue` names branches with the issue number, so match on it.

If you find more than one candidate branch, surface them and **ask** which to test.

**If no branch exists:** stop and surface it. There is nothing to verify — the feature isn't in progress. Recommend the user confirm the issue is actually being worked (or run `/dev #N` to start it). Do not fabricate a branch or test `main`.

## 2. Check out the branch safely

- **Refuse to clobber uncommitted work.** Run `git status --porcelain`; if the working tree is dirty, stop and surface it — let the user stash or commit first. Never discard their changes to switch branches.
- Record the current branch so you can offer to return to it at the end.
- `git fetch` the remote, then `git checkout <branch>` and bring it up to date (`git pull --ff-only` on the tracking branch). If the fast-forward fails (diverged), surface it rather than forcing.

This is a working-tree state change — note it in your report and offer to switch back when done.

## 3. Fetch the issue details

- GitHub: `gh issue view <N>` (title, body, labels). Jira: `acli` equivalent.
- Parse the structured sections the repo's checklist uses: **Context**, **Scope**, **Acceptance criteria**, **Out of scope**, **Manual verification**, **Dependencies**.

**Issue-quality gate.** If the issue has no acceptance criteria, or they're too thin to derive concrete scenarios, you can't build a meaningful test plan. Stop and surface it; offer to proceed by deriving *provisional* ACs from the Scope section (clearly marked as provisional in the plan), or to pause for a BA refinement pass (`/business-analyst #N`). Don't invent ACs silently.

## 4. Build the test plan

This is the QA value-add — do it well. For **each acceptance criterion**, derive concrete, executable scenarios across three categories:

- **Happy path** — the AC working as specified, with representative inputs.
- **Edge cases** — boundaries and corners: empty/zero/max inputs, missing optional data, first-run vs. repeat-run, concurrent or out-of-order operations, unusual-but-valid states.
- **Negative scenarios** — invalid input, missing prerequisites, permission/auth failures, conflicting state. Assert the feature *fails safely and informatively*, not just that the happy path works.

Also:

- Fold in any **Manual verification** steps the issue lists.
- Treat **Out of scope** items as explicit non-goals — do not test them, and note them as deliberately excluded so the plan's coverage is honest.

Structure each scenario as: a short title, the steps to run it, and the expected result. Group scenarios under the AC they cover, and mark which category (happy / edge / negative) each is.

## 5. Post the test plan to the issue

Post the plan as a comment on the driving issue. Do **not** pause for approval — posting is the skill's deliverable; the user invoked you to produce these artifacts.

- GitHub: `gh issue comment <N> --body <plan>`. Jira: `acli` equivalent.
- Lead the comment with a clear marker (e.g. `## QA test plan — <date>`) so it's distinguishable from discussion.

Show the plan in the conversation as you post it so the user has it in the transcript, and capture the comment URL for your final report.

## 6. Execute the test plan

Now run the feature. Discover how this project is exercised — don't assume:

- Build if needed (`npm run build`, `cargo build`, etc.), then run the app/CLI/service as a user would.
- Execute each scenario from §4. For each, record a verdict: **pass** / **fail** / **blocked** (couldn't run — note why), with *observed* vs *expected*.
- For UI/visual features, drive the actual interface where possible; if you can't (no browser, headless limits), say so explicitly and mark those scenarios **blocked** rather than claiming a pass.

**Hard constraint:** if a scenario fails, **do not edit the feature's source, tests, or config to make it pass.** Record the failure as a gap with enough detail for DEV to act (steps, observed behaviour, which AC it violates). Modifying the code under test is the line between QA and DEV; crossing it invalidates the verification.

## 7. Produce the assessment and recommendation

Summarise:

- **AC coverage** — each AC with an overall pass/fail, backed by its scenarios.
- **Scenario results** — counts by category (happy / edge / negative) and by verdict (pass / fail / blocked).
- **Gaps** — every failing or blocked scenario, with observed vs expected and the AC it maps to.

Then a single, unambiguous **recommendation**:

- **Close / ship it** — every AC passes, edge and negative coverage holds, no blocking gaps.
- **Address gaps** — one or more ACs fail or critical scenarios are blocked. List exactly what must be fixed, mapped to ACs, so DEV can act without re-deriving the plan.

## 8. Post the assessment to the issue and the PR

The assessment closes the loop on the test plan from §5. It goes to **both** surfaces: the issue (so the driving artifact carries the full QA verdict and history) and the PR (so the reviewer sees it in review context). Do not pause for approval.

- **Always post to the issue:** `gh issue comment <N> --body <assessment>`. Lead with a marker (e.g. `## QA verification — <date> — recommendation: <close | address gaps>`).
- **Find the PR for the branch:** `gh pr list --head <branch> --state open`. If a PR exists, post the same assessment there: `gh pr comment <PR> --body <assessment>`. If no PR exists yet, note it in your final report — the issue comment alone carries the assessment.

Show the assessment in the conversation as you post it, and capture both comment URLs for your report.

## 9. Clean up and report

- Return to the branch you started on (from §2) — don't leave the user on a checked-out feature branch they didn't ask to be on.
- Report back: the issue and branch tested, the test-plan comment URL, the assessment comment URLs (issue + PR if it exists), the headline verdict (close vs. address gaps), and the gap list. Be honest about any scenarios marked **blocked** and why — a verification that quietly skipped half its scenarios is worse than none.

## Out of scope (do not do these)

- **Don't fix the feature.** No edits to source, tests, or config to make scenarios pass — record gaps and recommend.
- **Don't test `main` or a fabricated branch.** No branch ⇒ stop and surface.
- **Don't clobber uncommitted work** to switch branches.
- **Don't test out-of-scope items**, and don't invent ACs the issue doesn't state (mark provisional ACs as such if the user opts in).
- **Don't merge, close, or transition the issue/PR.** Recommending closure is QA; the merge/close is a DEV move (`close-issue`).
