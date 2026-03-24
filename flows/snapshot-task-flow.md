# Snapshot-Task Flow - Capture Implementation State

> **Execution:** Run inline in the main context.

Generate a structured implementation snapshot for the active task. This snapshot serves as pre-built context for subagent flows (review, reconcile) and for resuming work in new sessions.

## Purpose
Capture the current state of the implementation so that future sessions and subagents can skip codebase discovery and go straight to analysis.

## Outcome (Required)
- [ ] `SNAPSHOT.md` written to task directory with current implementation state
- [ ] Snapshot reflects actual code, not just plans or specs
- [ ] User knows snapshot was saved

## Constraints (Required)
- SNAPSHOT.md lives in the task directory (task management file, like README.md and TURNS.md)
- Content must be derived from actual code and config, not from memory or conversation alone
- Keep it concise — this is a reference index, not documentation
- Project-agnostic — no hardcoded conventions

## Process

### 1. Identify Active Task

```bash
ls -d .claude-workspace/task/*/ 2>/dev/null
```

If no tasks: "No active task to snapshot."
If multiple: Ask which task.

### 2. Gather Context

Build the snapshot from available sources, in priority order:

1. **Conversation context** — if the current session has implementation knowledge, use it directly
2. **TURNS.md** — if conversation context is thin, read turn summaries for recently touched files and decisions
3. **Code inspection** — read symlinked implementation files and their sibling packages to fill gaps

For a fresh snapshot (no prior version), do a full scan of symlinked implementation files. For an update, focus on what changed since the last snapshot.

### 3. Write SNAPSHOT.md

Write to `.claude-workspace/task/[task-name]/SNAPSHOT.md` using this structure:

```markdown
# Implementation Snapshot — {task-name}

**Updated:** YYYY-MM-DD

## Project Structure
[Package tree with one-line purpose for each package]

## Core Interfaces
[Interface name, package, method signatures — the contracts everything depends on]

## Key Types
[Important structs, their fields, and which package owns them]

## Wiring
[How components connect: what registers what, what calls what, data flow through the pipeline]

## Files Index
[Key files with one-line descriptions — focus on files that matter for review/reconcile]

## Test Coverage
[Which packages have tests, what they cover, how to run them]

## Stubs and TODOs
[What's intentionally unimplemented, with tier/milestone references]
```

Sections can be omitted if not applicable to the task. Add sections if the implementation has aspects not covered above.

### 4. Confirm Update

```
✓ Snapshot saved to: task/[task]/SNAPSHOT.md
```

## Guidance

**When to snapshot:**
- Before switching sessions or clearing context (like checkpoint, but for code state)
- After significant implementation work that changes the structure
- Before running review-task (so the review agent gets a head start)

**Snapshot vs checkpoint:**
Checkpoint captures narrative (what happened, why). Snapshot captures structure (what exists, how it connects). They complement each other — checkpoint is the story, snapshot is the map.

**Staleness:**
A stale snapshot is better than no snapshot — subagents can verify claims against actual code. But if the implementation has changed significantly since the last snapshot, re-run before spawning heavy flows.

**How subagents use it:**
When spawning review-task or reconcile-task, the main context should read SNAPSHOT.md and include it in the subagent prompt as implementation context. This lets the agent skip discovery and go straight to analysis.
