# Cleanup-Task Flow - Post-Merge Teardown

> **Execution:** Run inline in the main context.

Tear down a task whose PR has merged: delete the task directory and remove any worktree the user created for this task. The local branch and remote-tracking refs are kept by default (for reference, cherry-picks, or just paranoia); `--delete-branch` opts in to full branch teardown.

## Purpose
Separate the destructive cleanup phase from `end-task` (which opens the PR). Cleanup waits on an external event — the PR merging — and has different preconditions than everything upstream of it. Splitting the two makes those preconditions explicit rather than hidden inside conditional branches.

## Outcome (Required)
- [ ] PR is verified as merged (or user has explicitly overridden)
- [ ] If a worktree exists for the branch, it's removed from disk and from `git worktree list`
- [ ] Task directory `task/{task-name}/` is deleted; archive files it symlinked are untouched
- [ ] Local branch + remote-tracking refs preserved by default; deleted only when `--delete-branch` is passed
- [ ] User sees a final summary of what was removed and what was kept

## Constraints (REQUIRED)
- MUST verify the PR is merged before destructive actions (`--force` is the only override, and it requires explicit user confirmation)
- MUST refuse if a worktree exists for the branch and has uncommitted or unpushed changes (checked before `git worktree remove`)
- MUST NOT run from inside the worktree being removed (git forbids it; this flow detects and instructs)
- MUST NOT delete or move archive files — only symlinks inside the task dir
- MUST NOT delete the local branch unless `--delete-branch` is passed
- MUST NOT force-delete the local branch without explicit user confirmation when `git branch -d` refuses (e.g., squash-merged branches); only applies under `--delete-branch`
- Operates on the active task's branch by default; `--branch <name>` allows targeting another already-ended task

## Modes

- **Default**: verify PR merged, remove worktree (if any), delete task dir, keep local branch + remote-tracking refs
- `--force`: skip the merged-PR check (useful if the PR was closed without merging and the user has decided to abandon the branch cleanly)
- `--dry-run`: print what would be removed without touching anything
- `--branch <name>`: target a specific task branch instead of the current one
- `--delete-branch`: also delete the local branch and prune its remote-tracking ref. Adds preconditions: not currently on the branch, no unpushed commits on it.

## Process

### 1. Resolve Target Task

```bash
main_repo=$(git rev-parse --show-toplevel 2>/dev/null || git -C . rev-parse --show-toplevel)

# Target branch: explicit or current
if [ -n "$arg_branch" ]; then
  branch="$arg_branch"
else
  branch=$(git rev-parse --abbrev-ref HEAD)
fi

task_name="${branch//\//-}"
task_dir="$main_repo/.claude-workspace/task/$task_name"
```

If `$branch` is the main/default branch: "Refusing to clean up the main branch." Exit.

If `$task_dir` doesn't exist: "No task directory for `$branch` (expected `task/$task_name/`). Nothing to clean up here." If a worktree still exists for the branch, offer to remove just that.

Find the worktree path from git's own records (don't reconstruct from conventions — worktrees can move):

```bash
worktree_path=$(git -C "$main_repo" worktree list --porcelain \
  | awk -v b="refs/heads/$branch" '$1=="worktree"{w=$2} $1=="branch" && $2==b {print w}')
```

### 2. Refuse If Running Inside the Target Worktree

```bash
cwd=$(pwd -P)
if [ -n "$worktree_path" ] && [ "$cwd" = "$(cd "$worktree_path" && pwd -P)" ]; then
  # Inside the worktree we're about to remove — git will refuse and the shell will lose its CWD
  echo "Cannot remove worktree while inside it. Run: cd $main_repo  (then re-invoke cleanup-task)"
  exit
fi
```

### 3. Verify PR State

```bash
pr_json=$(gh pr list --head "$branch" --state all --json number,state,mergedAt,url --limit 1)
```

Parse `state`:
- `MERGED` → proceed
- `OPEN` → "PR #N is still open. Run cleanup-task after it merges, or pass `--force` to clean up anyway." Exit unless `--force`.
- `CLOSED` (not merged) → "PR #N was closed without merging. Pass `--force` to discard the branch, or reopen/refile the PR." Exit unless `--force`.
- no PR found → "No PR found for `$branch`. Pass `--force` if you intend to discard the branch without a PR." Exit unless `--force`.

If `--force` was used: require explicit confirmation:

```
⚠ --force: cleaning up without a merged PR.
  Branch: {branch}
  PR state: {OPEN | CLOSED | none}
  This will remove the worktree (if any) and delete the task dir.
  {" The local branch will also be deleted." — only if --delete-branch}
Type the branch name to confirm: _
```

### 4. Verify Clean State

**If a worktree exists** (`$worktree_path` non-empty): `git worktree remove` requires a clean tree, so check:

```bash
dirty=$(git -C "$worktree_path" status --porcelain)
unpushed=$(git -C "$worktree_path" log "@{u}..HEAD" --oneline 2>/dev/null)
```

- If `dirty` is non-empty → "Worktree has uncommitted changes on `$branch`. Commit or stash them, then re-run." Exit unless `--force`.
- If `unpushed` is non-empty AND `--delete-branch` → "Unpushed commits on `$branch` would be lost when the branch is deleted. Push them, or drop `--delete-branch`." Exit unless `--force`.
- If `unpushed` is non-empty but no `--delete-branch`: just note it in the summary — the branch is being kept, so the commits aren't lost.

**If `--delete-branch` is passed and no worktree exists:**

```bash
current_branch=$(git -C "$main_repo" rev-parse --abbrev-ref HEAD)
if [ "$current_branch" = "$branch" ]; then
  echo "Refusing to delete the currently-checked-out branch. Switch to another branch first:"
  echo "  git -C $main_repo checkout {main-branch}"
  exit  # unless --force, and even then only after user confirms
fi

unpushed=$(git -C "$main_repo" log "$branch@{u}..$branch" --oneline 2>/dev/null)
```

- If `unpushed` non-empty → "Unpushed commits on `$branch`. Push them, or use `--force` to discard." Exit unless `--force`.

**Default path (no worktree, no `--delete-branch`):** nothing to verify — we're only deleting the task dir, which contains metadata (README + symlinks + task management files), not deliverables.

### 5. Check for Dependents

Before deleting the task dir, check whether other active tasks symlink into things this task created. Archive files are shared and should never be deleted here, but it's worth warning the user if another task's symlinks resolve through this one (rare, but possible with stacked work):

```bash
# Any symlinks under task/ pointing inside the to-be-removed task dir?
find "$main_repo/.claude-workspace/task" -type l \
  -lname "*task/$task_name/*" 2>/dev/null
```

If any found: list them and ask whether to proceed. These symlinks will dangle after cleanup.

### 6. Present Plan and Confirm

```
Cleanup plan for {branch}:
  ✓ PR #{N} merged at {timestamp} — {url}
  {→ remove worktree:   {worktree_path}            (only if a worktree exists)}
  → delete task dir:   .claude-workspace/task/{task-name}/
  {→ delete branch:     {branch} (local) + prune origin/{branch}   (only if --delete-branch)}
  → keep branch:       {branch}                                    (default — omit if --delete-branch)
  {dependent warnings, if any}

Proceed? (yes/no)
```

If `--dry-run`: print the plan and exit here.

### 7. Execute

Order matters — worktree removal must precede any branch deletion.

```bash
# 7a. Remove worktree (if one exists)
if [ -n "$worktree_path" ] && [ -d "$worktree_path" ]; then
  git -C "$main_repo" worktree remove "$worktree_path"
  # If git refuses (submodules, locked worktree), fall back to:
  #   git -C "$main_repo" worktree remove --force "$worktree_path"
  # only with explicit user confirmation.
fi
```

```bash
# 7b. Delete task directory (symlinks only — archive files are untouched)
rm -rf "$task_dir"
```

Verify: `ls "$main_repo/.claude-workspace/archive/"` should show archive contents intact.

```bash
# 7c. Delete local branch — ONLY if --delete-branch was passed
if [ -n "$arg_delete_branch" ]; then
  if ! git -C "$main_repo" branch -d "$branch" 2>/dev/null; then
    # -d refused. Common when the PR was squash/rebase-merged — git doesn't see the branch as merged.
    echo "git branch -d refused (likely squash/rebase merge). Force delete? (yes/no)"
    # On yes: git -C "$main_repo" branch -D "$branch"
  fi

  # 7d. Prune the remote-tracking ref for this branch specifically
  git -C "$main_repo" update-ref -d "refs/remotes/origin/$branch" 2>/dev/null || true
fi
```

**Default path does NOT touch the branch or remote-tracking refs.** The branch stays checked-out-able, `git log $branch` still works, and `origin/$branch` remains until the user chooses to prune (manually or with `--delete-branch` on a later `cleanup-task` run).

### 8. Confirm Completion

```
✓ Cleanup complete for {branch}
  {✓ Worktree removed:  {worktree_path}              (line omitted if no worktree existed)}
  ✓ Task dir deleted:  task/{task-name}/
  ✓ Local branch:      kept                          (default)   | deleted   (--delete-branch)
  ✓ Remote tracking:   kept (origin/{branch})        (default)   | pruned    (--delete-branch)

Archive files untouched: .claude-workspace/archive/
{Run with --delete-branch later if you want to remove the branch too.   (default path only)}
```

If any step was skipped or failed (worktree already gone, branch already deleted remotely), note that in the summary but treat as success — cleanup is idempotent.

## Guidance

- **When to run:** after the PR merges on GitHub. The default run cleans up the task metadata (task dir, worktree if any) but keeps the branch — lets you look back at the work, cherry-pick, or diff against it without relying on GitHub alone.
- **Why keep the branch by default:** local branches cost nothing, the remote retention policy is an org decision (many keep merged branches indefinitely), and there's no easy undo once you delete. Opt-in with `--delete-branch` when you're sure.
- **Worktree is optional:** prep-task doesn't create worktrees; users who want concurrent tasks make them manually. Most cleanup runs won't have a worktree — the flow skips Step 7a in that case.
- **Running from the worktree (if one exists):** the flow detects this and instructs the user to `cd` to the main repo. Don't try to work around it — git will fail and the shell will lose its CWD mid-flight.
- **`--delete-branch` preconditions:** not currently on the target branch, no unpushed commits. Without the flag, neither condition is checked because the branch isn't being touched.
- **Squash/rebase merges (only under `--delete-branch`):** `git branch -d` will often refuse because the merge commit on main has a different SHA than the branch tip. The flow falls back to `-D` with explicit confirmation. This is expected, not an error.
- **`--force` is for abandonment:** use it when the user is giving up on a branch that will never merge (closed PR, superseded work). It is NOT a shortcut past normal checks — it still verifies any worktree is clean and still requires typing the branch name to confirm.
- **Archive files are sacred:** this flow only touches the task dir (which contains README + symlinks + task management files) and the worktree. The actual artifacts in `archive/` stay put. If the user wants to clean up archive, that's a separate concern — see `references/rules.md § Cleanup Thresholds`.
- **Dependents:** stacked task workflows (task B depends on archive from task A) aren't common, but the Step 5 check flags them. The user decides whether to proceed with dangling-symlink consequences.
- **Idempotency:** re-running after a successful cleanup is a no-op with a "nothing to clean" message, not an error. This matters for scripts and for users who aren't sure whether they already ran it.
- **No PR, no gh:** if the project has no remote or `gh` isn't available, `--force` + manual branch name confirmation is the only path. The flow warns when `gh` isn't installed rather than silently skipping the merged-check.
