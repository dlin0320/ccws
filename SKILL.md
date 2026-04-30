---
name: ccws
description: Cognitive harness for developer-AI pairs. Two human gates, autonomous work between them, structured context that survives sessions, spec-driven review that catches semantic drift.
---

# Claude Code Workspace (CCWS)

## Purpose

A cognitive harness for developer-AI pairs working in Claude Code. The developer steers (plan approval, result approval); each flow executes autonomously when invoked (implement against success criteria, review against specs, reconcile divergences). The harness operates at the intent layer — specifying *what* to verify and preserve, not *how* — so implementations adapt as models improve.

**Architecture:** Tasks in `.claude-workspace/task/` organize work with README + symlinks. Artifacts in `archive/` persist across tasks. Deliverables stay in the project. Context preserved via task READMEs (WIP), git commits (completed), and structured task files (FEEDBACK, SUMMARY). Context types have explicit lifespans: progress notes are durable, git history is immutable, archive artifacts are cross-task.

**Branch-bound, in place:** Each task is bound to a branch. prep-task checks out a new branch `{type}/{name}` (feat/fix/refactor/etc.) in the current repo — no worktree, no session switch — and end-task pushes it and opens a PR. Task directories are flat: the branch name flattens to dashes, so `feat/auth-refresh` → `task/feat-auth-refresh/`. Task resolution is via `git rev-parse --abbrev-ref HEAD` with that transform applied. See `references/patterns.md § Task Directory Naming`. If the user wants to run concurrent tasks, they create a worktree manually (`git worktree add ...`) before running prep-task; cleanup-task detects and removes any such worktree.

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
| **review-task** | "review", "audit", "check implementation" | **Subagent** | `flows/review-task-flow.md` |
| **reconcile-task** | "reconcile", "resolve findings", "fix review items", address FEEDBACK.md | Inline | `flows/reconcile-task-flow.md` |
| **summarize-task** | "summarize", "wrap up" | Inline | `flows/summarize-task-flow.md` |
| **end-task** | "end task", task objectives achieved | Inline | `flows/end-task-flow.md` |
| **triage-pr-review** | "triage pr review", "ingest bot review", "check claude bot feedback" | **Subagent** | `flows/triage-pr-review-flow.md` |
| **cleanup-task** | "cleanup task", after PR merges | Inline | `flows/cleanup-task-flow.md` |

## Development Loop

Two human gates bracket the work. Each flow executes autonomously when invoked. Today the user drives flow progression; full autonomy between gates is the design trajectory.

```
prep → [GATE 1: plan approved] → implement ↔ review ↔ reconcile → summarize → [GATE 2: result approved]
     → end-task (PR opens) → triage-pr-review ↔ reconcile → push fixes
     → (PR merges externally) → cleanup-task
```

The implement/review/reconcile cycle repeats as needed before Gate 2. After the PR opens, the triage/reconcile cycle mirrors the pre-gate one — same shape, external source. Cleanup is a separate, post-merge phase with its own preconditions (merged PR, clean tree, not currently on the branch). For mid-session context relief use `/compact`; cross-session handoff is via README + git, kept current by implement/reconcile naturally.

## Flow Contracts

What each flow reads and produces — use this to trace data flow and debug issues.

| Flow | Reads | Produces | Gate |
|------|-------|----------|------|
| **setup** | — | `.claude-workspace/` structure, `.gitignore`, `CLAUDE.md` maintenance block | — |
| **prep-task** | User input; README (if resuming) | Branch `{type}/{name}` checked out in current repo, task dir, `README.md` | Gate 1: user approves plan |
| **implement-task** | README, symlinked refs + code | Code changes, README progress note | — |
| **review-task** | README, symlinked refs + code, prior FEEDBACK.md | `FEEDBACK.md` in task dir | — |
| **reconcile-task** | FEEDBACK.md, README, specs, code | Code fixes, spec updates, README design decisions | — |
| **summarize-task** | README, FEEDBACK.md, git diff | `SUMMARY.md` in task dir | Gate 2: user reviews summary |
| **end-task** | SUMMARY.md or README, git status | Git commits, pushed branch, pull request | — |
| **triage-pr-review** | PR reviews + comments (via `gh`), README, prior FEEDBACK.md | `## PR Review Findings` section appended to FEEDBACK.md; README progress note | — |
| **cleanup-task** | `gh pr view` state, `git worktree list`, task dir | Task dir deleted; worktree removed if one existed. Local branch + remote-tracking refs kept by default; `--delete-branch` opts in to full teardown. | — |

## References

- **`references/rules.md`** — Structural invariants and terminology. The non-negotiable constraints on workspace architecture.
- **`references/patterns.md`** — Shared templates, formats, and operational procedures. Referenced by flows via `§ Section` anchors.
