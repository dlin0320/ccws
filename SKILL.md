---
name: ccws
description: Claude Code Workspace management. Task-based organization with symlinks for development artifacts, keeping main project clean.
---

# Claude Code Workspace (CCWS)

## Purpose

Provides `.claude-workspace/` with task-based organization for Claude's development artifacts, using symlinks to manage files efficiently across tasks while keeping the main project clean.

**Architecture:** Task directories in `task/`, permanent artifacts in `archive/`. Context preserved via task READMEs (WIP) and git commits (completed work).

## What This Skill Provides

### Workspace Setup
- Creates directory structure: task/, archive/
- Updates .gitignore
- Rules and examples remain in skill (single source of truth)

### Task Management Flows
- **start-task**: Begin work (creates new task or resumes existing) — Gate 1: user reviews README
- **implement-task**: Execute implementation based on README success criteria
- **checkpoint-task**: Update README with progress notes and design decisions
- **snapshot-task**: Capture implementation structure for subagent consumption
- **review-task**: Review implementation against design docs, cross-referencing documented decisions
- **reconcile-task**: Resolve review findings (fix code, update spec, or document decision)
- **summarize-task**: Generate user-facing summary of what was built — Gate 2: user reviews before commit
- **end-task**: Incremental git commits (from SUMMARY.md) + clean up

## Flows

Flows vary in context cost. Heavy flows MUST run as subagents to keep the main conversation clean. Inline flows execute directly in the main context.

When spawning a subagent, resolve the flow file path relative to this skill's directory and pass the absolute path in the agent prompt.

| Flow | Triggers | Execution | Flow file |
|------|----------|-----------|-----------|
| **setup** | "setup workspace", or `.claude-workspace/` doesn't exist | Inline | `flows/setup-flow.md` |
| **start-task** | "start [task]", "resume [task]", "start working on [X]" | Inline | `flows/start-task-flow.md` |
| **implement-task** | "implement", "build it", "go" | **Subagent** | `flows/implement-task-flow.md` |
| **checkpoint-task** | "checkpoint", "save progress" | Inline | `flows/checkpoint-task-flow.md` |
| **snapshot-task** | "snapshot", "capture state" | Inline | `flows/snapshot-task-flow.md` |
| **review-task** | "review", "audit", "check implementation" | **Subagent** | `flows/review-task-flow.md` |
| **reconcile-task** | "reconcile", "resolve findings", "fix review items", address FEEDBACK.md | **Subagent** | `flows/reconcile-task-flow.md` |
| **summarize-task** | "summarize", "wrap up" | Inline | `flows/summarize-task-flow.md` |
| **end-task** | "end task", task objectives achieved | Inline | `flows/end-task-flow.md` |

**Automatic behavior** (not a flow — configured in project CLAUDE.md by setup-flow):
- **Turn logging** — after each substantive turn with an active task, append a summary to `task/[task-name]/TURNS.md`. Checkpoint distills TURNS.md into structured README progress notes.

## Development Loop

Two human gates, autonomous between them:

```
start → [GATE 1: user reviews README] → implement → review → reconcile → iterate → summarize → [GATE 2: user reviews summary] → end
```

Checkpoint and snapshot can be invoked at any point during the loop to save context.

## How It Works

1. **Tasks** live in `task/[task-name]/` with README + symlinks
2. **Artifacts** created in `archive/[type]/` and symlinked to tasks
3. **Deliverables** can be symlinked to tasks for context (safe to edit)
4. **Turn logging** captures per-turn summaries in TURNS.md (automatic, timestamped, with agent tags for subagent entries)
5. **Start** creates README and gates for user approval (Gate 1)
6. **Implement** executes the plan autonomously as a subagent
7. **Checkpoint** distills TURNS.md + conversation into structured README progress notes
8. **Snapshot** captures current implementation structure in SNAPSHOT.md (feeds into review/reconcile)
9. **Review** checks implementation against specs, writes FEEDBACK.md
10. **Reconcile** resolves review findings by fixing code, updating specs, or documenting decisions
11. **Summarize** generates user-facing summary and gates for user approval (Gate 2)
12. **End** creates incremental git commits (from SUMMARY.md) + removes task directory
13. **Context** preserved in: task README (WIP), TURNS.md (current session), SNAPSHOT.md (code state), git commits (completed), archive (artifacts)
