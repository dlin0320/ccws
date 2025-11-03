# Update-Flow - Sync Global Workspace Conventions

Update `~/.claude/Claude.md` with latest ccws terminology and workflows.

## Purpose
Keep global workspace conventions in sync when the ccws skill evolves (terminology changes, new features, updated conventions).

## Outcome (Required)
- [ ] ~/.claude/Claude.md updated with latest workspace content
- [ ] Non-workspace sections preserved
- [ ] User notified of changes

## When to Use

- User requests "update workspace docs" or "sync workspace conventions"
- After major skill changes (terminology updates, new workflows)
- When workspace conventions are out of date

## Process

### 1. Check if Global Claude.md Exists

```bash
test -f ~/.claude/Claude.md && echo "Found" || echo "Not found"
```

**If not found:** Use setup-flow instead (will create it)
**If found:** Proceed to update

### 2. Read Current Global Claude.md

```bash
cat ~/.claude/Claude.md
```

Look for the workspace section, marked by:
- Heading: `# Claude Code Workspace`
- Mention of `.claude-workspace/`
- Task management terminology

**If section not found:** Append it (same as setup-flow)
**If section found:** Proceed to replacement

### 3. Replace Workspace Section

**Identify boundaries:**
- **Start marker:** `# Claude Code Workspace` heading
- **End marker:** Next top-level heading (`#`) or end of file
- **Preserve:** All content BEFORE and AFTER the workspace section

Read the canonical content:

```bash
cat ~/.claude/skills/ccws/references/claude-md.md
```

**Strategy:**
1. Extract content before workspace section
2. Insert latest workspace content from `references/claude-md.md`
3. Extract content after workspace section (if any)
4. Combine and write back to ~/.claude/Claude.md

**Example approach:**

```bash
# Find line number of workspace heading
START_LINE=$(grep -n "^# Claude Code Workspace" ~/.claude/Claude.md | cut -d: -f1)

# Find next top-level heading after workspace section
NEXT_HEADING=$(tail -n +$((START_LINE + 1)) ~/.claude/Claude.md | grep -n "^# " | head -1 | cut -d: -f1)

# Calculate end line
if [ -n "$NEXT_HEADING" ]; then
  END_LINE=$((START_LINE + NEXT_HEADING - 1))
else
  END_LINE=$(wc -l < ~/.claude/Claude.md)
fi
```

Then use Edit tool to replace the section in ~/.claude/Claude.md.

### 4. Confirm Update

```
✓ ~/.claude/Claude.md updated with latest workspace conventions
✓ Preserved existing non-workspace content
✓ Changes:
  - Updated terminology (start/end instead of new/complete)
  - Updated workflow descriptions
  - [List specific changes if major]

Global workspace conventions are now up to date across all projects.
```

## Guidance

**What gets replaced:**
- Entire `# Claude Code Workspace` section
- All subsections under it
- Everything from that heading to the next top-level `#` heading

**What gets preserved:**
- Any content before workspace section
- Any content after workspace section
- Other unrelated sections in global Claude.md

**Manual review recommended:**
- After update, quickly scan ~/.claude/Claude.md to ensure structure looks correct
- Check that non-workspace content wasn't affected

**Edge cases:**
- If workspace section is at end of file: Just replace to EOF
- If no workspace section found: Append it (same as setup-flow)
- If heavily customized: Warn user and ask for confirmation before replacing

**When to use:**
- After terminology changes (like new→start, complete→end)
- When new features are added to workspace
- When workflow conventions are updated

**Impact:**
- Updates apply globally to all projects using `.claude-workspace/`
- Project-specific context should be in project CLAUDE.md, not global file
