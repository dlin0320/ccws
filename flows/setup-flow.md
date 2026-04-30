# Setup Flow - Workspace Initialization

Non-interactive setup for `.claude-workspace/` and global workspace conventions.

## When to Use

- User requests workspace setup
- `.claude-workspace/` doesn't exist in project

## Steps

### 1. Check Existing Workspace

```bash
ls -la .claude-workspace/ 2>/dev/null
```

If exists: Ask if user wants to reconfigure (backup existing to `.claude-workspace.backup-[timestamp]`)

### 2. Create Directory Structure

```bash
mkdir -p .claude-workspace/task .claude-workspace/archive/docs .claude-workspace/archive/scripts .claude-workspace/archive/reports .claude-workspace/archive/research
```

Creates structure:
- **task/** - Active tasks (README + symlinks)
- **archive/** - Permanent artifacts by type:
  - **docs/** - Documentation, analysis, architecture
  - **scripts/** - Reusable automation, utilities
  - **reports/** - Test results, benchmarks
  - **research/** - Experiments, comparisons

### 3. Update .gitignore

Check if `.gitignore` exists:
- If yes: Append `.claude-workspace` if not already present
- If no: Create with `.claude-workspace`

```bash
# Check and append — NO trailing slash, so the pattern matches both real dirs and symlinks
grep -qE "^\.claude-workspace/?$" .gitignore 2>/dev/null || echo ".claude-workspace" >> .gitignore
```

**Why no trailing slash:** if the user ever creates a worktree manually and symlinks `.claude-workspace` into it (so archive/ and task/ stay shared), the worktree sees a symlink-to-directory rather than a real directory. Git's `.gitignore` pattern `foo/` only matches actual directories, so the pattern with no slash (`.claude-workspace`) is what covers both cases. Costs nothing in the common non-worktree case.

### 4. Configure Project CLAUDE.md

Ensure the project has a `CLAUDE.md` file (create if absent). Append the following block if it's not already present:

```markdown
## Maintaining This File

When working on tasks, add project knowledge to this file that would help future sessions avoid repeated discovery:
- Build, test, and run commands
- Project conventions not obvious from code alone
- Environment setup requirements or gotchas
- Integration points with external systems

Do not add: task-specific state, information already in code/docs, or ephemeral details. Keep entries concise.
```

### 5. Commit Setup Artifacts

Stage and commit the tracked setup files so they're part of the repo from the start:

```bash
git add .gitignore CLAUDE.md
git commit -m "ccws setup: workspace, gitignore"
```

**Why commit now:** prep-task cuts new branches from the default branch (`main` / `master`). Having `.gitignore` and `CLAUDE.md` committed means every new branch inherits the `.claude-workspace` ignore rule and maintenance guidance automatically. If the user prefers to review before committing, skip this step and tell them to commit manually.

### 6. Completion

Inform user:

```
✓ Workspace created: .claude-workspace/
✓ Structure: task/ (active tasks), archive/ (permanent artifacts)
✓ .gitignore: updated (no trailing slash — matches symlinks too, covers optional worktrees)
✓ CLAUDE.md: maintenance guidance added
✓ Committed: .gitignore, CLAUDE.md

Workspace ready! Use ccws flows to manage tasks:
- prep-task: Begin a new task (checks out a new branch in the current repo)
- end-task: Commit, push, open PR
```
