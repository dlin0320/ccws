# Shared Patterns

Reusable templates, formats, and operational patterns referenced by flow files. Read specific sections by heading.

## Task Directory Naming

The task directory key is the branch name with `/` replaced by `-`. Task directories are exactly one level deep — the `/` separator in branches like `feat/auth-refresh` is a git commit convention, not a filesystem layout.

- Branch `feat/auth-refresh` → task dir `task/feat-auth-refresh/`
- Branch `fix/issue-123` → task dir `task/fix-issue-123/`
- Branch `main` → no task dir (flows refuse to operate on main)

The worktree basename uses the same transform, so `{repo}-feat-auth-refresh/` (worktree) pairs with `task/feat-auth-refresh/` (task dir).

**Bash idiom — use this whenever a flow resolves the task dir from the current branch:**

```bash
branch=$(git rev-parse --abbrev-ref HEAD)
task_name="${branch//\//-}"
task_dir=".claude-workspace/task/$task_name"
```

User-facing path displays use the form `task/{task-name}/` where `{task-name}` is the flattened branch.

## Symlink Construction

From `task/[task-name]/`, use relative symlinks to reach targets:

- **Archive files** are siblings under `.claude-workspace/`, so the path is always `../../archive/[type]/filename`
- **Deliverables** are outside `.claude-workspace/` — count `../` levels from the task directory up to the project root, then down to the file

Verify symlinks resolve correctly with `ls -la` after creation. Path distinguishes intent: symlinks into `archive/` are artifacts, symlinks outside `.claude-workspace/` are deliverables.

## Turn Logging

TURNS.md is maintained automatically by the turn-log hook installed by setup-flow. Flows do NOT log to TURNS.md themselves — the hook is the sole writer.

**Trigger events:**
- `Stop` — fires once after each main-session turn; writes `[auto]` entry
- `SubagentStop` — fires once after each subagent (Agent tool) completion; writes `[auto:subagent]` entry

**Task resolution:** the hook reads the current git branch (`git rev-parse --abbrev-ref HEAD`), applies the slash-to-dash transform per `§ Task Directory Naming`, and targets `.claude-workspace/task/{task-name}/TURNS.md`. If no matching task dir exists, the hook silently exits — non-task turns produce no entry.

**Entry format:**

    ### YYYY-MM-DD HH:MM [tag]
    First ~240 chars of the last assistant message, whitespace-collapsed to one line.

**Tags:**
- `[auto]` — main-session Stop
- `[auto:subagent]` — SubagentStop

**Example:**

    ### 2026-04-20 15:06 [auto]
    Implemented token refresh logic in src/auth.ts. Added retry with exponential backoff per spec §3.

**Consumption:** checkpoint-task reads TURNS.md to distill progress notes into the README, then clears the file. Empty TURNS.md after checkpoint is expected.

**Troubleshooting:** if TURNS.md isn't being written, verify (1) `.claude/settings.json` has Stop and SubagentStop hook entries pointing at `<skill-dir>/hooks/turn-log.sh`, (2) the script is executable, (3) the current git branch flattened per `§ Task Directory Naming` matches an existing `.claude-workspace/task/{task-name}/` directory.

## Design Decisions

Record intentional divergences from reference docs or specs in the task README `## Design Decisions` section.

**Template:**

```markdown
### [Short title]
- **Spec:** [What the reference doc says, with section ref]
- **Decision:** [What we did instead]
- **Rationale:** [Why]
```

**When to add:**
- Chose a different approach than what a design doc specifies
- Deferred something the spec says to implement now
- Added something not in any spec (and the choice is non-obvious)
- Changed a convention from what docs describe

**When NOT to add:**
- The spec doesn't cover it (nothing to diverge from)
- It's a bug fix or straightforward implementation
- It's already documented in a previous decision

If the README doesn't have a `## Design Decisions` section yet, create one between Success Criteria and Progress Notes.

## Task Management Files

Files that live directly in the task directory (not symlinked from archive):

| File | Purpose | Created by |
|------|---------|------------|
| `README.md` | Objective, context, success criteria, design decisions, progress notes | prep-task |
| `TURNS.md` | Per-turn session log, distilled into README by checkpoint | Automatic (turn logging) |
| `FEEDBACK.md` | Review findings with classifications | review-task |
| `SNAPSHOT.md` | Implementation structure index | snapshot-task |
| `SUMMARY.md` | User-facing implementation summary | summarize-task |

## Conventions

### Naming
- **Tasks:** kebab-case, short, descriptive: `auth-refactor`, `bug-fix-1234`
- **Files:** lowercase with hyphens: `auth-analysis.md` (not `notes.md` or `temp.txt`)
- **Time-sensitive files:** date prefix: `2025-10-28-coverage.html`

### Concurrent Tasks
- Multiple tasks can coexist but should represent **independent work**
- If two tasks symlink the same deliverable, edits through either affect the same file — checkpoint both tasks before switching
- Prefer sequential tasks over concurrent when work overlaps on the same files
- When resuming, always check `ls .claude-workspace/task/` to see all active tasks

### Checkpoints
- Save progress before context switches
- Latest checkpoint = source of truth for WIP state

### File Metadata
Add header to workspace documentation for searchability:
```markdown
<!--
Purpose: [What this file does]
Created: [YYYY-MM-DD]
Task: [Associated task]
Tags: [Keywords]
-->
```

## Finding Previous Work

When searching for prior work on a topic:

1. **Git commits** — completed deliverable changes:
   ```bash
   git log --oneline --grep="[topic]" -10
   ```
2. **Archive** — artifacts from past tasks:
   ```
   Glob "*[topic]*" in .claude-workspace/archive/
   Grep "[topic]" in .claude-workspace/archive/docs/
   ```
3. **Active tasks** — current WIP:
   ```
   Bash: ls .claude-workspace/task/
   ```

## Cross-Task File Reuse

Archive files persist after task deletion and can be symlinked to any future task. If a modified copy is needed, create a new version in archive first (`-v2` suffix), then symlink that.

## Agent Handoff

When a different agent or session needs to continue work:

1. Check for active tasks: `ls .claude-workspace/task/`
2. Read task README for objectives, decisions, and current state
3. Check git log for recent deliverable changes: `git log --oneline -10`
4. Search archive for relevant artifacts

**Context sources:** README = current WIP, git history = completed work, archive = reusable artifacts.

## Build Verification

When a flow requires build verification:

1. Detect the project's build command from project files (package.json, Makefile, go.mod, Cargo.toml, pyproject.toml, etc.)
2. Run it and note pass/fail in the progress note or return summary
3. If tests exist for affected code, run them
4. If no build system is detected, note this rather than silently skipping

## Recovery

When a flow fails mid-execution or leaves unexpected state, check these invariants:

| Check | Expected | Fix |
|-------|----------|-----|
| Task directory contents | Task management files + symlinks only | Move real files to archive/, remove unexpected files |
| Symlinks | All resolve to existing targets | Remove broken symlinks or recreate targets |
| README progress notes | Chronological, latest reflects current state | Add a corrective progress note |
| TURNS.md after checkpoint | Empty (cleared by checkpoint) | Clear if checkpoint completed successfully |
| FEEDBACK.md vs README | Reconcile progress note post-dates FEEDBACK.md if findings addressed | Run reconcile-task or add missing progress note |

**General recovery:** README is source of truth for task intent, git for deliverable state, archive for artifacts. Read the README, compare against actual state, correct the divergence.
