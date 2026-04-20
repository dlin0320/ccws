# CCWS Development Guide

## What This Suite Is

A cognitive harness for developer-AI pairs. In the emerging "harness engineering" frame (agent = model + harness), CCWS is the harness — but designed for a specific user: an experienced developer who steers, not an autonomous loop that runs unattended.

**The problem:** The developer-AI pair has hard problems that neither side solves alone. The developer has intent and judgment but limited bandwidth. The model has execution capacity but loses context across sessions, drifts from specs, and can't preserve its own rationale. Most harness engineering targets autonomous agents — adding mechanical verification, health checks, and environment bootstrap that assume no human is watching. That's the wrong optimization for a developer who's present and capable.

**The approach:** User approves the plan (Gate 1) and the result (Gate 2). Between gates, the development loop progresses through implement, review, and reconcile — each flow executing autonomously. Today the user invokes each flow; full inter-flow autonomy is the design target. The harness operates at the intent layer (what to verify, what to preserve, what to track) rather than the mechanism layer (which test runner, which linter, which CI system). Implementation choices are left to the model, which picks the right tool for the context — and will pick better tools as models improve.

**What this is not:** An operational harness for autonomous agent loops. CCWS doesn't prescribe test suites, bootstrap development environments, or detect stuck loops — because an experienced developer handles those things faster than any harness can. CCWS solves the problems the developer *can't* efficiently solve: maintaining structured context across sessions, catching semantic drift against specifications, and preserving decision rationale so future sessions (and future models) understand *why*, not just *what*.

## Design Philosophy

### Cognitive harness, not operational harness
Operational harnesses compensate for the agent's unreliability when running unattended — health checks, crash recovery, mechanical verification. Cognitive harnesses amplify the developer-AI pair's shared capability — context preservation, spec adherence, decision tracking. CCWS is the latter. The developer provides the reliability; the harness provides the memory and discipline.

### Abstractions over implementations
The harness specifies *what* needs to happen (review against specs, preserve rationale, checkpoint context) but not *how*. The review-task says "audit against specifications," not "run pytest." If a future model can verify correctness by reading code, no tests needed. If today's model needs tests, it writes and runs them. Hardwiring mechanisms into the harness creates overhead that ages poorly — test suites go stale, linters fall behind, CI configurations drift. The abstraction survives. **Exception: setup.** Bootstrapping requires specific directory creation, .gitignore updates, and installation of a turn-logging hook in the project's `.claude/settings.json`. This is the one mechanistic flow — defining the scaffold that the intent-layer flows operate within.

### Don't bet against model capabilities
Future models will be better at context management, self-review, spec adherence, and session continuity. Design the suite so that pieces become optional as models improve, not so entrenched that they become overhead. The review/reconcile loop adds value today because models drift from specs; it should be easy to skip when they don't.

### Layered guidance
Flows provide guidance at three layers with different lifespans. **Principles** (Outcome, Constraints) are durable — they define what the harness ensures. **Tactical examples** (Process steps, templates, few-shot patterns) improve stability for current models but are expected to simplify. **Deprecation** follows demonstrated capability: when a model consistently meets a flow's Outcome without detailed Process steps, those steps can be removed. Few-shot examples earn their keep most for classification (finding categories), formatting (README structure), and edge cases (when NOT to act) — areas where models fail even when they grasp the principle. Remove examples based on demonstrated reliability, not optimism.

### Gates over micromanagement
Two gates (plan review, result review) give the user meaningful control. Between gates, flows execute autonomously — today user-invoked, eventually self-chaining as models mature. Resist adding more gates — each one adds friction and signals distrust in the agent. **Re-gate on resume:** when resuming a task whose README changed (design decisions, reconcile updates), the plan is re-presented for approval — not a third gate, but verification that Gate 1's approval still holds after changes between sessions. This aligns with the harness engineering consensus: humans steer, agents execute.

### Decisions are first-class
The hardest thing to recover across sessions isn't code (that's in git) or progress (that's in the README) — it's *why* something was done a certain way. Design Decisions, FEEDBACK.md classifications, and reconciliation records exist to preserve rationale. Most harnesses preserve *what was done*. CCWS preserves *why it was done that way*.

### Context has structure and lifespans
Unstructured context (conversation history, raw logs) compresses poorly and ages badly. Structured context (README sections, typed classifications, task management files with defined purposes) survives session boundaries and agent handoffs. Different context types have different lifespans: turns are ephemeral, README progress notes are durable-but-mutable, git history is immutable, archive artifacts are cross-task. The harness manages these transitions explicitly.

### The workspace is incidental
`.claude-workspace/` with archive/task/symlinks is the mechanism for keeping artifacts out of the project. It's an implementation detail. The suite's value is the development loop and context management, not the directory structure.

## Development Conventions

When evolving this suite:

- **Single source of truth** — shared formats live in `references/patterns.md`, structural rules in `references/rules.md`. Flows reference these by `§ Section` anchors. Don't duplicate.
- **Flows are self-contained procedures** — each flow file has Outcome, Constraints, Process, Guidance. A flow should be executable by reading just that file plus its referenced patterns.
- **SKILL.md is the map** — routing table, development loop, flow contracts, reference index. If you can't find something from SKILL.md, the structure needs fixing.
- **Inline vs subagent** — flows that need user interaction or are cheap on context run inline. Flows that read many files and produce artifacts run as subagents. The split is about context cost, not importance.
