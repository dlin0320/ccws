# End-Task Flow - Commit, Push, Open PR

> **Execution:** Run inline in the main context.

Finalize the task: commit deliverable changes, push the branch, open a pull request. Task directory cleanup (and any worktree removal) is handled separately by `cleanup-task` after the PR merges.

## Purpose
Close out the work-producing phase of the task cycle. Commits capture deliverable changes, the PR enables external review and merge, and the task dir remains so `triage-pr-review` and `reconcile-task` can operate on external PR feedback until the change lands. `cleanup-task` runs post-merge to tear everything down.

## Outcome (Required)
- [ ] Git commit(s) created for any deliverable changes
- [ ] Branch pushed to origin
- [ ] Pull request opened with SUMMARY.md as body (if available) or a README-derived summary
- [ ] User knows the PR URL and what's pending post-merge

## Constraints (REQUIRED)
- MUST NOT delete task directory (cleanup happens post-merge, outside end-task)
- MUST NOT delete or move archive files
- MUST NOT force-push unless the user explicitly authorizes it
- MUST use `gh pr create` rather than manually constructing a URL
- Runs on whatever working tree is currently checked out — main repo (default) or a user-created worktree

## Process

### 1. Verify Task Context

```bash
branch=$(git rev-parse --abbrev-ref HEAD)
task_name="${branch//\//-}"
main_repo=$(git rev-parse --show-toplevel)
workspace="$main_repo/.claude-workspace"
task_dir="$workspace/task/$task_name"
```

If `$task_dir` doesn't exist: "No matching task for branch `$branch` (expected `task/$task_name/`). Was prep-task run?"

If `$branch` is the main/default branch (e.g., `main`, `master`): "Refusing to end-task on the main branch. Create a feature branch first."

### 2. Check for Unresolved Findings

If `FEEDBACK.md` exists in the task dir, scan for unresolved actionable findings:
- Count findings with category `DIVERGENCE`, `UNDOCUMENTED`, or `MISSING`
- Exclude `DOCUMENTED` (resolved), `STUB` (intentionally deferred), `EXTRA` (informational)
- Check if a reconcile progress note in the README post-dates FEEDBACK.md

If unresolved findings exist AND no post-FEEDBACK.md reconcile note:
```
⚠ FEEDBACK.md contains N unresolved findings:
  - X DIVERGENCE (contradicts spec)
  - Y UNDOCUMENTED (missing rationale)
  - Z MISSING (not yet implemented)
Consider running reconcile-task before ending. Proceed anyway? (yes/no)
```
If no: stop and suggest running reconcile-task.
If yes: proceed.

If `FEEDBACK.md` does not exist: proceed silently (review was never run, valid for simple tasks).

### 3. Check for Deliverable Changes

```bash
git status
```

- **Uncommitted changes** → Step 4 (create commits)
- **Clean tree but unpushed commits on the branch** → skip to Step 5 (push)
- **Clean tree and no unpushed commits** → "Nothing to finalize." Exit — no PR needed.

### 4. Create Commits

Avoid bloated unified commits. **One commit per logical unit** when changes separate cleanly.

#### 4a. Determine Strategy

Read context sources in priority order:
1. **SUMMARY.md** (if exists) — "Files Changed" section groups changes by logical component
2. **README progress notes** — each implement/reconcile progress note = one logical unit
3. **git diff** — ground truth

**If changes separate cleanly** (different files per unit): one commit per unit.
**If changes are interleaved** (same files across units): one structured commit.

#### 4b. Write Commits

For each logical unit (or single commit if interleaved):

```bash
git add [relevant deliverables]
git commit -m "$(cat <<'EOF'
{type}: {concise summary of this unit}

{Body from SUMMARY.md section or progress note}
{Key decisions if relevant}

Task: {branch}
EOF
)"
```

The subject uses the branch's conventional-commit prefix (`feat:`, `fix:`, `refactor:`, etc.) derived from the branch name.

**Commit message sources:**
- **If SUMMARY.md exists:** subject from Objective, body from "What Was Built" sections, key decisions noted
- **If no SUMMARY.md:** fall back to README objective + progress notes

### 5. Push Branch

```bash
git push -u origin "$branch"
```

If push fails because the remote has new commits the local branch doesn't have: fetch, rebase onto `origin/$branch`, resolve any conflicts, then retry. **Do NOT force-push** unless the user explicitly authorizes it for this branch.

If push fails because the branch has no upstream configured: the `-u` flag handles it. If the remote rejects due to protected-branch rules, surface the error and stop.

### 6. Open Pull Request

Derive title and body from available context:

- **Title:** `{type}: {name-as-sentence}`. E.g., branch `feat/auth-refresh` → `feat: auth refresh`.
- **Base branch:** the project's main branch (detect: `main` or `master`; respect `gh` default if configured).
- **Body:**
  - Prefer `$task_dir/SUMMARY.md` if it exists (run summarize-task first for best results).
  - Otherwise construct from README Objective + Progress Notes.

```bash
base=$(gh repo view --json defaultBranchRef -q .defaultBranchRef.name 2>/dev/null || echo main)

if [ -f "$task_dir/SUMMARY.md" ]; then
  gh pr create --base "$base" --head "$branch" \
    --title "{type}: {name-as-sentence}" \
    --body-file "$task_dir/SUMMARY.md"
else
  gh pr create --base "$base" --head "$branch" \
    --title "{type}: {name-as-sentence}" \
    --body "$(cat <<'EOF'
## Summary
{Objective from README}

## Changes
{Progress notes from README, bulletized}

## Test plan
- [ ] {items}
EOF
)"
fi
```

If `gh pr create` fails (auth missing, no remote, etc.): print the error and the full command so the user can run it manually. Capture the PR URL from a successful run.

### 7. Confirm Completion

```
✓ Task "{branch}" finalized
✓ Commits pushed: {N} to origin/{branch}
✓ PR opened: {url}

Next:
  - If the PR gets an automated review (e.g., claude bot), run triage-pr-review
    to ingest findings into FEEDBACK.md, then reconcile-task to resolve them.
  - After the PR merges, run cleanup-task to delete the task dir (and remove
    the worktree, if you created one). The local branch is kept by default;
    add --delete-branch to tear it down too.
```

## Guidance

**When to end a task:**
- Success criteria from README are met
- Reconcile has run (or the user accepts unresolved findings)
- Work is ready for external review

**If work isn't done yet:**
Use checkpoint-task to save progress — keeps the task active and doesn't open a PR.

**Draft PRs:**
If the user wants an early-feedback draft, add `--draft` to `gh pr create`. Otherwise default to ready-for-review.

**PR body vs SUMMARY.md:**
SUMMARY.md is the authoritative PR body. If absent, end-task falls back to README, but running summarize-task first yields a significantly better PR description.

**Cleanup is separate:**
Task dir deletion (and worktree removal, if one exists) happens **after** the PR merges, via `cleanup-task`. end-task leaves the task dir in place so the user can reference it during external review and so `triage-pr-review` has somewhere to write FEEDBACK.md.

**Worktree mode:**
If the user created a worktree manually, end-task still commits, pushes, and opens the PR the same way — it operates on the current working tree, whatever it is. `cleanup-task` will detect and remove the worktree post-merge.

**No remote:**
If the project has no git remote, end-task skips Step 5 and 6 entirely. It commits locally and notes that push + PR must be done manually once a remote exists.
