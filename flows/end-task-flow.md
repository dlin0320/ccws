# End-Task Flow - Finish and Clean Up

> **Execution:** Run inline in the main context.

End task with git commit (if deliverables changed) and delete task directory.

## Purpose
Finalize completed work, preserve it in git history, and clean up task directory.

## Outcome (Required)
- [ ] Git commit created (if deliverables were modified)
- [ ] Task directory deleted: `task/[task-name]/`
- [ ] Artifacts remain in archive/
- [ ] User knows task is complete

## Constraints (REQUIRED)
Per workspace REQUIRED RULES:
- MUST delete task directory when complete
- MUST NOT delete or move archive files
- MUST NOT leave completed task directories in task/

## Process

### 1. Check for Active Task

```bash
ls -d .claude-workspace/task/*/ 2>/dev/null
```

If no tasks: "No active tasks to end."
If multiple: Ask which to end.

### 2. Check for Unresolved Findings

If `FEEDBACK.md` exists in the task directory, scan for unresolved actionable findings:
- Count findings with category `DIVERGENCE`, `UNDOCUMENTED`, or `MISSING`
- Exclude `DOCUMENTED` (resolved), `STUB` (intentionally deferred), `EXTRA` (informational)
- Check if a reconcile progress note exists in the README that post-dates the FEEDBACK.md (suggesting reconciliation happened)

If unresolved findings exist AND no post-FEEDBACK.md reconcile note found:
```
⚠ FEEDBACK.md contains N unresolved findings:
  - X DIVERGENCE (contradicts spec)
  - Y UNDOCUMENTED (missing rationale)
  - Z MISSING (not yet implemented)
Consider running reconcile-task before ending. Proceed anyway? (yes/no)
```
If no: stop and suggest running reconcile-task.
If yes: proceed (user accepts the risk).

If `FEEDBACK.md` does not exist: proceed silently (review was never run, which is a valid workflow for simple tasks).

### 3. Check for Deliverable Changes

```bash
git status
```

Were project files (deliverables) modified during this task?

**If YES** → Proceed to Step 4 (Git Commit)
**If NO** (only artifacts created) → Skip to Step 5 (Delete Task)

### 4. Create Git Commits

Avoid bloated unified commits. Create **one commit per logical unit** when possible.

#### 4a. Determine Commit Strategy

Read context sources in priority order:
1. **SUMMARY.md** (if exists) — "Files Changed" section groups changes by logical component
2. **README progress notes** — each implement/reconcile progress note = one logical unit
3. **git diff** — what actually changed

**If changes separate cleanly** (different files per logical unit):
- Create one commit per logical unit
- Each commit message derived from that unit's context

**If changes are interleaved** (same files modified across multiple units):
- Create a single commit with a structured message listing the logical units

#### 4b. Create Commits

For each logical unit (or single commit if interleaved):

```bash
git add [relevant deliverables]
git commit -m "$(cat <<'EOF'
[Concise summary of this logical unit]

[What was done — from SUMMARY.md section or progress note]
[Key decisions if relevant]

Task: [task-name]
EOF
)"
```

**Commit message sources:**
- **If SUMMARY.md exists:** summary line from Objective, body from "What Was Built" sections, key decisions noted
- **If no SUMMARY.md:** fall back to README objective + progress notes

### 5. Delete Task Directory (REQUIRED)

```bash
rm -rf .claude-workspace/task/[task-name]
```

**What gets deleted:**
- Task directory with README
- All symlinks in task directory

**What remains:**
- ALL artifacts in `archive/` - NEVER deleted
- Project deliverables (modified via symlinks, now committed)
- Git history (if commit was made)

### 6. Confirm Completion

```
✓ Task "[task-name]" completed
[If git commit]: ✓ Changes committed: [commit summary]
✓ Task directory removed
✓ Artifacts preserved in archive/

Context preserved in:
- Git commit (deliverable changes)
- Archive files (artifacts)
```

## Guidance

**When to end a task:**
- Success criteria from README are met
- Work is done (or abandoned)
- Ready to move on to something else

**If task isn't done yet:**
Use "checkpoint" to save progress instead - keeps task active for next session.

**Archive persistence:**
Artifacts remain available for future tasks - no need to recreate analysis or scripts.