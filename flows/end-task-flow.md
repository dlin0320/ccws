# End-Task Flow - Finish and Clean Up

End task with git commit (if deliverables changed) and delete task directory.

## Purpose
Finalize completed work, preserve it in git history, and clean up task directory.

## Outcome (Required)
- [ ] Git commit created (if deliverables were modified)
- [ ] Task directory deleted: `current/[task-name]/`
- [ ] Artifacts remain in archive/
- [ ] User knows task is complete

## Constraints (REQUIRED)
Per workspace REQUIRED RULES:
- MUST delete task directory when complete
- MUST NOT delete or move archive files
- MUST NOT leave completed task directories in current/

## Process

### 1. Check for Active Task

```bash
ls -d .claude-workspace/current/*/ 2>/dev/null
```

If no tasks: "No active tasks to end."
If multiple: Ask which to end.

### 2. Check for Deliverable Changes

```bash
git status
```

Were project files (deliverables) modified during this task?

**If YES** → Proceed to Step 3 (Git Commit)
**If NO** (only artifacts created) → Skip to Step 4 (Delete Task)

### 3. Create Git Commit (Automatic)

**Derive commit message from task README:**
- Use task objective as commit summary
- Add context from README if relevant
- List key changes

```bash
# Example commit message derived from README
git add [modified deliverables]
git commit -m "$(cat <<'EOF'
[Objective from README - concise summary]

[Brief description of what was done]
[Key changes or decisions if relevant]

Task: [task-name]
EOF
)"
```

**Good habit:** Let task context inform commit message automatically.

### 4. Delete Task Directory (REQUIRED)

```bash
rm -rf .claude-workspace/current/[task-name]
```

**What gets deleted:**
- Task directory with README
- All symlinks in task directory

**What remains:**
- ALL artifacts in `archive/` - NEVER deleted
- Project deliverables (modified via symlinks, now committed)
- Git history (if commit was made)

### 5. Confirm Completion

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