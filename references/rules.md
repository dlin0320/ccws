# Workspace Rules

Conventions for `.claude-workspace/` with symlink-based task organization.

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

**Task** - A temporary unit of work with its own directory in `current/`.
- Path: `current/[task-name]/`
- Contains: README.md + symlinks (to artifacts AND/OR deliverables)
- Lifecycle: Create → Work → Complete → Delete
- Deletion safe: only removes directory with README and symlinks, never actual files

## REQUIRED RULES (Non-Negotiable)

These rules define the workspace architecture and MUST be followed:

### 1. File Creation Architecture
- ✅ **DO**: Create ALL files in `archive/[type]/`
- ✅ **DO**: Symlink from archive to `current/[task]/`
- ❌ **DON'T**: Create files directly in `current/[task]/` (except README.md)
- ❌ **DON'T**: Create files outside `.claude-workspace/`

```bash
# CORRECT
echo "content" > .claude-workspace/archive/scripts/test.sh
ln -s ../../archive/scripts/test.sh .claude-workspace/current/my-task/test.sh

# WRONG
echo "content" > .claude-workspace/current/my-task/test.sh
```

### 2. Task Deletion
- ✅ **DO**: Delete task directory when complete: `rm -rf current/[task]/`
- ✅ **DO**: Verify archive files remain untouched after deletion
- ❌ **DON'T**: Delete or move archive files when completing tasks
- ❌ **DON'T**: Leave completed task directories in current/

### 3. Directory Structure
- ✅ **DO**: Use `current/`, `archive/[types]/`, `checkpoint/` structure
- ✅ **DO**: Organize archive by type: docs, scripts, reports, research
- ❌ **DON'T**: Create custom top-level directories in workspace
- ❌ **DON'T**: Reorganize archive structure without updating rules

### 4. Symlink Pattern
- ✅ **DO**: Use relative symlinks: `ln -s ../../archive/type/file current/task/file`
- ✅ **DO**: Symlink artifacts from archive/ to task
- ✅ **DO**: Symlink project deliverables to task for context (read/write allowed)
- ❌ **DON'T**: Use absolute paths in symlinks
- ❌ **DON'T**: Move or rename project files through symlinks

**Symlinking project files:**
```bash
# Link deliverable for context (safe to edit through symlink)
ln -s ../../src/auth.ts .claude-workspace/current/auth-fix/auth.ts

# Link artifact (created in archive first)
ln -s ../../archive/docs/auth-analysis.md .claude-workspace/current/auth-fix/auth-analysis.md
```

Path makes intent clear: `../../src/` = deliverable, `../../archive/` = artifact

## RECOMMENDED PATTERNS (Best Practices)

These patterns improve workspace usage but can be adapted:

### Task Naming
- Use kebab-case: `auth-refactor`, `bug-fix-1234`
- Keep names simple and descriptive
- One conceptual unit per task

### File Naming
- Lowercase with hyphens: `auth-analysis.md`
- Descriptive, not generic: ~~`notes.md`~~, ~~`temp.txt`~~
- Date prefix for time-sensitive: `2025-10-28-coverage.html`

### Checkpoint Usage
- Save progress before context switches
- Latest checkpoint = source of truth
- Keep recent 10-20, archive older ones

### File Metadata
Add header to documentation for searchability:
```markdown
<!--
Purpose: [What this file does]
Created: [YYYY-MM-DD]
Task: [Associated task]
Tags: [Keywords]
-->
```

---

## Directory Reference

### current/ - Active Tasks
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

## Task Lifecycle

1. **Start**: Create `current/[task]/` with README
2. **Work**: Create artifacts in `archive/[type]/`, symlink to task
3. **Checkpoint**: Update README with progress notes (anytime)
4. **Complete**: Git commit (if deliverables changed) + delete `current/[task]/`
5. **Resume**: Read task README, git log, or search archive