# Shared Patterns

Reusable templates, formats, and operational patterns referenced by flow files. Read specific sections by heading.

## Task Directory Naming

The task directory key is the branch name with `/` replaced by `-`. Task directories are exactly one level deep — the `/` separator in branches like `feat/auth-refresh` is a git commit convention, not a filesystem layout.

- Branch `feat/auth-refresh` → task dir `task/feat-auth-refresh/`
- Branch `fix/issue-123` → task dir `task/fix-issue-123/`
- Branch `main` → no task dir (flows refuse to operate on main)

(If the user has manually created a worktree for this branch, its basename conventionally uses the same transform — e.g. `{repo}-feat-auth-refresh/` — but that's a user choice, not something the skill enforces.)

**Bash idiom — use this whenever a flow resolves the task dir from the current branch:**

```bash
branch=$(git rev-parse --abbrev-ref HEAD)
task_name="${branch//\//-}"
task_dir=".claude-workspace/task/$task_name"
```

User-facing path displays use the form `task/{task-name}/` where `{task-name}` is the flattened branch.

## Symlink Construction

From `task/[task-name]/`, use relative symlinks to reach targets:

- **Archive bundles** are siblings under `.claude-workspace/`, so the path is always `../../archive/{type}/{name}/filename` (per `§ Archive Shape`)
- **Deliverables** are outside `.claude-workspace/` — count `../` levels from the task directory up to the project root, then down to the file

Verify symlinks resolve correctly with `ls -la` after creation. Path distinguishes intent: symlinks into `archive/` are artifacts, symlinks outside `.claude-workspace/` are deliverables.

## Design Decisions

Record intentional divergences from reference docs or specs in the task README `## Design Decisions` section.

**Template:**

```markdown
### [Short title]
- **Spec:** [What the reference doc says, with section ref]
- **Decision:** [What we did instead]
- **Rationale:** [Why]
```

**When to add:**
- Chose a different approach than what a design doc specifies
- Deferred something the spec says to implement now
- Added something not in any spec (and the choice is non-obvious)
- Changed a convention from what docs describe

**When NOT to add:**
- The spec doesn't cover it (nothing to diverge from)
- It's a bug fix or straightforward implementation
- It's already documented in a previous decision

If the README doesn't have a `## Design Decisions` section yet, create one between Success Criteria and Progress Notes.

## Deferred Spec Items

When reconcile resolves a finding as `defer`, the deferral must be recorded somewhere that survives the task's cleanup. The referenced spec is the durable home — future tasks working on the same area will see what was explicitly deferred and why.

**Where to write:** the finding's `Reference:` field cites a spec document and section. Append to that spec's `## Deferred` (or `## Future Work`) section, creating the section at the end of the document if absent.

**Template:**

```markdown
## Deferred

- **[Short title]** — [what the spec originally required]
  - **Deferred:** YYYY-MM-DD (branch `{task-branch}`, PR #{N} if known)
  - **Rationale:** [why not now — scope, dependency, risk, cost]
  - **Trigger:** [event/milestone that should cause re-pickup]
```

**When the reference isn't durable:**
If the finding's only reference is the task README (task-scoped, not a spec), there is no durable file to update. Record the deferral as a Design Decision instead per `§ Design Decisions` — it flows into git history via the reconcile progress note and the end-task commit, which is the best available durability for task-scoped concerns.

**What survives cleanup:**
Specs (whether tracked in the repo or under `.claude-workspace/archive/`) are preserved by `cleanup-task`. FEEDBACK.md's Deferred Items table is still written for in-task tracking, but treat it as a working copy that dies with the task.

## Archive Shape

All `archive/[type]/` content uses name-keyed bundles, not loose files. Every artifact lives at `archive/{type}/{name}/` where `{name}` is a kebab-case identifier and the directory holds whatever files that artifact comprises (single writeup, multi-file investigation, script + helpers + sample data, etc.).

**Canonical entry file** — every bundle has one file that's the "start here":
- `archive/plans/{name}/PLAN.md` — plans have a defined spec role; the entry name reflects it
- `archive/investigations/{name}/README.md` — investigations vary in shape; README is the universal "start here"
- `archive/scripts/{name}/{script}.{ext}` — solo scripts ARE the entry; multi-file bundles add a `README.md`

**Why bundles:** real artifacts produce multiple files (writeup + raw data + processed output, or script + helper + sample input). The dir-as-bundle shape gives them a single home, and the directory name itself becomes searchable metadata. Loose files directly under `archive/[type]/` are forbidden — they break the type/name structure and re-create the "where does this go" ambiguity that nesting solves.

## Plans

When a multi-step plan drives several sequential tasks, persist it as a referenced spec in the workspace so each task can read the current plan state and reconcile can write deferrals back. Plans follow `§ Archive Shape` with `PLAN.md` as the canonical entry.

**Import:** copy the plan from its source (e.g., plan-mode's output dir) into the archive on first use, with a one-time human-friendly rename — validated per the same rules as task names (kebab-case, no denylist words, ≥12 chars or has hyphen). After import, the archive name is authoritative.

**The plan IS the referenced spec.** Reconcile's `## Deferred` promotion (`§ Deferred Spec Items`) targets PLAN.md when a task spawned from the plan defers something. This is what lets the plan absorb learnings across tasks — task N+1 reads PLAN.md and sees what task N decided not to do.

**Task linkage:**
- Each task spawned from the plan adds a `## Plan` section to its README pointing at `archive/plans/{plan-name}/PLAN.md`.
- PLAN.md has a `## Tasks` section listing constituent tasks (`{type}/{name}` per entry). Tasks append themselves at creation time.

**Lifecycle:** plan dirs persist past `cleanup-task` — the plan is a durable cross-task artifact, not task-scoped. Manual pruning is the user's call.

## PR Body Voice

SUMMARY.md is consumed verbatim as the PR body by `end-task`. The PR body is a formal artifact — read by reviewers, archaeologists, and release-notes writers who were never in the authoring conversation. Agent-conversational voice belongs in the chat, not in the artifact.

**Voice rules:**
- Third-person and declarative. State what the change is, what's in scope, what isn't.
- No first-person verbs: avoid "I", "I'll", "I'd", "I've", "we'll", "we'd", "we've", "my", "me" (in the voice sense — "my" in a code path is fine).
- No open questions to the reviewer: avoid "should I split this?", "do you want …?". The author makes the call; review comments are the place to renegotiate.
- No conversational offers: avoid "happy to", "let me know", "feel free to", "if preferred", "can fold this in".

**Follow-up / out-of-scope items:**
Future work is legitimate content but must be stated declaratively:

- ✅ "Out of scope: CI `gofmt` check. Tracked separately."
- ✅ "Follow-up: add CI `gofmt` check to prevent drift recurrence."
- ❌ "Happy to fold in a CI `gofmt` check if preferred — let me know."

The declarative form gives reviewers information. The conversational form invites a negotiation in a venue (the PR description) that isn't built for it.

**Enforcement:**
`end-task` performs a voice check on the prospective PR body before `gh pr create`: it scans for first-person and conversational markers, rewrites them in-place to declarative form where possible, and shows the final body to the user for confirmation. The rewrite preserves information — "Happy to fold in X if preferred" becomes "Follow-up: X." — rather than dropping content.

## Task Management Files

Files that live directly in the task directory (not symlinked from archive):

| File | Purpose | Created by |
|------|---------|------------|
| `README.md` | Objective, context, success criteria, design decisions, progress notes | prep-task |
| `FEEDBACK.md` | Review findings with classifications | review-task |
| `SUMMARY.md` | User-facing implementation summary | summarize-task |

## Conventions

### Naming
- **Tasks:** kebab-case, short, descriptive: `auth-refactor`, `bug-fix-1234`
- **Files:** lowercase with hyphens: `auth-analysis.md` (not `notes.md` or `temp.txt`)
- **Time-sensitive files:** date prefix: `2025-10-28-coverage.html`

### Concurrent Tasks
- Multiple tasks can coexist but should represent **independent work**
- If two tasks symlink the same deliverable, edits through either affect the same file — record state in each README before switching
- Prefer sequential tasks over concurrent when work overlaps on the same files
- When resuming, always check `ls .claude-workspace/task/` to see all active tasks

### File Metadata
Add header to workspace documentation for searchability:
```markdown
<!--
Purpose: [What this file does]
Created: [YYYY-MM-DD]
Task: [Associated task]
Tags: [Keywords]
-->
```

## Finding Previous Work

When searching for prior work on a topic:

1. **Git commits** — completed deliverable changes:
   ```bash
   git log --oneline --grep="[topic]" -10
   ```
2. **Archive** — artifacts from past tasks:
   ```
   Glob "*[topic]*" in .claude-workspace/archive/
   Grep "[topic]" in .claude-workspace/archive/investigations/
   ```
3. **Active tasks** — current WIP:
   ```
   Bash: ls .claude-workspace/task/
   ```

## Cross-Task File Reuse

Archive files persist after task deletion and can be symlinked to any future task. If a modified copy is needed, create a new version in archive first (`-v2` suffix), then symlink that.

## Agent Handoff

When a different agent or session needs to continue work:

1. Check for active tasks: `ls .claude-workspace/task/`
2. Read task README for objectives, decisions, and current state
3. Check git log for recent deliverable changes: `git log --oneline -10`
4. Search archive for relevant artifacts

**Context sources:** README = current WIP, git history = completed work, archive = reusable artifacts.

## Build Verification

When a flow requires build verification:

1. Detect the project's build command from project files (package.json, Makefile, go.mod, Cargo.toml, pyproject.toml, etc.)
2. Run it and note pass/fail in the progress note or return summary
3. If tests exist for affected code, run them
4. If no build system is detected, note this rather than silently skipping

## Recovery

When a flow fails mid-execution or leaves unexpected state, check these invariants:

| Check | Expected | Fix |
|-------|----------|-----|
| Task directory contents | Task management files + symlinks only | Move real files to archive/, remove unexpected files |
| Symlinks | All resolve to existing targets | Remove broken symlinks or recreate targets |
| README progress notes | Chronological, latest reflects current state | Add a corrective progress note |
| FEEDBACK.md vs README | Reconcile progress note post-dates FEEDBACK.md if findings addressed | Run reconcile-task or add missing progress note |

**General recovery:** README is source of truth for task intent, git for deliverable state, archive for artifacts. Read the README, compare against actual state, correct the divergence.
