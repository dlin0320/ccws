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
mkdir -p .claude-workspace/current .claude-workspace/archive/docs .claude-workspace/archive/scripts .claude-workspace/archive/reports .claude-workspace/archive/research
```

Creates structure:
- **current/** - Active tasks (README + symlinks)
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

### 4. Update Global Claude.md

Append workspace section to `~/.claude/Claude.md` if not already present:

```bash
# Check if workspace section already exists
if grep -q "^# Claude Code Workspace" ~/.claude/Claude.md 2>/dev/null; then
  echo "Workspace conventions already in global Claude.md"
else
  # Create ~/.claude/ if it doesn't exist
  mkdir -p ~/.claude

  # Append with proper spacing
  echo "" >> ~/.claude/Claude.md
  echo "" >> ~/.claude/Claude.md
  cat ~/.claude/skills/ccws/references/claude-md.md >> ~/.claude/Claude.md

  echo "✓ Added workspace conventions to ~/.claude/Claude.md"
fi
```

**Note:** This makes workspace conventions global - they apply to all projects where you create a `.claude-workspace/`.

### 5. Completion

Inform user:

```
✓ Workspace created: .claude-workspace/
✓ Structure: current/ (active tasks), archive/ (permanent artifacts)
✓ .gitignore: updated
✓ Global conventions: ~/.claude/Claude.md (applies to all projects)

Workspace ready! Start a task with "start task" or "start working on [X]"

Context preservation:
- WIP: Task README (updated with "checkpoint")
- Completed work: Git commits
- Artifacts: Persist in archive/

Project-specific context can go in project CLAUDE.md.
Global workspace conventions are in ~/.claude/Claude.md.
```
