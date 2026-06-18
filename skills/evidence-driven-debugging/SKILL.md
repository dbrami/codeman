---
name: evidence-driven-debugging
description: >-
  Use this skill for ANY debugging task — a failing test, a production error, a crash, a 500/409/timeout,
  or any behavior that surprises you — and ESPECIALLY when a previous fix did not hold, when something
  works in one environment but fails in another, when a bug cannot be reproduced, or when you catch
  yourself guessing or assuming the cause instead of observing it (phrases like "works locally but fails
  in prod", "I think it's", "it must be", "can't reproduce", "fixed it but it came back", "why is this
  happening", "the code looks right but"). It installs evidence-over-deduction habits: capture ground
  truth at the boundary instead of inferring it from downstream state, isolate the one differing variable
  when two "identical" cases diverge, trace a symptom to its true layer (often a code-versus-config
  contradiction far from where the error surfaces), match the reproduction to the real scenario, and
  verify the fix against the original failure. Apply it even for seemingly simple bugs and even when you
  think you already know the cause — that is exactly when wrong fixes happen; pair it with whatever
  structured debugging loop you use. Do NOT use it for building new features, refactors or renames,
  performance tuning of already-correct code, code review, or "explain how X works" questions.
---

# Evidence-Driven Debugging

**Core thesis: at any point where a conclusion will drive a fix, deduction is a hypothesis — not a finding.** The fastest way to waste an hour is to reason confidently from indirect signals and fix the wrong thing. Replace inference with a cheap observation, trace the symptom to its true layer, and make sure the thing you reproduce is the thing that actually breaks.

Pair this with whatever structured debugging loop you already use — for example, a four-phase loop: root cause → pattern → hypothesis → fix. Use the loop for structure; use **this** skill for the habits that keep each phase honest — the ones that stop you from confidently concluding the wrong root cause.

## When this applies

Any debugging, but reach for it hardest when: the system spans components/layers (API → service → DB → config), the behavior is *surprising* (your model of the system is wrong somewhere), a prior fix didn't hold, or you notice yourself saying "it must be," "presumably," or "so X is stable." Those phrases are the tell that you're deducing where you could be observing.

## The five habits

### 1. Capture ground truth at decision points — never infer an input from a downstream effect

The trap: concluding what the system *received* or *did* from a side effect you can see. "The row count didn't change, so it must have sent the same identity." Downstream state is **lossy** — many different inputs collapse to the same observable effect, so reasoning backward from the effect is guessing dressed up as logic.

The habit: when a conclusion gates a fix and the observation is cheap, **capture the actual value at the boundary** — log the request body, dump the variable, replay the exact call. Spend the two minutes.

Why it matters: in one case a re-pair failure was diagnosed *twice* from database state — first "the identity is stable," then "the MAC is stable but the serial changes." Both were confident, both were wrong. Logging the actual outgoing payload showed *both* fields regenerated on every wipe. The capture took two minutes and overturned an hour of deduction. The lesson isn't "I made a mistake" — it's that the *method* (inferring an input from a downstream count) was structurally incapable of being right.

### 2. When two "identical" situations diverge, the difference IS the bug

If a replay of "the same" operation succeeds while the real one fails against the same backend state, you have not found a mystery — you have found a **lead**. Identical-but-divergent means there is exactly one real difference, and it is the cause.

The habit: deliberately construct the minimal pair — one invocation that works, one that fails — then enumerate *every* difference between them, however trivial, and test the one that differs. Resist "that can't matter"; the thing you wave off is usually it. In the case above, a hand-built replay returned success while the live client failed with identical server state, which isolated the cause to the request payload and nothing else.

### 3. Trace the symptom to its true layer — the cause is usually not where the error appears — and check code against config

The layer that throws the error is frequently working *correctly*; it is reacting to bad input from somewhere upstream. Fixing at the symptom layer either does nothing or breaks a correct invariant.

The habit: follow the bad value (or identity, or state) **backward across each component boundary** until you reach where it originates. Fix there. And specifically watch for **code-versus-config contradictions** — code that assumes a behavior the configuration forbids. Comments and docs are *claims*, not truth; verify them against the actual config and runtime.

Why it matters: one "the server rejected this with a 409" symptom traced — through the client, through identity generation, through a storage layer — to a mobile backup-rules config that excluded the very data the code's comment claimed would "persist across reinstalls via backup." Four layers from the symptom, and the layer that emitted the 409 was behaving exactly as designed. The fix belonged at the origin, not the symptom.

### 4. Make the reproduction the actual scenario — know what your test action really does

A repro that is *close to* the real scenario but not the same can lead you to a confident, wrong conclusion. Before trusting a result, name the exact real-world event you care about and confirm your action exercises *that* — not a harder or easier cousin.

Why it matters: a "clear app data" action was used to stand in for "reinstall," but the two differ in a decisive way (cloud backup can restore on reinstall but never on a data-clear). Reasoning about reinstall while testing data-clear nearly produced the wrong root cause. Understand what your tooling actually does to system state — "clear data," "restart," "redeploy," and "reinstall" are not interchangeable.

### 5. Verify the fix against the original failure — and instrument safely

A green unit test is necessary but not sufficient: it proves the code does what the test says, not that the *original failure* is gone. Re-run the exact thing that broke and watch it succeed, with evidence (status code, log line, row). In one case the fix was only "done" once the on-device wipe-and-re-pair that previously 409'd returned 201 — the unit tests passing was a checkpoint, not the proof.

When you add temporary instrumentation to capture ground truth (habit 1): **redact secrets, restrict file permissions, and always revert it.** Diagnostic logging that writes a credential to a world-readable file, or that survives into a commit, trades a bug for a worse one.

## Cheap observability toolkit

Reach for one of these at each boundary *before* theorizing — the goal is to make the system show you what it's doing rather than guess:

- **Deterministic replay** — script/curl the exact call so an intermittent failure becomes repeatable and you can probe it freely.
- **Boundary state inspection** — read the DB row, queue, cache. (Remember habit 1: this is a downstream effect, good for confirming outcomes, dangerous for inferring inputs.)
- **Edge logging on both sides of a boundary** — what entered the component, what exited. Reveals *which* layer is wrong, not just that something is.
- **Temporary instrumentation** — when a value isn't otherwise observable, log it (redacted, perms-restricted, reverted).
- **Code graph / structural search** — find the layer that actually owns the behavior fast (call graph, who-writes-this-field, config that governs it) instead of grepping blindly.

## Red flags — you're about to fix the wrong thing

| Thought | What to do instead |
|---|---|
| "It must be X" / "presumably" / "so X is stable" | Capture X directly at the boundary (habit 1) |
| "These are the same situation, but one fails" | Enumerate the one difference — it's the bug (habit 2) |
| "I'll fix it where the error shows up" | Trace backward to the origin layer (habit 3) |
| "The comment/doc says it handles this" | Verify against config and runtime (habit 3) |
| "Clearing data is basically a reinstall" | Match the exact real scenario (habit 4) |
| "Tests pass, so it's fixed" | Re-run the original failure with evidence (habit 5) |
| "I've tried three fixes, one more should do it" | Stop — question the layer or architecture, not just the code |
