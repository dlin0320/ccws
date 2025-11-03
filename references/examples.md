# Workspace Examples

Practical patterns for task-based workflow with symlinks.

## Key Concepts

**Artifact** = BY Claude FOR Claude → Must be in archive/
**Deliverable** = Project files → Live in project, can symlink to task
**Task** = Temporary workspace → README + symlinks, deleted when complete
**Context** = WIP in README, completed work in git, artifacts in archive

## Starting a New Task

**Scenario:** User says "Let's debug the authentication issue"

**Actions:**
1. Create task: "start task" → interactive flow
2. Create `current/auth-debug/README.md` with objectives
3. Work in task context

```bash
# Task creation
mkdir -p .claude-workspace/current/auth-debug

# README with context
cat > .claude-workspace/current/auth-debug/README.md << EOF
# Task: auth-debug

**Started:** 2025-10-28 14:30

## Objective
Debug and fix authentication failures on mobile app

## Context
Users reporting intermittent login failures, only on mobile

## Success Criteria
Mobile auth works reliably, root cause identified

## Progress Notes
<!-- Added with "checkpoint" command -->
EOF
```

## Creating Artifacts During Tasks

**Scenario:** Writing analysis while working on auth-debug task

**Actions:**
1. Create in archive/ for permanence
2. Symlink to current task

```bash
# 1. Create artifact in archive
Write .claude-workspace/archive/docs/mobile-auth-analysis.md

# 2. Symlink to task
ln -s ../../archive/docs/mobile-auth-analysis.md \
      .claude-workspace/current/auth-debug/analysis.md
```

**Result:** Artifact accessible in task, preserved in archive after task deletion

## Linking Project Deliverables

**Scenario:** Need to modify auth.ts for the fix

**Actions:**
```bash
# Link project file to task directory (safe to edit through symlink)
ln -s ../../src/auth.ts \
      .claude-workspace/current/auth-debug/auth.ts

# Edit through symlink - changes go to actual file
# Path makes it clear: ../../src/ = deliverable
```

**Result:** Deliverable accessible in task context, edits apply to actual file

## Creating Helper Scripts

**Scenario:** Need script to test auth endpoints

**Actions:**
```bash
# Create in archive/scripts/
Write .claude-workspace/archive/scripts/test-mobile-auth.sh

# Symlink to task
ln -s ../../archive/scripts/test-mobile-auth.sh \
      .claude-workspace/current/auth-debug/test-script.sh

# Make executable (on archive file)
chmod +x .claude-workspace/archive/scripts/test-mobile-auth.sh
```

## Mid-Task Checkpoint

**Scenario:** User says "checkpoint" or switching context

**Actions:**
1. Update task README Progress Notes section
2. Continue working or switch tasks

**Updated README:**
```markdown
# Task: auth-debug

**Started:** 2025-10-28 14:30

## Objective
Debug and fix authentication failures on mobile app

## Context
Users reporting intermittent login failures, only on mobile

## Success Criteria
Mobile auth works reliably, root cause identified

## Progress Notes
- Identified token expiration issue in auth.ts
- Created test script for reproduction
- Narrowed down to refresh token handling
- Next: Get mobile app logs from user, implement fix
```

**Result:** README preserves WIP state for next session or agent handoff

## Finding Previous Work

**Scenario:** User asks "Did we work on auth before?"

**Actions:**
```bash
# Check git commits
git log --oneline --grep="auth" -10
git log --oneline --grep="Task:" -10

# Search archive for auth-related artifacts
find .claude-workspace/archive/ -name "*auth*" -type f

# Search artifact contents
grep -r "authentication" .claude-workspace/archive/docs/

# Check active tasks
ls .claude-workspace/current/
```

**Context sources:**
- Git commits = completed work on deliverables
- Archive = artifacts from past work
- current/ = active WIP

## Resuming After Context Reset

**Scenario:** New session, need to continue task

**Actions:**
1. Check for active tasks
2. Read task README for context
3. Continue from Progress Notes

```bash
# Check if task still active
ls .claude-workspace/current/

# Read README to understand current state
cat .claude-workspace/current/auth-debug/README.md

# Progress Notes show latest state and next steps
# Continue from there
```

## Ending a Task

**Scenario:** User says "end task" or objectives achieved

**Actions:**
1. Check if deliverables were modified
2. Create git commit (if yes)
3. Delete task directory
4. Artifacts remain for future use

```bash
# Check what changed
git status

# If deliverables modified: commit with context from README
git add src/auth.ts
git commit -m "$(cat <<'EOF'
Fix mobile auth token expiration issue

Identified and fixed refresh token handling bug causing
intermittent login failures on mobile app.

- Updated token expiration logic in auth.ts
- Added proper refresh token rotation
- Verified fix with test script

Task: auth-debug
EOF
)"

# Delete task directory (only README and symlinks)
rm -rf .claude-workspace/current/auth-debug

# Artifacts preserved in archive:
# - archive/docs/mobile-auth-analysis.md
# - archive/scripts/test-mobile-auth.sh
```

**Result:**
- Deliverable changes in git history
- Artifacts available for future tasks
- Task workspace cleaned up

## Cross-Task File Reuse

**Scenario:** New task needs file from previous work

**Actions:**
```bash
# Starting task "improve-auth"
mkdir -p .claude-workspace/current/improve-auth

# Link existing analysis from archive
ln -s ../../archive/docs/mobile-auth-analysis.md \
      .claude-workspace/current/improve-auth/previous-analysis.md

# Create modified version if needed
cp .claude-workspace/archive/docs/mobile-auth-analysis.md \
   .claude-workspace/archive/docs/mobile-auth-analysis-v2.md
# Then symlink the new version
```

## Agent Handoff

**Scenario:** Different agent/session needs to continue

**What receiving agent does:**
1. Check for active tasks: `ls .claude-workspace/current/`
2. Read task README for context
3. Check git log for recent work: `git log --oneline -10`
4. Search archive for relevant artifacts

**Context sources:**
- Task README = current WIP
- Git history = completed work
- Archive = reusable artifacts

## Archive Maintenance

**Scenario:** Archive getting large (>50MB) or old (>30 days)

**Actions:**
```bash
# Check archive size
du -sh .claude-workspace/archive/

# Find old artifacts
find .claude-workspace/archive/ -mtime +30 -type f

# Review before deleting (don't auto-delete)
# Check git history to see if artifact still relevant
git log --oneline --all -- "description of artifact"
```

## Key Patterns

**Task-Focused Work:**
- All relevant files (artifacts + deliverables) in one task directory via symlinks
- Easy to see everything for current work
- Clean separation between tasks

**Symlink Benefits:**
- Artifacts: No duplication, persist after task deletion
- Deliverables: Link for context, safe to edit
- Path makes intent clear: `archive/` vs `src/`

**Context Preservation:**
- WIP: Task README (updated with "checkpoint")
- Completed: Git commits (derived from README)
- Artifacts: Archive files (permanent, reusable)

**Clean Workspace:**
- Active work in `current/` (temporary)
- Reusable artifacts in `archive/` (permanent)
- Completed work in git history (permanent)
- Aggressive task cleanup (30 days, 50MB thresholds)