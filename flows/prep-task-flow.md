# Prep-Task Flow - Begin or Resume Work

> **Execution:** Run inline in the main context.

Prepare a task for work — either creating a new branch + worktree + task dir, or resuming an existing one.

## Purpose
Turn a user intent into a named, categorized, branch-bound task ready for implementation. Worktree-native by default: each task lives on its own branch in its own worktree, with the task dir keyed by the branch name.

## Outcome (Required)
- [ ] Task name is meaningful and categorized with a conventional-commit prefix
- [ ] Branch `{type}/{name}` exists, based on the project's main branch
- [ ] Worktree exists at a sibling path of the main repo (for new tasks)
- [ ] `.claude-workspace/task/{type}/{name}/README.md` exists with Objective, Context, Success Criteria
- [ ] Session is ready to proceed in the worktree (Gate 1 approved)

## Constraints (Required)
- Task dir path mirrors the branch name exactly: branch `feat/auth-refresh` → `task/feat/auth-refresh/`
- README.md is the only file created directly in the task directory (artifacts live in `archive/` and symlink)
- Worktree-native: branch is authoritative; the turn-log hook resolves the task dir from `git rev-parse --abbrev-ref HEAD`
- Branch defaults to being cut from the project's main branch, not from whatever the user is currently on

## Process

### 1. Determine Mode

```bash
branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
```

- **Resume** if the current branch has a matching `task/{branch}/` dir → Step 2A.
- **Create** otherwise → Step 2B.

### 2A. Resume Existing Task

Read `.claude-workspace/task/{branch}/README.md`, list symlinks, check for broken ones.

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
Example path:    {worktree-path}
Base:            origin/{main-branch}

Confirm, or override (e.g. "use fix/ instead", "rename to {new-name}", "base off {other-branch}")?
```

User confirms or edits. Default base is `origin/{main-branch}` (detect: `main` or `master`). Offering to base off a different branch is allowed but unusual — warn if non-default.

#### Create Branch + Worktree

Compute the worktree path — sibling to main repo, slashes in branch replaced with dashes:

```bash
main_repo=$(git rev-parse --show-toplevel)
base_name=$(basename "$main_repo")
worktree_suffix="${branch_name//\//-}"      # feat/auth-refresh → feat-auth-refresh
worktree_path="$(dirname "$main_repo")/${base_name}-${worktree_suffix}"
```

Create the branch and worktree from main:

```bash
git -C "$main_repo" fetch origin {main-branch}
git -C "$main_repo" worktree add -b "{type}/{name}" "$worktree_path" "origin/{main-branch}"
```

Symlink the workspace into the worktree so archive/ and task/ are shared:

```bash
ln -s "$main_repo/.claude-workspace" "$worktree_path/.claude-workspace"
```

#### Create Task Dir + README

```bash
mkdir -p "$main_repo/.claude-workspace/task/{type}/{name}"
```

Write `README.md` using the template:

```markdown
# Task: {type}/{name}

**Started:** YYYY-MM-DD HH:MM
**Branch:** {type}/{name}
**Worktree:** {worktree-path}

## Objective
{What we're trying to achieve — specific and outcome-focused}

## Context
{Why this task? What prompted it? Any background}

## Success Criteria
{How will we know it's done? Specific, testable conditions. Trace to spec sections when possible.}

## Design Decisions
<!-- Intentional divergences from spec — added during checkpoint or reconcile -->

## Progress Notes
<!-- Added during checkpoint -->
```

#### Initial Linking

Symlink any reference docs or deliverables the user mentioned. See `references/patterns.md § Symlink Construction` for path details. The symlinks go into the task dir under the main repo's `.claude-workspace/task/{type}/{name}/`.

#### Gate 1b: Approve README

Display the full README. Pause:

```
✓ Branch created: {type}/{name}
✓ Worktree:       {worktree-path}
✓ Task dir:       .claude-workspace/task/{type}/{name}/

[Full README]

Review the objective and success criteria. Confirm to proceed, or request changes.
```

If changes requested: update README and re-display. Do NOT proceed to implement-task automatically.

### 3. Ready to Work

Inform the user of the worktree path and instruct them to move the session there:

```
✓ Task ready: {type}/{name}

To continue in the worktree:
  cd {worktree-path}

Then invoke implement-task, or proceed with manual work. The turn-log hook will write to
  {worktree-path}/.claude-workspace/task/{type}/{name}/TURNS.md
automatically.
```

The main-repo session can exit or remain — all further work happens in the worktree.

## File Creation During Task (REQUIRED)

All artifacts MUST be created in `archive/` and symlinked to the task dir. See `references/patterns.md § Symlink Construction` and `§ Task Management Files`.

**DO NOT create artifacts in `task/{type}/{name}/`** — violates workspace architecture.

## Guidance

- **Worktree is the unit.** Branch = worktree = task. Don't create a task without a worktree; don't create a worktree without a task.
- **Base branch default:** `origin/main` (or `origin/master`). Prompt for override only if the user has a specific reason.
- **Task naming:** prefer specific over clever. `feat/token-refresh-retry` beats `feat/auth-fix`.
- **Stacked branches:** if the user wants to branch off another feature branch (not main), warn that the PR will require the base PR to merge first.
- **Resume path:** when resuming, the current branch must match an existing task dir. If you're on `feat/x` but no `task/feat/x/` exists, prep-task treats it as Create and prompts.
- **Completion:** end-task commits, pushes, and opens a PR. Worktree and task dir stay until the PR merges, then are cleaned up separately.
