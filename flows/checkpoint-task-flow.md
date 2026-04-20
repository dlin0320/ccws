# Checkpoint-Task Flow - Save Progress

> **Execution:** Run inline in the main context.

Update task README with progress notes and design decisions for continuity.

## Purpose
Save current progress in task README for multi-session work or context switches.

## Outcome (Required)
- [ ] Task README updated with new progress note
- [ ] Progress note includes what was done and current state
- [ ] Design decisions captured (if any divergences from specs occurred)
- [ ] User knows progress was saved

## Constraints (Required)
- Update existing task README, don't create separate files
- Maintain chronological order in Progress Notes section
- README remains in task directory

## Process

### 1. Identify Active Task

```bash
ls -d .claude-workspace/task/*/ 2>/dev/null
```

If no tasks: "No active task to checkpoint."
If multiple: Ask which task to update.

### 2. Gather Context

Build the progress note from available sources, in priority order:

1. **Conversation context** — if the current conversation has implementation/discussion history, use it directly
2. **TURNS.md** — if conversation context is missing (e.g., after `/clear`), read `task/[task-name]/TURNS.md` for turn-by-turn summaries since the last checkpoint
3. **Git state** — `git diff` and `git log` since the last checkpoint timestamp can supplement either source

If both conversation and TURNS.md are empty, there's nothing to checkpoint — say so and stop.

After writing the progress note, **clear TURNS.md** (delete its contents or the file). The turn log has been distilled into the checkpoint; keeping stale entries causes confusion in the next cycle.

### 3. Add Progress Note

Append to the Progress Notes section in task README:

```markdown
## Progress Notes
- [Previous notes...]
- [New entry]: [What was accomplished], [Current state], [Next steps if known]
```

**What to capture:**
- What was accomplished since last update
- Current state (completed, in-progress, blocked)
- Key findings
- Next steps if clear

**Ordering:** List maintains chronological order (newest at bottom or use timestamps)

### 3b. Capture Design Decisions (if any)

If work since the last checkpoint involved intentional divergences from reference docs or specs, update the README per `references/patterns.md § Design Decisions`.

### 4. Confirm Update

```
✓ Progress saved to: task/[task]/README.md
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

**Design decisions vs progress notes:**
Progress notes track what happened. Design decisions track why you diverged from a spec. If a decision also belongs in progress notes (because it was a significant milestone), reference it briefly in the progress note and put the full rationale in Design Decisions.

**Note:** When task ends, README context informs git commit message.
