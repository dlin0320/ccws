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
- Must exist in workspace (`archive/[type]/`)
- Examples: analysis docs, test scripts, debug logs, research notes
- Never part of project deliverables
- Gitignored (not committed)

**Deliverable** - Files that are part of the project.
- Exists in project (outside workspace)
- Examples: source code, project tests, project documentation
- Version controlled and shipped with project

**Task** - A temporary unit of work with its own directory in `task/`.
- Path: `task/[task-name]/`
- Contains: README.md + symlinks (to artifacts AND/OR deliverables)
- Lifecycle: Create → Work → Complete → Delete
- Deletion safe: only removes directory with README and symlinks, never actual files

## REQUIRED RULES (Non-Negotiable)

These rules define the workspace architecture and MUST be followed:

### 1. File Creation Architecture
- ✅ **DO**: Create ALL files in `archive/[type]/`
- ✅ **DO**: Symlink from archive to `task/[task]/`
- ❌ **DON'T**: Create files directly in `task/[task]/` (except task management files: README.md, TURNS.md, FEEDBACK.md, SNAPSHOT.md, SUMMARY.md)
- ❌ **DON'T**: Create files outside `.claude-workspace/`

```bash
# CORRECT
echo "content" > .claude-workspace/archive/scripts/test.sh
ln -s ../../archive/scripts/test.sh .claude-workspace/task/my-task/test.sh

# WRONG
echo "content" > .claude-workspace/task/my-task/test.sh
```

### 2. Task Deletion
- ✅ **DO**: Delete task directory when complete: `rm -rf task/[task]/`
- ✅ **DO**: Verify archive files remain untouched after deletion
- ❌ **DON'T**: Delete or move archive files when completing tasks
- ❌ **DON'T**: Leave completed task directories in task/

### 3. Directory Structure
- ✅ **DO**: Use `task/`, `archive/[types]/` structure
- ✅ **DO**: Organize archive by type: docs, scripts, reports, research
- ❌ **DON'T**: Create custom top-level directories in workspace
- ❌ **DON'T**: Reorganize archive structure without updating rules
- ❌ **DON'T**: Nest task directories (e.g., `task/group/subname/` breaks symlink paths)
- ✅ **DO**: Keep task directories exactly one level deep: `task/[task-name]/`

### 4. Symlink Pattern
- ✅ **DO**: Use relative symlinks from `task/[task-name]/` to the target
- ✅ **DO**: Symlink artifacts from archive/ to task
- ✅ **DO**: Symlink project deliverables to task for context (read/write allowed)
- ❌ **DON'T**: Use absolute paths in symlinks
- ❌ **DON'T**: Move or rename project files through symlinks

For path construction details, see `references/patterns.md § Symlink Construction`.

For conventions (naming, concurrent tasks, checkpoints, file metadata), see `references/patterns.md § Conventions`.

## Directory Reference

### task/ - Active Tasks
Contents: README.md (task-specific) + symlinks to archive files
Lifecycle: Create → Work → Checkpoint → Delete

### archive/ - Permanent Storage
**archive/docs/** - Documentation, analysis, architecture
Examples: `auth-system-analysis.md`, `database-schema.md`

**archive/scripts/** - Reusable automation
Examples: `test-api.sh`, `benchmark.py`, `deploy.sh`

**archive/reports/** - Test results, benchmarks
Examples: `2025-10-28-coverage.html`, `api-performance.md`

**archive/research/** - Experiments, comparisons
Examples: `redis-vs-memcached.md`, `auth-libraries.md`

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

