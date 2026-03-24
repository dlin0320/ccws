# Start-Task Flow - Begin or Resume Work

> **Execution:** Run inline in the main context.

Start working on a task (creates new task if needed, or resumes existing one).

## Purpose
Begin work on a task, whether it's brand new or already exists from a previous session.

## Outcome (Required)
- [ ] Task is ready for work (either created or resumed)
- [ ] README.md exists with: Objective, Context, Success Criteria, Progress Notes
- [ ] User understands the objective and current state

## Constraints (Required)
Per workspace REQUIRED RULES:
- Task directory in `task/` only
- README.md is only file created in task directory
- All other files created in `archive/` and symlinked (see "File Creation During Task")

## Process

### 1. Determine Task Name
Extract from user input or ask: "What should we call this task?"
- Use kebab-case: `auth-fix`, `api-refactor`
- Short and descriptive

### 2. Check if Task Exists

```bash
ls -d .claude-workspace/task/[task-name] 2>/dev/null
```

**If task exists** → Go to Step 3A (Resume)
**If task doesn't exist** → Go to Step 3B (Create)

### 3A. Resume Existing Task

Task already exists - show context and get ready to work:

```bash
# Read the README
cat .claude-workspace/task/[task-name]/README.md

# List current symlinks
ls -la .claude-workspace/task/[task-name]/

# Check for broken symlinks
find .claude-workspace/task/[task-name]/ -type l ! -exec test -e {} \; -print
```

**If broken symlinks are found:**
List them and warn:
```
⚠ Found broken symlinks (targets no longer exist):
  - [symlink] → [target]
These may indicate deleted archive files or moved project files.
Remove broken symlinks? (yes/no)
```
If yes: remove the broken symlinks. If no: proceed but warn that broken symlinks may cause errors in subagent flows.

**Check for README changes since last user review:**
- If the `## Design Decisions` section is non-empty, OR progress notes contain reconcile entries the user may not have seen:
  - Display the full README content and note: "README has been updated since your last review (design decisions and/or reconcile changes). Please review before continuing."
  - Wait for user confirmation before proceeding (re-gate).
- Otherwise, use abbreviated confirmation:

```
✓ Resuming task: [task-name]
✓ Objective: [from README]
✓ Current state: [latest progress note from README]

Ready to continue work. Current symlinks:
- [list of symlinked files]
```

Then proceed to Step 4.

### 3B. Create New Task

Task doesn't exist - gather context and create it.

#### Gather Context (Flexible)
Extract from user's message or ask targeted questions:
- **Objective**: What are we trying to achieve?
- **Context**: Why this task? What prompted it?
- **Success criteria**: How will we know it's done?

**Note**: User may provide structured requirements, paste entire specs, or give brief description. Adapt - get what you need however you can. If information is missing or unclear, ask specific questions.

#### Create Task Directory and README

```bash
mkdir -p .claude-workspace/task/[task-name]
```

Create `.claude-workspace/task/[task-name]/README.md` using template below.

#### README Template

Fill in what you have from user's input:

```markdown
# Task: [task-name]

**Started:** YYYY-MM-DD HH:MM

## Objective
[What we're trying to achieve - be specific]

## Context
[Why this task? What prompted it? Any background]

## Success Criteria
[How will we know it's done? Specific, testable conditions]

## Design Decisions
<!-- Intentional divergences from spec — added during checkpoint or reconcile -->

## Progress Notes
[Ordered list of progress updates - added during "checkpoint"]
```

#### Initial Linking (Lazy)

**Don't search extensively.** Only symlink:
- Resources explicitly mentioned by user
- Obviously relevant deliverables (if user said "fix auth.ts", link it)

```bash
# Example: User mentioned fixing auth
ln -s ../../src/auth.ts .claude-workspace/task/[task]/auth.ts
```

Add more symlinks as work progresses and needs become clear.

#### Confirm Creation (Gate 1)

Display the full README content, then pause for user review:

```
✓ Task created: task/[task-name]/

[Display full README.md content]

Review the objective and success criteria above. Confirm to begin implementation.
```

Do NOT proceed to implementation automatically. Wait for user confirmation. If the user requests changes, update the README and re-display.

### 4. Ready to Work

**4A. After resume (3A):** If the README was re-gated (design decisions or reconcile changes detected), user confirmation was obtained in Step 3A. Otherwise, the README was approved in a prior session and has not been substantively modified. Proceed:
```
✓ Resuming task: [task-name]
✓ Ready to continue work.
```

**4B. After create (3B):** Gate 1 is active — the flow is complete. The main context waits for user confirmation before invoking implement-task or proceeding with manual work.

## File Creation During Task (REQUIRED)

**Per workspace REQUIRED RULES:** All artifacts MUST be created in archive/ and symlinked to task.

### Creating Artifacts

```bash
# 1. Create in archive
echo "content" > .claude-workspace/archive/[type]/filename

# 2. Symlink to task
ln -s ../../archive/[type]/filename .claude-workspace/task/[task]/filename
```

### Linking Deliverables (for context)

```bash
# Link project file to task directory (safe to edit through symlink)
ln -s ../../src/auth.ts .claude-workspace/task/[task]/auth.ts
```

**Path makes intent clear:**
- `../../archive/` = artifact (created by Claude)
- `../../src/`, `../../lib/`, etc. = deliverable (project file)

**DO NOT create artifacts in `task/[task]/`** - Violates workspace architecture.

## Guidance

- **Start vs Resume**: Flow handles both automatically - just say "start [task-name]"
- **Task scope**: One conceptual unit of work
- **Lazy linking**: Add symlinks as needed, not all upfront
- **Multi-session**: Tasks can span sessions - use "checkpoint" to save progress
- **Completion**: "end task" creates git commit + deletes task directory
- **Finding context**: When resuming, README + progress notes + symlinks tell the full story