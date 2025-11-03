# Start-Task Flow - Begin or Resume Work

Start working on a task (creates new task if needed, or resumes existing one).

## Purpose
Begin work on a task, whether it's brand new or already exists from a previous session.

## Outcome (Required)
- [ ] Task is ready for work (either created or resumed)
- [ ] README.md exists with: Objective, Context, Success Criteria, Progress Notes
- [ ] User understands the objective and current state

## Constraints (Required)
Per workspace REQUIRED RULES:
- Task directory in `current/` only
- README.md is only file created in task directory
- All other files created in `archive/` and symlinked (see "File Creation During Task")

## Process

### 1. Determine Task Name
Extract from user input or ask: "What should we call this task?"
- Use kebab-case: `auth-fix`, `api-refactor`
- Short and descriptive

### 2. Check if Task Exists

```bash
ls -d .claude-workspace/current/[task-name] 2>/dev/null
```

**If task exists** → Go to Step 3A (Resume)
**If task doesn't exist** → Go to Step 3B (Create)

### 3A. Resume Existing Task

Task already exists - show context and get ready to work:

```bash
# Read the README
cat .claude-workspace/current/[task-name]/README.md

# List current symlinks
ls -la .claude-workspace/current/[task-name]/
```

**Confirm resumption:**
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
mkdir -p .claude-workspace/current/[task-name]
```

Create `.claude-workspace/current/[task-name]/README.md` using template below.

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

## Progress Notes
[Ordered list of progress updates - added during "checkpoint"]
```

#### Initial Linking (Lazy)

**Don't search extensively.** Only symlink:
- Resources explicitly mentioned by user
- Obviously relevant deliverables (if user said "fix auth.ts", link it)

```bash
# Example: User mentioned fixing auth
ln -s ../../src/auth.ts .claude-workspace/current/[task]/auth.ts
```

Add more symlinks as work progresses and needs become clear.

#### Confirm Creation

```
✓ Task created: current/[task-name]/
✓ README documents objective and success criteria
✓ Ready to work

As you work:
- Create artifacts in archive/[type]/, symlink to task
- Symlink deliverables for context (safe to edit)
- Update README with "checkpoint" to save progress
```

### 4. Ready to Work

Whether you resumed or created the task, you're now ready to start working. Use the symlinked files, create new artifacts in archive/ as needed, and remember to checkpoint progress to the README.

## File Creation During Task (REQUIRED)

**Per workspace REQUIRED RULES:** All artifacts MUST be created in archive/ and symlinked to task.

### Creating Artifacts

```bash
# 1. Create in archive
echo "content" > .claude-workspace/archive/[type]/filename

# 2. Symlink to task
ln -s ../../archive/[type]/filename .claude-workspace/current/[task]/filename
```

### Linking Deliverables (for context)

```bash
# Link project file to task directory (safe to edit through symlink)
ln -s ../../src/auth.ts .claude-workspace/current/[task]/auth.ts
```

**Path makes intent clear:**
- `../../archive/` = artifact (created by Claude)
- `../../src/`, `../../lib/`, etc. = deliverable (project file)

**DO NOT create artifacts in `current/[task]/`** - Violates workspace architecture.

## Guidance

- **Start vs Resume**: Flow handles both automatically - just say "start [task-name]"
- **Task scope**: One conceptual unit of work
- **Lazy linking**: Add symlinks as needed, not all upfront
- **Multi-session**: Tasks can span sessions - use "checkpoint" to save progress
- **Completion**: "end task" creates git commit + deletes task directory
- **Finding context**: When resuming, README + progress notes + symlinks tell the full story