---
name: ccws
description: Cognitive harness for developer-AI pairs. Two human gates, autonomous work between them, structured context that survives sessions, spec-driven review that catches semantic drift.
---

# Claude Code Workspace (CCWS)

## Purpose

A cognitive harness for developer-AI pairs working in Claude Code. The developer steers (plan approval, result approval); each flow executes autonomously when invoked (implement against success criteria, review against specs, reconcile divergences). The harness operates at the intent layer — specifying *what* to verify and preserve, not *how* — so implementations adapt as models improve.

**Architecture:** Tasks in `.claude-workspace/task/` organize work with README + symlinks. Artifacts in `archive/` persist across tasks. Deliverables stay in the project. Context preserved via task READMEs (WIP), git commits (completed), and structured task files (TURNS, SNAPSHOT, FEEDBACK, SUMMARY). Context types have explicit lifespans: turns are ephemeral, progress notes are durable, git history is immutable, archive artifacts are cross-task.

**Worktree-native:** Each task is bound to a branch. prep-task creates a branch `{type}/{name}` (feat/fix/refactor/etc.) and a sibling git worktree; end-task pushes the branch and opens a PR. The task dir path mirrors the branch name: `task/feat/auth-refresh/`. Task resolution throughout — including the turn-log hook — is via `git rev-parse --abbrev-ref HEAD`. Multiple worktrees = multiple concurrent tasks with no shared state problems.

## What This Skill Provides

### Workspace Setup
- Creates directory structure: task/, archive/
- Updates .gitignore
- Rules and patterns remain in skill (single source of truth)

### Task Management Flows
See the Flows table below for the full list with triggers, execution modes, and flow file paths.

## Flows

Flows vary in context cost. Heavy flows MUST run as subagents to keep the main conversation clean. Inline flows execute directly in the main context.

When spawning a subagent, resolve the flow file path relative to this skill's directory and pass the absolute path in the agent prompt.

| Flow | Triggers | Execution | Flow file |
|------|----------|-----------|-----------|
| **setup** | "setup workspace", or `.claude-workspace/` doesn't exist | Inline | `flows/setup-flow.md` |
| **prep-task** | "prep [task]", "start [task]", "resume [task]" | Inline | `flows/prep-task-flow.md` |
| **implement-task** | "implement", "build it", "go" | **Subagent** | `flows/implement-task-flow.md` |
| **checkpoint-task** | "checkpoint", "save progress" | Inline | `flows/checkpoint-task-flow.md` |
| **snapshot-task** | "snapshot", "capture state" | Inline | `flows/snapshot-task-flow.md` |
| **review-task** | "review", "audit", "check implementation" | **Subagent** | `flows/review-task-flow.md` |
| **reconcile-task** | "reconcile", "resolve findings", "fix review items", address FEEDBACK.md | Inline | `flows/reconcile-task-flow.md` |
| **summarize-task** | "summarize", "wrap up" | Inline | `flows/summarize-task-flow.md` |
| **end-task** | "end task", task objectives achieved | Inline | `flows/end-task-flow.md` |

**Automatic behavior** (not a flow — installed by setup-flow as a hook):
- **Turn logging** — the turn-log hook fires on `Stop` (main session) and `SubagentStop` (subagent completion). It resolves the active task from the current git branch and appends a one-line entry to `task/<branch>/TURNS.md`. Checkpoint distills TURNS.md into structured README progress notes. See `references/patterns.md § Turn Logging`.

> **Note:** Setup installs a hook in the project's `.claude/settings.json` — the one deliberate write outside `.claude-workspace/`.

## Development Loop

Two human gates bracket the work. Each flow executes autonomously when invoked. Today the user drives flow progression; full autonomy between gates is the design trajectory.

```
prep → [GATE 1: user approves plan] → implement ↔ review ↔ reconcile → summarize → [GATE 2: user approves result] → end
```

The implement/review/reconcile cycle repeats as needed. Checkpoint and snapshot can be invoked at any point to save context.

## Flow Contracts

What each flow reads and produces — use this to trace data flow and debug issues.

| Flow | Reads | Produces | Gate |
|------|-------|----------|------|
| **setup** | — | `.claude-workspace/` structure, `.gitignore`, `.claude/settings.json` hook entries, `CLAUDE.md` maintenance block | — |
| **prep-task** | User input; README (if resuming) | Branch `{type}/{name}`, sibling worktree, task dir, `README.md` | Gate 1: user approves plan |
| **implement-task** | README, symlinked refs + code, SNAPSHOT.md | Code changes, README progress note | — |
| **checkpoint-task** | Conversation, TURNS.md, git state | README progress notes + design decisions; clears TURNS.md | — |
| **snapshot-task** | Conversation, TURNS.md, code | `SNAPSHOT.md` in task dir | — |
| **review-task** | README, symlinked refs + code, SNAPSHOT.md, prior FEEDBACK.md | `FEEDBACK.md` in task dir | — |
| **reconcile-task** | FEEDBACK.md, README, specs, code | Code fixes, spec updates, README design decisions | — |
| **summarize-task** | README, SNAPSHOT.md, FEEDBACK.md, git diff | `SUMMARY.md` in task dir | Gate 2: user reviews summary |
| **end-task** | SUMMARY.md or README, git status | Git commits, pushed branch, pull request | — |
| **turn-log hook** (automatic) | Stop / SubagentStop hook input | Entry appended to `task/{branch}/TURNS.md` | — |

## References

- **`references/rules.md`** — Structural invariants and terminology. The non-negotiable constraints on workspace architecture.
- **`references/patterns.md`** — Shared templates, formats, and operational procedures. Referenced by flows via `§ Section` anchors.
