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
- If yes: Append `.claude-workspace/` if not already present
- If no: Create with `.claude-workspace/`

```bash
# Check and append
grep -q "^\.claude-workspace/" .gitignore 2>/dev/null || echo ".claude-workspace/" >> .gitignore
```

### 4. Configure Turn Logging

Check if a project-level `CLAUDE.md` exists and whether it already contains a turn-logging directive:

```bash
grep -q "TURNS.md" CLAUDE.md 2>/dev/null
```

If the directive is already present: skip this step.

If absent (or `CLAUDE.md` doesn't exist): append the following block to `CLAUDE.md` (create the file if needed):

```markdown
## CCWS Turn Logging

When a task is active under `.claude-workspace/task/`, log a summary to that task's `TURNS.md` after each substantive turn.

**When to log:** After completing a meaningful unit of work (not after every tool call). Examples: implemented a function, fixed a bug, completed a research step, made a design decision.

**Format:**

    ### YYYY-MM-DD HH:MM [tag]
    One-line summary of what was done. Key files or decisions if notable.

**Tags:** Use the flow name when running inside a ccws flow (`[implement-task]`, `[review-task]`, `[reconcile-task]`, `[reconcile-task:fix-code]`). Use `[manual]` for ad-hoc work outside a flow.

**Example:**

    ### 2025-11-15 14:30 [implement-task]
    Implemented token refresh logic in src/auth.ts. Added retry with exponential backoff per spec §3.

**Do not log:** File reads, searches, minor edits, or turns where no meaningful progress was made.

## Maintaining This File

When working on tasks, add project knowledge to this file that would help future sessions avoid repeated discovery:
- Build, test, and run commands
- Project conventions not obvious from code alone
- Environment setup requirements or gotchas
- Integration points with external systems

Do not add: task-specific state, information already in code/docs, or ephemeral details. Keep entries concise.
```

### 5. Completion

Inform user:

```
✓ Workspace created: .claude-workspace/
✓ Structure: task/ (active tasks), archive/ (permanent artifacts)
✓ .gitignore: updated
✓ CLAUDE.md: turn logging configured

Workspace ready! Use ccws flows to manage tasks:
- start-task: Begin or resume work
- checkpoint-task: Save progress
- end-task: Commit + clean up
```
