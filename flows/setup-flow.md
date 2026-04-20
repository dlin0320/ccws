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
# Check and append — NO trailing slash, so the pattern matches both real dirs (main repo) and symlinks (worktrees)
grep -qE "^\.claude-workspace/?$" .gitignore 2>/dev/null || echo ".claude-workspace" >> .gitignore
```

**Why no trailing slash:** prep-task symlinks `.claude-workspace` into each worktree. Git's `.gitignore` pattern `foo/` only matches actual directories, not symlinks-to-directories — so worktrees would see the symlink as untracked. The pattern `.claude-workspace` (no slash) matches both.

### 4. Install Turn-Logging Hook

Resolve the ccws skill directory — the parent of the directory containing this flow file. If setup-flow.md lives at `<skill-dir>/flows/setup-flow.md`, the hook script is at `<skill-dir>/hooks/turn-log.sh`. Use the absolute path.

Ensure the project has `.claude/settings.json` (create if absent). Merge the following hook entries under `hooks.Stop` and `hooks.SubagentStop` without clobbering existing hooks:

```json
{
  "hooks": {
    "Stop": [
      { "hooks": [{ "type": "command", "command": "<skill-dir>/hooks/turn-log.sh" }] }
    ],
    "SubagentStop": [
      { "hooks": [{ "type": "command", "command": "<skill-dir>/hooks/turn-log.sh" }] }
    ]
  }
}
```

The hook appends a one-line entry to the active task's TURNS.md after each main-session turn (`Stop`) and each subagent completion (`SubagentStop`). Task resolution is worktree-native: the hook reads the current git branch and writes to `.claude-workspace/task/<branch>/TURNS.md`. If no matching task dir exists, the hook silently exits — non-task chores produce no noise.

See `references/patterns.md § Turn Logging` for the entry format the hook produces.

### 5. Configure Project CLAUDE.md

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

### 6. Commit Setup Artifacts

Stage and commit the tracked setup files so future worktrees inherit them:

```bash
git add .gitignore .claude/settings.json CLAUDE.md
git commit -m "ccws setup: workspace, hooks, gitignore"
```

**Why commit now:** prep-task creates worktrees from `main` (or the default branch). If `.gitignore` isn't committed, new worktrees won't ignore the `.claude-workspace` symlink and it'll show as untracked. Committing before the first worktree is created avoids this. If the user prefers to review before committing, skip this step and tell them to commit manually.

### 7. Completion

Inform user:

```
✓ Workspace created: .claude-workspace/
✓ Structure: task/ (active tasks), archive/ (permanent artifacts)
✓ .gitignore: updated (no trailing slash — matches symlinks in worktrees)
✓ Hook installed: .claude/settings.json (Stop + SubagentStop → turn-log.sh)
✓ CLAUDE.md: maintenance guidance added
✓ Committed: .gitignore, .claude/settings.json, CLAUDE.md

Workspace ready! Use ccws flows to manage tasks:
- prep-task: Begin a new task (creates branch + worktree)
- checkpoint-task: Save progress
- end-task: Commit, push, open PR
```
