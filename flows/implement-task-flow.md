# Implement-Task Flow - Execute Task Implementation

> **Execution:** Run as a subagent. This flow reads reference docs, writes code, and should not pollute the main conversation context.

Implement the task defined in README.md, using success criteria as the contract and symlinked reference docs as guidance.

## Outcome (Required)
- [ ] All success criteria addressed (implemented or explicitly noted as blocked)
- [ ] Deliverables created/modified and symlinked to task
- [ ] Self-check completed against each success criterion
- [ ] Build passes (if applicable)
- [ ] Progress note appended to README

## Constraints (Required)
- **Project-agnostic** — no hardcoded conventions
- **Criteria-driven** — success criteria are the contract, reference docs are guidance
- **Symlink hygiene** — new deliverables symlinked to task, new artifacts in archive/
- **No user interaction** — run autonomously; if blocked, document the blocker and continue with other criteria
- **Single responsibility** — does NOT run review or reconcile; those are separate loop steps

## Process

### 1. Load Task Context

Read the task README. Extract:
- **Objective** — the high-level goal
- **Success criteria** — the verifiable conditions (these become the implementation checklist)
- **Design decisions** — pre-existing constraints from prior reconciliation
- **Progress notes** — what's already been done (for resume cases)

List symlinked files in the task directory. Separate into:
- **Reference docs** (.md, .yaml, .yml, .json, .toml, config) — read for implementation guidance
- **Implementation files** (.go, .py, .ts, etc.) — existing code to build on or modify

If SNAPSHOT.md exists, read it for structural context.

### 2. Plan Implementation

For each success criterion, determine:
- What needs to be built or changed
- Which reference doc sections are relevant
- Dependencies between criteria (ordering)

Order criteria by dependency: foundational pieces first, dependent pieces after.

### 3. Execute Implementation

For each criterion (in dependency order):

1. Read relevant reference doc sections
2. Read existing code in affected packages (sibling files, not just symlinked ones)
3. Implement the change
4. Symlink new deliverables to the task directory
5. Verify: does the code satisfy this specific criterion?

Follow existing project conventions (detected from codebase, not hardcoded):
- Package structure, naming conventions, error handling patterns
- Test patterns (if tests exist, follow their style)
- Import organization, comment style

### 4. Self-Check

Walk each success criterion and classify:
- **Met** — cite specific evidence: file path, function name, or test that satisfies it. "See implementation" is not sufficient.
- **Partial** — partially addressed, document what's missing and why
- **Blocked** — cannot implement, document the blocker

Verify build per `references/patterns.md § Build Verification`. If tests exist for affected code, run them.

### 5. Update Task README

Append a progress note:

```markdown
### YYYY-MM-DD — Implementation [complete|partial]
- **Implemented:** [list of criteria met, with key files]
- **Partial:** [list of partially met criteria, with explanation]
- **Blocked:** [list of blocked criteria, with blocker description]
- **Key files:** [primary deliverables created/modified]
```

### 6. Return Summary

Report back to main context:

```
Implementation [complete|partial]: X/Y criteria met
[If partial/blocked]: N criteria partially met, M blocked — see README progress note
Ready for review
```

## Guidance

- **Convention detection:** Read existing code before writing new code. Match the project's style, not a generic template.
- **Blocked criteria:** Document and move on. Don't stall the entire implementation on one blocked item.
- **Scope discipline:** Implement what the criteria say, nothing more. Don't refactor adjacent code or add features not in the criteria.
- **Test writing:** If the criteria include tests, write them. If they don't, don't add them — review-task will flag missing tests if the spec requires them.
- **Existing code:** Prefer editing existing files over creating new ones. Build on what's there.
