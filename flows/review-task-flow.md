# Review-Task Flow - Audit Implementation Against Design Docs

> **Execution:** Run as a subagent. This flow reads many files and should not pollute the main conversation context.

Review implementation for correctness against reference documents and task success criteria, cross-referencing documented design decisions to avoid false positives.

## Purpose
Systematically verify that implementation matches what design docs and task specs require, producing a structured FEEDBACK.md with actionable findings. Documented design decisions are acknowledged, not re-flagged.

## Outcome (Required)
- [ ] Reference docs identified and assertions extracted
- [ ] Task README design decisions and progress notes extracted
- [ ] Implementation scanned against each assertion, cross-referenced with documented decisions
- [ ] Findings classified (DIVERGENCE, DOCUMENTED, UNDOCUMENTED, MISSING, STUB, EXTRA)
- [ ] Task README claims verified
- [ ] FEEDBACK.md written to task directory

## Constraints (Required)
- **Project-agnostic** — no hardcoded filenames, section numbers, or project-specific conventions
- **Doc-anchored** — every finding cites its source document and section/heading
- **Architecture focus** — check interfaces, patterns, wiring, config format, contracts — not code style or performance
- **Stub-aware** — code with stub/TODO/deferred comments → `[STUB]`, not `[MISSING]`
- **Decision-aware** — divergences documented in README Design Decisions or progress notes → `[DOCUMENTED]`, not `[DIVERGENCE]`
- FEEDBACK.md is written to the task directory (not archive)

## Modes

- **Task-scoped** (default): Uses the active task's symlinked files to determine both reference docs and implementation scope
- **Full** (`--full`): Auto-discovers design/architecture docs across the repo and scans all source code

## Process

### 1. Identify Active Task and Review Mode

```bash
# Find active task(s)
ls -d .claude-workspace/task/*/ 2>/dev/null
```

If no tasks: "No active task to review."
If multiple: Ask which task to review.

- Read the task README — extract objective, success criteria, **design decisions**, progress notes
- If a `## Design Decisions` section exists, extract all documented decisions (these will be cross-referenced during classification)
- Also scan progress notes for informal decision documentation (look for rationale language: "chose X because", "deferred Y since", "intentionally", "by design", "instead of")
- List all symlinked files in the task directory:

```bash
ls -la .claude-workspace/task/[task-name]/
```

- Determine mode from user input: default (task-scoped) or `--full` (repo-wide)
- If a prior FEEDBACK.md exists in the task directory, read it to distinguish new vs previously identified findings
- Check for SNAPSHOT.md in the task directory:
  - **If missing**: Warn: "No SNAPSHOT.md found. Run snapshot-task first for better review quality, or proceed without it." Wait for user confirmation before continuing.
  - **If exists**: Read it and check the `Updated:` timestamp. If the timestamp is more than 24 hours old, or if `git log --since` shows changes to implementation files since that timestamp, note: "SNAPSHOT.md may be stale (last updated [date]). Consider re-running snapshot-task." Proceed but note the staleness in the FEEDBACK.md summary.

### 2. Gather Reference Material

#### Task-scoped mode (default)

Separate symlinked files into two groups based on file type:

- **Reference docs**: `.md`, `.yaml`, `.yml`, `.json`, `.toml`, config files — these are the spec/design references
- **Implementation files**: `.go`, `.py`, `.ts`, `.js`, `.rs`, `.java`, and other source code — these are what gets audited

Read all reference docs. Extract **verifiable assertions** relevant to the task's success criteria — things like:
- Required interfaces, function signatures, types
- Expected package structure or wiring
- Config format or field requirements
- Behavioral contracts (e.g., "retries 3 times", "emits metric X")
- Integration points (e.g., "reads from Kafka topic Y")

#### Full mode (`--full`)

Auto-discover design and architecture docs in the repo:

```bash
# Search for design/spec docs by filename
find . -name "*.md" -not -path "./.claude-workspace/*" -not -path "./.git/*" -not -path "./node_modules/*" -not -path "./vendor/*" | head -50
```

Filter for docs likely to contain specs — look for filenames or content containing: architecture, design, requirements, RFC, ADR, spec, overview, migration, observability.

Also read CLAUDE.md (if it exists) for documented conventions or references to design docs.

Read discovered docs and extract verifiable assertions about the implementation.

Determine implementation scope: glob for all source code files in the repo (`.go`, `.py`, `.ts`, etc., excluding vendor/generated directories).

### 3. Scan Implementation

**Task-scoped**: Read implementation files symlinked to the task. Also read sibling files in the same packages to understand context.

**Full**: Read all source code files discovered in step 2.

For each assertion from the reference docs, check whether the implementation matches.

**Before classifying a finding as DIVERGENCE or MISSING**, cross-reference the task README:
1. Is there a matching entry in the `## Design Decisions` section? If yes → `[DOCUMENTED]`
2. Is there rationale in the progress notes (even informally)? If yes → `[DOCUMENTED]`, but note the rationale should be promoted to a formal Design Decision entry
3. Was this finding in a prior FEEDBACK.md and subsequently addressed in the README? If yes → `[DOCUMENTED]`
4. Does the code contradict a spec requirement (wrong type, broken contract, opposite behavior) with zero rationale anywhere? → `[DIVERGENCE]`
5. Does the code depart from the spec's approach (different pattern, naming, structure) without contradicting a requirement, and with zero rationale anywhere? → `[UNDOCUMENTED]` (the missing documentation is the finding, not just the divergence)

Classify findings:

| Category | Meaning |
|----------|---------|
| `[DIVERGENCE]` | Implementation contradicts a spec requirement (wrong type, broken contract, opposite behavior) with no documented rationale |
| `[DOCUMENTED]` | Implementation contradicts or departs from the spec but rationale is documented in README Design Decisions or progress notes |
| `[UNDOCUMENTED]` | Implementation departs from spec approach (different pattern, naming, structure) with no documented rationale — the missing documentation is the finding |
| `[MISSING]` | Spec requires something not yet implemented (and not marked as deferred) |
| `[STUB]` | Intentionally deferred — code has stub/TODO comment or spec marks it as future work |
| `[EXTRA]` | Implementation includes something not covered by the spec (informational, not necessarily wrong) |

**Build check**: If the project has a recognizable build command (`go build ./...`, `cargo build`, `npm run build`, `make build`, etc.), run it as a sanity check and note any failures.

### 4. Verify Task README Claims

- For each checked `[x]` item in success criteria, verify against actual code
- Spot-check factual claims in progress notes (e.g., "implemented X in file Y" — does Y actually contain X?)
- Flag inaccurate or overstated claims

### 5. Write FEEDBACK.md

Write to `.claude-workspace/task/[task-name]/FEEDBACK.md`.

Use the following format:

```markdown
# Implementation Review — {YYYY-MM-DD}

## Summary
- **Task:** {task name}
- **Scope:** {task-scoped | full}
- **Reference docs:** {list of docs used}
- **Findings:** N total (X divergences, Y documented, Z undocumented, M missing, S stubs, E extra)

## Findings

### {finding title}

**Reference:** {doc name}, {section or heading}
**Category:** DIVERGENCE | DOCUMENTED | UNDOCUMENTED | MISSING | STUB | EXTRA
**Status:** New | Previously identified
**README ref:** {Design Decisions entry title, or progress note date, or "none"}

{Description — what the spec says vs what the code does}

**Fix:** {suggested resolution — for DOCUMENTED items, suggest whether spec should be updated to match; for UNDOCUMENTED items, suggest adding a Design Decision or fixing the code}
**Files:** {affected file paths}

---

## Deferred Items
| Item | Reference | Rationale |
|------|-----------|-----------|

## README Verification
| Claim | Verdict | Notes |
|-------|---------|-------|
```

### 6. Log Turns

Append turn entries to TURNS.md at natural milestones during the review:

```markdown
### YYYY-MM-DD HH:MM [review-task]
Reviewed [N packages/files] against [reference docs]. Found [N] findings: [brief breakdown]. FEEDBACK.md written.
```

Log at meaningful points — e.g., after scanning each major package or completing assertion extraction — not after every file read.

### 7. Return Summary

Print a one-line summary to the user:

```
✓ Review complete: N findings (X divergences, Y documented, Z undocumented, M missing, S stubs) → task/[task-name]/FEEDBACK.md
```

## Guidance

- **Parallel exploration**: Use parallel Explore agents to audit different packages or doc sections simultaneously for speed
- **Incremental reviews**: When FEEDBACK.md already exists, mark previously identified items as "Previously identified" and highlight what's new
- **Assertion quality**: Be specific in assertions — "§3.2 says Pipeline must implement `Process(ctx, msg) error`" is better than "the pipeline interface should exist"
- **DOCUMENTED items**: These acknowledge that the implementation diverges from spec intentionally. The suggested fix should be "update spec" (if the decision is correct) or "reconsider decision" (if the spec was right all along). Do not treat documented divergences as problems.
- **UNDOCUMENTED items**: The finding is the missing rationale, not just the code difference. The fix should always include "add a Design Decision entry explaining the rationale, or fix the implementation to match the spec."
- **EXTRA items**: These are informational — implementation may legitimately go beyond spec. Don't treat them as problems unless they contradict something
- **Build failures**: If the build fails, note it in Summary but still complete the review — build issues are separate from spec alignment
- **Snapshot freshness**: Review is more accurate with a current SNAPSHOT.md. If the snapshot is missing or stale, the review agent must do its own code discovery, which is slower and may miss structural context
- **Large codebases**: In full mode, prioritize reading files that are most likely to relate to documented assertions rather than scanning everything exhaustively
