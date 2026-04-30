# Workspace Rules

Structural invariants for `.claude-workspace/`. These define the workspace architecture — what must always be true regardless of which flows are used.

## Terminology

Clear definitions to avoid confusion:

**Project** - The main codebase/repository containing deliverables.
- Path: Everything OUTSIDE `.claude-workspace/`
- Examples: `src/`, `lib/`, `test/`, `package.json`, `README.md`

**Workspace (CCWS)** - Claude's development environment for artifacts.
- Path: `.claude-workspace/` directory
- Purpose: Claude's work-in-progress, analysis, development tools

**Artifact** - Files created BY Claude FOR Claude's development process.
- Must exist in workspace (`archive/[type]/[name]/`)
- Examples: investigations (audits, gap analyses, captures), automation scripts, multi-task plans
- Never part of project deliverables
- Gitignored (not committed)

**Deliverable** - Files that are part of the project.
- Exists in project (outside workspace)
- Examples: source code, project tests, project documentation
- Version controlled and shipped with project

**Task** - A temporary unit of work bound to a branch (checked out in the current repo; worktrees are optional and user-managed).
- Path: `task/[task-name]/` — the branch name flattened per `references/patterns.md § Task Directory Naming` (e.g., `feat/auth-refresh` → `task/feat-auth-refresh/`)
- Contains: README.md + symlinks (to artifacts AND/OR deliverables)
- Lifecycle: prep-task → work → end-task (PR opens) → (PR merges externally) → cleanup-task
- Deletion safe: cleanup-task removes only the directory with README and symlinks, never actual files

## REQUIRED RULES (Non-Negotiable)

These rules define the workspace architecture and MUST be followed:

### 1. File Creation Architecture
- ✅ **DO**: Create ALL files in `archive/[type]/[name]/`
- ✅ **DO**: Symlink from archive to `task/[task]/`
- ❌ **DON'T**: Create files directly in `task/[task]/` (except task management files: README.md, FEEDBACK.md, SUMMARY.md)
- ❌ **DON'T**: Create files at `archive/[type]/` root — every artifact lives inside a name-keyed bundle
- ❌ **DON'T**: Create files outside `.claude-workspace/`

```bash
# CORRECT
echo "content" > .claude-workspace/archive/scripts/test-api/test-api.sh
ln -s ../../archive/scripts/test-api/test-api.sh .claude-workspace/task/my-task/test-api.sh

# WRONG
echo "content" > .claude-workspace/archive/scripts/test.sh
echo "content" > .claude-workspace/task/my-task/test.sh
```

### 2. Task Lifecycle and Deletion
- ✅ **DO**: Leave the task directory in place through PR review — `end-task` opens the PR, `cleanup-task` removes the directory after the PR merges
- ✅ **DO**: Treat `cleanup-task` as the sole deleter — no other flow removes a task directory
- ✅ **DO**: Verify archive files remain untouched after cleanup
- ❌ **DON'T**: Delete or move archive files when completing tasks
- ❌ **DON'T**: Manually remove a task directory before its PR merges; it's needed for `triage-pr-review` and for reference during external review
- ✅ **DO**: Preserve plan directories (`archive/plans/{plan-name}/`) past task cleanup — they're durable cross-task artifacts; manual pruning is the user's call

### 3. Directory Structure
- ✅ **DO**: Use `task/`, `archive/[types]/` structure
- ✅ **DO**: Organize archive by type: plans, investigations, scripts
- ✅ **DO**: Use name-keyed bundles under each type — `archive/{type}/{name}/` (see `references/patterns.md § Archive Shape`)
- ❌ **DON'T**: Create custom top-level directories in workspace
- ❌ **DON'T**: Reorganize archive structure without updating rules
- ❌ **DON'T**: Nest task directories (e.g., `task/feat/auth-refresh/` breaks symlink paths and glob-based task discovery)
- ✅ **DO**: Keep task directories exactly one level deep: `task/[task-name]/` where `[task-name]` is the branch name flattened per `references/patterns.md § Task Directory Naming`

### 4. Symlink Pattern
- ✅ **DO**: Use relative symlinks from `task/[task-name]/` to the target
- ✅ **DO**: Symlink artifacts from archive/ to task
- ✅ **DO**: Symlink project deliverables to task for context (read/write allowed)
- ❌ **DON'T**: Use absolute paths in symlinks
- ❌ **DON'T**: Move or rename project files through symlinks

For path construction details, see `references/patterns.md § Symlink Construction`.

For conventions (naming, concurrent tasks, file metadata), see `references/patterns.md § Conventions`.

## Directory Reference

### task/ - Active Tasks
Contents: README.md (task-specific) + symlinks to archive files
Path: `task/[task-name]/` — flat, one level deep. Branch name flattened to dashes per `references/patterns.md § Task Directory Naming` (e.g. `feat/auth-refresh` → `task/feat-auth-refresh/`).
Lifecycle: prep-task → implement / review / reconcile → end-task (PR opens) → cleanup-task (post-merge)

### archive/ - Permanent Storage
All archive content uses name-keyed bundles: `archive/{type}/{name}/`. See `references/patterns.md § Archive Shape` for the full convention. The project repo holds evergreen reference (architecture, runbooks, in-tree ADRs); archive holds snapshot content (investigations of external systems, captures of upstream state, forward-looking plans).

**archive/plans/{name}/** - Forward-looking multi-task plans (cross-task referenced specs)
Examples: `plans/auth-refresh/PLAN.md`, `plans/migration-q3/PLAN.md`

**archive/investigations/{name}/** - Backward-looking captures (audits, gap analyses, debug bundles, test reports, comparisons)
Examples: `investigations/snowflake-token-audit/README.md`, `investigations/coverage-2026-04/README.md`

**archive/scripts/{name}/** - Reusable automation
Examples: `scripts/test-api/test-api.sh`, `scripts/deploy/deploy.sh`

## Cleanup Thresholds

Aggressive cleanup for lean workspace:
- **Time**: Flag artifacts >30 days old for review
- **Size**: Review when archive/ >50MB
- **Tasks**: Delete immediately after completion (REQUIRED)

### Cleanup Procedure
When thresholds are hit:
1. **Identify candidates**: `find .claude-workspace/archive/ -mtime +30 -type f` (or check `du -sh .claude-workspace/archive/`)
2. **Check for active references**: For each candidate, verify no active task symlinks point to it: `find .claude-workspace/task/ -type l -exec readlink {} \; | grep [candidate-filename]`
3. **Review before deleting**: Never auto-delete. Present the list to the user with file sizes and last-modified dates
4. **Delete confirmed files only**: Remove from archive/; any dangling symlinks in active tasks will be caught by prep-task's broken symlink check

