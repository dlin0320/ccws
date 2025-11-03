# Checkpoint-Task Flow - Save Progress

Update task README with progress notes for continuity.

## Purpose
Save current progress in task README for multi-session work or context switches.

## Outcome (Required)
- [ ] Task README updated with new progress note
- [ ] Progress note includes what was done and current state
- [ ] User knows progress was saved

## Constraints (Required)
- Update existing task README, don't create separate files
- Maintain chronological order in Progress Notes section
- README remains in task directory

## Process

### 1. Identify Active Task

```bash
ls -d .claude-workspace/current/*/ 2>/dev/null
```

If no tasks: "No active task to checkpoint."
If multiple: Ask which task to update.

### 2. Add Progress Note

Append to the Progress Notes section in task README:

```markdown
## Progress Notes
- [Previous notes...]
- [New entry]: [What was accomplished], [Current state], [Next steps if known]
```

**What to capture:**
- What was accomplished since last update
- Current state (completed, in-progress, blocked)
- Any key decisions or findings
- Next steps if clear

**Ordering:** List maintains chronological order (newest at bottom or use timestamps)

### 3. Confirm Update

```
✓ Progress saved to: current/[task]/README.md
✓ Task context preserved for next session
```

## Guidance

**When to checkpoint:**
- Before context switch (working on something else)
- End of work session
- After completing a significant sub-task
- When user explicitly requests

**What if task spans multiple days:**
README maintains full history - latest entry shows current state.

**Format flexibility:**
Simple list works. Optional: add timestamps for clarity.
```markdown
- 2025-10-31: Analyzed auth flow, found token validation issue
- 2025-10-31: Created test script, confirmed bug, started fix
```

**Note:** When task ends, README context informs git commit message.
