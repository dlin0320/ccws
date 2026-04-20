# Triage-PR-Review Flow - Ingest External PR Review

> **Execution:** Run as a subagent. This flow reads the PR timeline and cross-references task context; keep it out of the main conversation.

Ingest an external PR review (by default, Claude's GitHub bot), classify each finding against the task's design context, and merge the results into `FEEDBACK.md` so `reconcile-task` can consume them.

## Purpose
Translate unstructured bot review into the project's `FEEDBACK.md` taxonomy. The bot lacks the task's README context, so a significant fraction of its findings will conflict with documented Design Decisions or re-surface previously handled issues. This flow does the translation + filtering once, so `reconcile-task` can operate on a single uniform surface regardless of whether a finding originated from self-review or external PR review.

## Outcome (Required)
- [ ] PR for the active branch identified; bot review + inline comments fetched
- [ ] Each new bot finding assessed against repo code and task README (Design Decisions + progress notes)
- [ ] Findings classified using the standard taxonomy, plus `DISMISSED` for bot noise/false-positives
- [ ] A new `## PR Review Findings — PR #N ({YYYY-MM-DD})` section appended to `FEEDBACK.md`; existing sections untouched
- [ ] Re-runs are idempotent — already-ingested bot comments are skipped (dedupe by comment ID)

## Constraints (Required)
- **Project-agnostic** — no hardcoded filenames or repo-specific conventions
- **Decision-aware** — bot findings that conflict with a documented Design Decision → `[DOCUMENTED]`, same rule as `review-task`
- **Independent assessment** — do NOT accept bot findings at face value; read the cited code and judge
- **Bot-scoped** — by default, only the configured bot author is ingested; other reviewers' comments are noted but not classified (user handles humans)
- **Non-destructive** — `FEEDBACK.md` findings from self-review are never modified or re-classified
- **Idempotent** — a second run on the same PR with no new bot comments produces no new findings
- **Read-only on GitHub** — this flow does not post replies, resolve threads, or change PR state

## Modes

- **Default**: classify and write to `FEEDBACK.md`
- `--author <pattern>`: override the bot author match (default: `claude[bot]`)
- `--dry-run`: produce the finding list in the return summary without writing to `FEEDBACK.md`
- `--include-humans`: also list human reviewer comments in the return summary (still not classified) so the user knows they exist

## Process

### 1. Identify Active Task and PR

```bash
branch=$(git rev-parse --abbrev-ref HEAD)
task_name="${branch//\//-}"
main_repo=$(git rev-parse --show-toplevel)
task_dir="$main_repo/.claude-workspace/task/$task_name"
```

If `$task_dir` doesn't exist: "No matching task for branch `$branch` (expected `task/$task_name/`)."

Find the PR for this branch:

```bash
gh pr view --json number,url,state,author,headRefName
```

If no PR exists: "No open PR for `$branch`. Run end-task first, or wait for the bot to post."
If PR is closed/merged: warn but proceed — bot findings may still be worth archiving.

### 2. Fetch Review Material

Fetch three sources and merge:

```bash
pr=$(gh pr view --json number -q .number)
repo=$(gh repo view --json nameWithOwner -q .nameWithOwner)

# Top-level reviews (APPROVE / REQUEST_CHANGES / COMMENT with review body)
gh api "repos/$repo/pulls/$pr/reviews"

# Inline review comments (attached to specific lines)
gh api "repos/$repo/pulls/$pr/comments"

# Issue comments (non-inline, e.g. bot summary posted as an issue comment)
gh api "repos/$repo/issues/$pr/comments"
```

Retain for each item: `id`, `user.login`, `body`, `path` + `line` (if inline), `html_url`, `created_at`.

### 3. Filter to Bot Author

Match `user.login` against the configured pattern (default `claude[bot]`, or `--author`). Everything else:
- If `--include-humans`: keep in a separate bucket for summary reporting.
- Otherwise: drop.

If zero bot comments remain: "No comments from `<author>` on PR #N." Exit without modifying `FEEDBACK.md`.

### 4. Dedupe Against Prior Ingestion

Read existing `FEEDBACK.md` (if present). Extract previously-ingested bot comment IDs from the `**Source:**` lines (format: `bot-review, PR #N comment #ID`). Skip any fetched comment whose ID appears there.

If all fetched comments are already ingested: "No new bot comments since last triage." Exit without writing.

### 5. Extract Findings

Bot reviews are usually semi-structured (markdown headings, severity markers, code suggestions). For each remaining comment:

- Split multi-issue comments into individual findings when the structure is clear (headings, numbered lists, separate `### ` sections)
- For inline comments, the finding is implicitly scoped to `path:line`
- For top-level reviews without inline targets, the finding scope is the whole diff; try to infer affected files from the bot text

Retain bot-provided metadata: severity hints (`critical`, `warning`, `nit`, `suggestion`), file/line, and the raw quoted text.

### 6. Cross-Reference Task Context

For each finding, in this order:

1. **Design Decisions** — does the finding contradict a `## Design Decisions` entry in the task README? If yes → `[DOCUMENTED]`, cite the entry.
2. **Progress notes** — is there informal rationale already recorded (e.g., "deferred X since Y")? If yes → `[DOCUMENTED]`, note rationale should be promoted to a formal Design Decision.
3. **Prior FEEDBACK.md findings** — does the same issue already appear (self-review or earlier triage)? If yes → mark `Status: Previously identified` and link the existing finding rather than creating a duplicate.
4. **Spec documents** — if the task symlinks reference docs, check whether the bot's concern traces back to a spec assertion. If it does, the classification is an independent re-discovery of the same issue (usually `[MISSING]` or `[DIVERGENCE]`).

### 7. Classify

Read the cited code before classifying. Do not trust the bot.

| Category | Meaning |
|----------|---------|
| `[DIVERGENCE]` | Bot is correct: code contradicts a spec requirement with no documented rationale |
| `[DOCUMENTED]` | Code diverges from bot's expectation but rationale is in the README |
| `[UNDOCUMENTED]` | Bot flags a real departure from the spec approach with no rationale in the README — the missing doc is the finding |
| `[MISSING]` | Bot correctly identifies required functionality not yet implemented |
| `[STUB]` | Bot flagged work that is intentionally deferred (TODO/stub comment or spec marks as future work) |
| `[EXTRA]` | Bot observation about code that's outside any spec — informational |
| `[DISMISSED]` | Bot finding is noise: false positive, stylistic nit that doesn't matter, based on a misreading of the code, or contradicted by context the bot didn't see |

`DISMISSED` requires a one-line rationale. Don't use it as a catch-all — if the bot's concern is real but minor, prefer `EXTRA` or `STUB`.

### 8. Write Findings to FEEDBACK.md

Append (do not overwrite) a section to `$task_dir/FEEDBACK.md`. If `FEEDBACK.md` doesn't exist yet (review-task was never run), create it with the standard summary header and go straight to the PR section.

```markdown
## PR Review Findings — PR #{N} ({YYYY-MM-DD})

**Source:** {bot-author} on {repo}#{N}
**Fetched:** {N} bot comments ({new} new, {dedup} previously ingested)
**Classification:** X divergences, Y documented, Z undocumented, M missing, S stubs, E extra, D dismissed

### {finding title}

**Source:** bot-review, PR #{N} comment #{id}
**Reference:** {path:line} (inline) | review body | issue comment
**Category:** DIVERGENCE | DOCUMENTED | UNDOCUMENTED | MISSING | STUB | EXTRA | DISMISSED
**Status:** New | Previously identified
**README ref:** {Design Decision title | progress note date | none}

**Bot said:** {quoted or summarized bot text — keep under ~5 lines; link the full thread via html_url}
**Assessment:** {independent analysis — agree/disagree/dismiss with rationale}
**Fix:** {suggested resolution, or "none — DISMISSED because …"}
**Files:** {paths}
**Thread:** {html_url}

---
```

### 9. Append a Progress Note

Append to the task README's `## Progress Notes`:

```markdown
### {YYYY-MM-DD} — Triaged PR #{N} review from {bot-author}
- **Ingested:** {new} new findings ({dedup} already seen)
- **Classification:** {X divergences, Y documented, … , D dismissed}
- Ran reconcile-task next: {yes/no — leave blank if not yet}
```

### 10. Return Summary

```
✓ Triage complete: PR #{N}, {new} new findings ingested, {dedup} skipped as duplicates
  Classification: X divergence, Y documented, Z undocumented, M missing, S stubs, E extra, D dismissed
  Actionable for reconcile: {X + Z + M}
  → task/{task-name}/FEEDBACK.md (new section: PR Review Findings — PR #{N})
```

If `--dry-run`: include the full finding list inline instead of writing.

If `--include-humans` found human comments: append a one-block summary:
```
  Human reviewer comments (not classified): {N} from {logins}
```

## Guidance

- **Bot noise is the norm, not the exception.** Expect 30–60% of bot findings to be `DOCUMENTED` or `DISMISSED`. Cross-referencing the README before classifying is the single most valuable thing this flow does.
- **Read the code the bot cites.** Bot hallucinations are common — it will confidently describe behavior that isn't in the diff. A `DISMISSED` based on "I read the file and the bot's description doesn't match" is legitimate and should say so.
- **Don't flatten severity.** Preserve the bot's own severity hints in the raw `Bot said` quote so the user can weigh them during reconcile. The classification is your judgment; the severity is the bot's.
- **Multi-issue comments:** bots often pile multiple concerns into one comment. Split them when the structure allows — reconcile works best on atomic findings. If a comment is a single integrated argument, keep it whole.
- **Suggestion comments (GitHub `suggested changes`):** treat the suggestion as the bot's proposed fix. Classification still depends on whether the underlying finding is real.
- **Stacked runs:** every new bot review on the same PR appends a new `## PR Review Findings — PR #N ({date})` section. The date distinguishes runs; dedupe by comment ID prevents double-counting.
- **Reconcile hand-off:** DISMISSED joins STUB/EXTRA as skipped categories in `reconcile-task`. Make sure the rationale on DISMISSED is strong — reconcile trusts it.
- **Human comments:** this flow deliberately doesn't classify them. If the user wants that, it's a separate pass — most human feedback needs a conversation, not triage.
- **No GitHub writes.** The flow reads only. Posting replies to resolve threads, approving/requesting changes, or editing the PR is a separate concern that belongs with the user or a later flow.
