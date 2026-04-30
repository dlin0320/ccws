# Prep-Task Flow - Begin or Resume Work

> **Execution:** Run inline in the main context.

Prepare a task for work — either creating a new branch + task dir, or resuming an existing one. Operates in place on the current repo; no worktree or session switch.

## Purpose
Turn a user intent into a named, categorized, branch-bound task ready for implementation. Each task lives on its own branch in the current working tree, with the task dir keyed by the branch name. Worktrees are an environment choice the user makes (if they want concurrent tasks) — prep-task doesn't create them.

## Outcome (Required)
- [ ] Task name is meaningful and categorized with a conventional-commit prefix
- [ ] Branch `{type}/{name}` exists, based on the project's main branch, and is checked out
- [ ] `.claude-workspace/task/{type}-{name}/README.md` exists with Objective, Context, Success Criteria
- [ ] Session is ready to proceed (Gate 1 approved)

## Constraints (Required)
- Task dir name is the branch with `/` flattened to `-`: branch `feat/auth-refresh` → `task/feat-auth-refresh/`. See `references/patterns.md § Task Directory Naming`.
- README.md is the only file created directly in the task directory (artifacts live in `archive/` and symlink)
- Branch defaults to being cut from the project's main branch, not from whatever the user is currently on
- Refuse to create a new branch while the working tree is dirty — the user must commit or stash first (prevents silent carryover of unrelated changes)

## Process

### 1. Determine Mode

```bash
branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
task_name="${branch//\//-}"
```

- **Resume** if the current branch has a matching `task/$task_name/` dir → Step 2A.
- **Create** otherwise → Step 2B.

### 2A. Resume Existing Task

Read `.claude-workspace/task/$task_name/README.md`, list symlinks, check for broken ones.

**If broken symlinks are found:**
```
⚠ Found broken symlinks (targets no longer exist):
  - [symlink] → [target]
Remove broken symlinks? (yes/no)
```
If yes: remove them. If no: proceed with warning.

**Check for README changes since last review:**
- If the `## Design Decisions` section is non-empty, OR progress notes contain reconcile entries the user may not have seen:
  - Display the full README and note: "README has been updated since your last review. Please review before continuing."
  - Wait for user confirmation (re-gate).
- Otherwise, abbreviated confirmation:

```
✓ Resuming task: {branch}
✓ Objective: {from README}
✓ Current state: {latest progress note}
```

Proceed to Step 3.

### 2B. Create New Task

#### Check Working Tree

```bash
dirty=$(git status --porcelain)
```

If `dirty` is non-empty:
```
⚠ Working tree has uncommitted changes:
{dirty output}

prep-task refuses to create a branch over dirty state. Commit or stash first, then retry.
```
Exit. The user decides whether those changes belong on the current branch, a different task branch, or should be stashed for later.

#### Gather Context
Extract from user's message or ask:
- **Objective** — what to achieve (specific, outcome-focused)
- **Context** — why; what prompted this
- **Success criteria** — how we know it's done (specific, testable)

CCWS works best when the user brings pre-existing specs or design docs. Success criteria should trace to references when available.

#### Propose Name + Type

Classify the task from the objective text:

| Type | Use for |
|------|---------|
| `feat` | New feature or capability |
| `fix` | Bug fix |
| `refactor` | Restructuring without behavior change |
| `chore` | Maintenance, deps, tooling |
| `docs` | Documentation only |
| `test` | Test-only changes |
| `perf` | Performance work |
| `exp` | Experimental / spike |

Generate a kebab-case name from the objective (2–5 words, specific).

**Validation:**
- **Denylist** (reject): `task`, `fix`, `bug`, `wip`, `temp`, `test`, `changes`, `update`, `stuff`, `things`, `work`, `new`
- **Required form**: lowercase, hyphens only, no spaces, no uppercase
- **Minimum specificity**: at least one hyphen OR ≥12 characters (forces multi-word names)

If the name fails, propose a better one derived from the objective text. Do not accept a name that fails validation.

#### Confirm Branch (Gate 1a)

Present:
```
Proposed branch: {type}/{name}
Task dir:        .claude-workspace/task/{type}-{name}/
Base:            origin/{main-branch}

Confirm, or override (e.g. "use fix/ instead", "rename to {new-name}", "base off {other-branch}")?
```

User confirms or edits. Default base is `origin/{main-branch}` (detect: `main` or `master`). Offering to base off a different branch is allowed but unusual — warn if non-default.

#### Create Branch

Compute the task key per `references/patterns.md § Task Directory Naming`, fetch the base, and check out a new branch in the current repo:

```bash
main_repo=$(git rev-parse --show-toplevel)
task_name="${branch_name//\//-}"            # feat/auth-refresh → feat-auth-refresh

git -C "$main_repo" fetch origin {main-branch}
git -C "$main_repo" checkout -b "{type}/{name}" "origin/{main-branch}"
```

After checkout, the session is on the new branch. No directory change needed.

#### Create Task Dir + README

```bash
mkdir -p "$main_repo/.claude-workspace/task/$task_name"
```

Write `README.md` using the template:

```markdown
# Task: {type}/{name}

**Started:** YYYY-MM-DD HH:MM
**Branch:** {type}/{name}

## Objective
{What we're trying to achieve — specific and outcome-focused}

## Context
{Why this task? What prompted it? Any background}

## Success Criteria
{How will we know it's done? Specific, testable conditions. Trace to spec sections when possible.}

## Design Decisions
<!-- Intentional divergences from spec — added during reconcile -->

## Progress Notes
<!-- Added by implement, reconcile, and other flow runs -->
```

#### Initial Linking

Symlink any reference docs or deliverables the user mentioned. See `references/patterns.md § Symlink Construction` for path details. The symlinks go into `.claude-workspace/task/{type}-{name}/`.

#### Gate 1b: Approve README

Display the full README. Pause:

```
✓ Branch created:  {type}/{name}
✓ Task dir:        .claude-workspace/task/{type}-{name}/

[Full README]

Review the objective and success criteria. Confirm to proceed, or request changes.
```

If changes requested: update README and re-display. Do NOT proceed to implement-task automatically.

### 3. Ready to Work

```
✓ Task ready: {type}/{name}

Continue with implement-task, or proceed with manual work.
```

## File Creation During Task (REQUIRED)

All artifacts MUST be created in `archive/` and symlinked to the task dir. See `references/patterns.md § Symlink Construction` and `§ Task Management Files`.

**DO NOT create artifacts in `task/{type}-{name}/`** — violates workspace architecture.

## Guidance

- **One branch per task.** Branch = task dir = unit of work. prep-task checks out the branch in place; no worktree or session switch.
- **Base branch default:** `origin/main` (or `origin/master`). Prompt for override only if the user has a specific reason.
- **Task naming:** prefer specific over clever. `feat/token-refresh-retry` beats `feat/auth-fix`.
- **Stacked branches:** if the user wants to branch off another feature branch (not main), warn that the PR will require the base PR to merge first.
- **Resume path:** when resuming, the current branch must match an existing task dir. If you're on `feat/x` but no corresponding task dir exists, prep-task treats it as Create and prompts.
- **Dirty tree:** prep-task refuses to create a branch over uncommitted changes. The user commits, stashes, or discards — their call.
- **Concurrent tasks via worktree (optional):** if the user wants to run two tasks in parallel, they create a worktree manually (`git worktree add ...`) before running prep-task. The flow works the same inside a worktree — branch resolution is identical. `cleanup-task` detects and removes any worktree it finds.
- **Completion:** end-task commits, pushes, and opens a PR. The task dir stays until the PR merges; cleanup-task removes it (and any worktree) post-merge.
