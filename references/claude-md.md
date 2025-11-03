<!--
This content is appended to ~/.claude/Claude.md during workspace setup.
It defines global workspace conventions that apply to all projects.
Project-specific context should go in project CLAUDE.md, not here.
-->

# Claude Code Workspace

This defines global conventions for `.claude-workspace/` with task-based organization for development artifacts.

**CRITICAL: This workspace is FOR Claude, BY Claude. Use it automatically in all projects.**

## Terminology

**Artifact** = Files BY Claude FOR Claude (analysis, scripts, logs) → Must be in workspace
**Deliverable** = Files for the project (source, tests, docs) → Lives in project
**Task** = Temporary unit of work in `current/[task]/` with README + symlinks
**Workspace** = `.claude-workspace/` (Claude's development environment)
**Project** = Main repository (everything outside workspace)

See ccws skill for detailed rules and examples.

## Workspace Structure

```
.claude-workspace/
├── current/      # Active tasks (README + symlinks)
└── archive/      # Permanent artifacts by type
    ├── docs/     # Analyses, documentation
    ├── scripts/  # Reusable automation
    ├── reports/  # Test results, benchmarks
    └── research/ # Experiments, comparisons
```

## Core Workflow (REQUIRED)

1. **Start task**: "start task" → create or resume `current/[task]/` with README
2. **Create artifacts**: ALWAYS in `archive/[type]/`, NEVER in `current/[task]/`
3. **Symlink to task**: Link artifacts AND/OR deliverables for context
   - Artifact: `ln -s ../../archive/docs/analysis.md current/[task]/`
   - Deliverable: `ln -s ../../src/auth.ts current/[task]/`
4. **Save progress**: "checkpoint" → update task README
5. **End task**: Git commit (if deliverables changed) + delete `current/[task]/`

## Decision: What Goes Where?

### ✅ .claude-workspace/ (Claude's workspace)

**Always store here:**
- Analysis reports about the codebase
- Helper scripts for testing/automation
- Test outputs, coverage reports
- Debug logs and execution traces
- Planning documents, research
- Experimental or prototype code

**Rule:** If it helps Claude but isn't part of project deliverables → `.claude-workspace/`

### ❌ Main Project Directory

**Only store here:**
- Project source code (`src/`, `lib/`)
- Project tests (`test/`, `__tests__/`)
- Project configuration (`package.json`)
- Project documentation (README.md)
- Build outputs (`dist/`, `build/`)

**Rule:** If it's part of project deliverables → main directory

## Mandate: Automatic Usage

**When creating ANY development artifact:**

1. Use `.claude-workspace/` automatically - NEVER ask where to save
2. Create artifacts in `archive/[type]/` - NEVER in `current/[task]/`
3. Symlink from archive to task if working on a task
4. Symlink deliverables to task for context (safe to edit)
5. Follow **REQUIRED RULES** from ccws skill

**NEVER:**
- Ask "where should I save this?"
- Create artifacts in `current/[task]/` (except README.md)
- Delete archive files when completing tasks
- Create dev artifacts in main project
- Skip using workspace

**The ccws skill defines REQUIRED architecture rules and provides usage examples.**

## Task Management

- **Start work**: "start task" or "resume task" → creates or resumes task directory with README
- **Save progress**: "checkpoint" → updates task README with progress notes
- **End task**: "end task" → git commit + delete task directory

## Check Before Creating

**Before starting work:**
- Check `git log` for recent related work
- Search `archive/` for reusable artifacts
- Look in `current/` for active tasks
- Avoid duplicating existing artifacts

## Details

**Note:** `.claude-workspace/` is gitignored and not committed to version control.

The ccws skill provides:
- REQUIRED architecture rules
- Recommended patterns and conventions
- Practical usage examples
- Flow definitions for task management