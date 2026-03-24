# Reconcile-Task Flow - Resolve Review Findings

> **Execution:** Run as a subagent. This flow reads FEEDBACK.md, specs, and source files, and makes edits across multiple files.

Resolve divergences from a review by fixing code, updating specs, or documenting decisions.

## Purpose
Bridge the gap between "review found problems" and "problems are resolved." For each actionable finding in FEEDBACK.md, decide on a resolution and execute it.

## Outcome (Required)
- [ ] Every actionable finding has a resolution (fix-code, update-spec, document, or defer)
- [ ] Code fixes applied for fix-code resolutions
- [ ] Spec/design docs updated for update-spec resolutions
- [ ] README Design Decisions updated for document resolutions
- [ ] Progress note added summarizing reconciliation

## Constraints (Required)
- **Project-agnostic** — no hardcoded filenames or project-specific conventions
- **FEEDBACK.md required** — must exist in task directory (run review-task first)
- **User confirmation** — in interactive mode, confirm each resolution before executing
- **Spec edits are real edits** — update-spec means changing the actual design doc, not a separate file

## Modes

- **Interactive** (default): Present each finding, user chooses resolution
- **Autonomous** (`--auto`): Agent chooses resolution based on context and rationale
- **Dry-run** (`--dry-run`): Produce resolution plan without executing changes

## Process

### 1. Load Review Findings

```bash
ls -d .claude-workspace/task/*/ 2>/dev/null
```

If no tasks: "No active task to reconcile."
If multiple: Ask which task.

Read FEEDBACK.md from the task directory. If it doesn't exist: "No FEEDBACK.md found — run review-task first."

Parse all findings. Filter to actionable findings — skip these categories:
- `[STUB]` — intentionally deferred, no action needed
- `[EXTRA]` — informational, no action needed
- `[DOCUMENTED]` — already has rationale (unless the finding suggests a spec update is warranted)

Present remaining findings grouped by category:

```
Findings requiring resolution:

DIVERGENCE (contradicts spec, no rationale):
  1. [title] — [one-line summary]

UNDOCUMENTED (diverges, missing rationale):
  2. [title] — [one-line summary]

MISSING (spec requires, not implemented):
  3. [title] — [one-line summary]
```

### 2. Resolve Each Finding

For each actionable finding, choose a resolution:

| Resolution | When to use | What happens |
|------------|-------------|--------------|
| **fix-code** | Implementation is wrong | Fix the code to match the spec |
| **update-spec** | Spec is wrong or outdated | Update the design doc to match implementation |
| **document** | Divergence is intentional | Add Design Decision to README |
| **defer** | Not addressing now | Note rationale for deferral |

**Interactive mode:** Present each finding with its FEEDBACK.md description and suggested fix. Ask: "Resolution? (fix-code / update-spec / document / defer)"

**Autonomous mode:** Assess each finding independently (do NOT simply follow FEEDBACK.md's suggested fix):

1. Read the spec section cited in the finding AND the implementation code
2. Determine which better reflects the project's actual requirements:
   - Implementation is clearly correct and spec is outdated or wrong → update-spec
   - Spec is clearly correct and implementation deviates → fix-code
   - Divergence is an intentional design choice with clear rationale in context (README progress notes, code comments, commit messages) → document
   - Both spec and implementation are defensible but differ → document (with rationale explaining the choice)
   - Genuinely uncertain which is correct → fall back to interactive for that finding
3. Use FEEDBACK.md's suggested fix as one input, not as the decision. If your independent assessment disagrees with the suggestion, follow your assessment and note the disagreement in the resolution.

### 3. Execute Resolutions

Execute in this order:
1. **update-spec** resolutions first (changes what "correct" means)
2. **document** resolutions second (updates README)
3. **fix-code** resolutions last (code changes informed by updated specs)
4. **defer** resolutions (update README or FEEDBACK.md deferred table)

For each resolution:

**fix-code:**
- Read the affected files listed in the finding
- Apply the fix described in the finding's "Fix" field (or an improved version)
- Verify the fix (build check if applicable)

**update-spec:**
- Read the referenced design doc and section
- Update the spec to match the current implementation
- Grep for cross-references to the changed section and update those too

**document:**
- Add a Design Decision entry to the task README:
  ```markdown
  ### [Finding title]
  - **Spec:** [What the spec says — from finding's Reference field]
  - **Decision:** [What the implementation does — from finding's description]
  - **Rationale:** [Why — from user input or finding context]
  ```
- If `## Design Decisions` section doesn't exist, create it between Success Criteria and Progress Notes

**defer:**
- Add to the Deferred Items table in FEEDBACK.md (if it exists)
- Note the rationale for deferral and the expected tier/milestone

### 4. Update Task README

Append a progress note summarizing the reconciliation:

```markdown
### [date] — Reconciled review findings
- **Resolved:** N findings (X fix-code, Y update-spec, Z document)
- **Deferred:** M findings
- [Brief summary of key resolutions]
```

### 5. Log Turns

Append turn entries to TURNS.md at natural milestones during reconciliation:

```markdown
### YYYY-MM-DD HH:MM [reconcile-task:fix-code]
Fixed F2: LabelResolver return type changed to *labelpb.LabelRecord. Updated pkg/enricher/enricher.go.

### YYYY-MM-DD HH:MM [reconcile-task:update-spec]
Updated go-architecture-design.md §5 to reflect InputType()/OutputType() on Step interface.
```

Use the resolution type as a sub-tag (`:fix-code`, `:update-spec`, `:document`, `:defer`) for granularity.

### 6. Return Summary

```
✓ Reconciliation complete: N findings resolved
  - fix-code: X
  - update-spec: Y
  - document: Z
  - deferred: M
✓ README updated with resolutions and progress note
→ Run review-task again to verify resolutions
```

## Guidance

- **Run review first**: Reconcile requires FEEDBACK.md — always run review-task before reconcile-task
- **Re-review after**: Reconcile changes code and specs. Run review-task again to verify that resolutions didn't introduce new issues.
- **Batch similar findings**: If multiple findings have the same resolution type and affect the same file, handle them together
- **Spec updates are significant**: When updating specs, consider whether the change affects other parts of the design doc (cross-references, section dependencies)
- **Don't over-document**: If a divergence is trivial and the fix is obvious, fix-code is better than document. Reserve document for genuinely intentional architectural choices.
- **Defer is valid**: Not everything needs to be resolved now. Defer with good rationale is a legitimate outcome.
- **DOCUMENTED findings**: These are usually skipped, but if the review suggests the spec should be updated to match the documented decision, include that as an update-spec resolution.
