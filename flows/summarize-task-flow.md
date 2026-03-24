# Summarize-Task Flow - User-Facing Implementation Summary

> **Execution:** Run inline in the main context.

Produce a developer-facing implementation summary showing what was built and how it works. This summary serves two purposes: (1) developer review at Gate 2 (can they understand and verify the implementation?), and (2) input for end-task commit message generation.

## Outcome (Required)
- [ ] SUMMARY.md written to task directory
- [ ] Summary reflects current implementation state and current specs (post-reconciliation)
- [ ] Summary displayed for user review
- [ ] User can decide whether to proceed to end-task

## Constraints (Required)
- SUMMARY.md is a task management file (lives in task directory)
- Content must reflect current state, not original spec (specs may have evolved during reconciliation)
- Developer-facing: concrete, technical, reviewable — a developer should be able to verify the implementation from this summary
- Feeds into end-task for commit messages — should contain the "what" and "why" at a level suitable for git history
- Project-agnostic — no hardcoded conventions

## Process

### 1. Identify Active Task

```bash
ls -d .claude-workspace/task/*/ 2>/dev/null
```

If no tasks: "No active task to summarize."
If multiple: Ask which task.

### 2. Gather Context

Read from these sources (all optional — use what exists):

1. **Task README** — objective, success criteria, design decisions, progress notes
2. **SNAPSHOT.md** — structural details (if exists)
3. **FEEDBACK.md** — resolved/deferred findings (if exists)
4. **Conversation context** — recent work not yet checkpointed
5. **TURNS.md** — session history (if exists)
6. **git diff / git status** — actual file changes

Prioritize current state over historical narrative.

### 3. Write SUMMARY.md

Write to `.claude-workspace/task/[task-name]/SUMMARY.md`:

```markdown
# Task Summary — {task-name}

**Date:** YYYY-MM-DD

## Objective
[Restate the objective — use current version from README, which may have evolved]

## Implementation

### [Component/Package/Area name]
[What was added or changed. Show key interfaces, function signatures, or types
that a reviewer needs to understand. Include brief code snippets for non-obvious
logic. Explain *how* things connect, not just *that* they exist.]

### [Next component...]
[Repeat per logical component. Each section should give the developer enough
detail to understand the implementation without reading every line of code.]

## Files Changed
[Deliverables created or modified, grouped by component. For each file:
one line describing what changed and why.]

## Success Criteria
| Criterion | Status | Notes |
|-----------|--------|-------|
| [criterion from README] | Met / Partial / Deferred | [how it was met — reference specific code] |

## Key Decisions
[Design decisions that affect the implementation. Include the rationale.
Pull from README Design Decisions and FEEDBACK.md resolutions.
Only decisions a reviewer needs to understand — skip trivial ones.]

## Deferred Items
[What was explicitly deferred and why. Pull from FEEDBACK.md deferred table if exists.]
```

Sections can be omitted if empty (e.g., no Deferred Items).

### 4. Present for Review (Gate 2)

Display the full SUMMARY.md content, then pause:

```
[Full SUMMARY.md content]

Review the summary above. Confirm to finalize (ccws end-task).
```

Do NOT proceed to end-task automatically. Wait for user confirmation. If the user requests changes, update SUMMARY.md and re-display.

## Guidance

**Summarize vs Snapshot:**
Snapshot is agent-facing (structural index for subagent consumption). Summarize is developer-facing (implementation review with enough detail to verify correctness). Snapshot is a map; summarize is a walkthrough.

**Summarize vs Checkpoint:**
Checkpoint captures incremental progress (what happened this session). Summarize captures the final implementation (what exists now, how it works). Not a status report — a technical walkthrough.

**When specs changed during reconciliation:**
The summary should reflect the post-reconciliation reality. If the design doc was updated to match the implementation, note that in Key Decisions but don't flag it as a divergence.

**Implementation section:**
Show the developer what they need to verify. Key interfaces, important logic, how components connect. Include brief code snippets for non-obvious patterns. This is not a changelog — it's a technical walkthrough that lets the developer confirm the implementation is correct without reading every file.

**Files Changed section:**
Group logically (by package, component, or concern), not alphabetically. Each file gets one line explaining what changed and why — not just a flat list of paths.
