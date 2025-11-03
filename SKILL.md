---
name: ccws
description: Claude Code Workspace management. Task-based organization with symlinks for development artifacts, keeping main project clean.
---

# Claude Code Workspace (CCWS)

## Purpose

Provides `.claude-workspace/` with task-based organization for Claude's development artifacts, using symlinks to manage files efficiently across tasks while keeping the main project clean.

**Architecture:** Task directories in `current/`, permanent artifacts in `archive/`. Context preserved via task READMEs (WIP) and git commits (completed work).

## What This Skill Provides

### Workspace Setup
- Creates directory structure: current/, archive/
- Appends conventions to ~/.claude/Claude.md (global, applies to all projects)
- Updates .gitignore
- Rules and examples remain in skill (single source of truth)

### Task Management Flows
- **start-task**: Begin work (creates new task or resumes existing)
- **checkpoint-task**: Update README with progress notes
- **end-task**: Git commit (if deliverables changed) + clean up

## When to Use

- **Setup**: User requests workspace setup or `.claude-workspace/` doesn't exist
- **Update**: User says "update workspace docs" or "sync conventions" (updates global ~/.claude/Claude.md)
- **Start/Resume Task**: User says "start [task]", "resume [task]", or "start working on [X]"
- **Checkpoint**: User says "checkpoint" or "save progress"
- **End Task**: User says "end task" or task objectives achieved

## How It Works

1. **Tasks** live in `current/[task-name]/` with README + symlinks
2. **Artifacts** created in `archive/[type]/` and symlinked to tasks
3. **Deliverables** can be symlinked to tasks for context (safe to edit)
4. **Progress** saved via README updates (checkpoint-task flow)
5. **Completion** creates git commit (if deliverables changed) + removes task directory
6. **Context** preserved in: task README (WIP), git commits (completed), archive (artifacts)

## Available Flows

- `flows/setup-flow.md` - Initialize workspace and global conventions
- `flows/update-flow.md` - Sync ~/.claude/Claude.md with latest conventions
- `flows/start-task-flow.md` - Start work (new or existing task)
- `flows/checkpoint-task-flow.md` - Update README with progress
- `flows/end-task-flow.md` - Git commit + clean up task

## After Setup

Claude uses workspace automatically:
1. Reads ~/.claude/Claude.md → global workspace conventions apply
2. Follows REQUIRED rules from skill → architecture constraints
3. References skill examples → usage patterns
4. Uses standard tools with symlink workflow

**Note:** Project-specific context goes in project CLAUDE.md. Global workspace conventions are in ~/.claude/Claude.md and apply to all projects.