# TeX-Interleaved Proof Completion Plan

## Purpose

This plan is for finishing proof-heavy work where the proof artifact and the
written exposition are developed together. The goal is to prevent endless
"almost done" loops by forcing each pass to either close a named gap or
produce a precise blocking record.

## Core Rule

Each pass must end in exactly one of these states:

1. `closed`
   A named gap is fully discharged.
2. `reduced`
   A named gap is strictly smaller, with the remaining subgap written down.
3. `blocked`
   The pass stops with a concrete blocker certificate.

A pass is invalid if it ends with only a vague claim like "one final issue" or
"almost there" without a fresh named subgoal.

## Work Unit

The unit of progress is a **proof checkpoint**. Each checkpoint must record:

- theorem or lemma name
- current status: `closed`, `reduced`, or `blocked`
- exact frontier statement still needing proof
- dependency list
- artifact locations:
  - proof source
  - TeX source
  - generated notes or traces
- acceptance test for closure

## Interleaving Policy

Proof and TeX work should alternate in bounded chunks instead of drifting.

1. Proof pass
   Reduce or close one formal gap.
2. TeX pass
   Rewrite only the section justified by the latest proof state.
3. Consistency pass
   Check that theorem names, hypotheses, and conclusion text still match.

Do not let TeX prose get ahead of the proof state. If the proof is blocked, the
text must explicitly mark the remaining claim as provisional.

## Stop Conditions Per Pass

Each pass must have a budget fixed in advance:

- one target checkpoint
- one target frontier statement
- one maximum pass budget
  - suggested default: 60-90 minutes
- one allowed escalation outcome if the checkpoint does not close

At budget expiry, do not continue chasing the same frontier informally. Instead
choose one of:

1. split the frontier into named sublemmas
2. mark the checkpoint `blocked` with a blocker certificate
3. revert the pass if no measurable reduction happened

## Blocker Certificate

When a pass cannot close, write a blocker certificate containing:

- the smallest statement still not proved
- the first failed inference step
- whether the obstacle is:
  - missing lemma
  - wrong statement
  - missing invariant
  - tooling failure
  - notation/TeX mismatch
- the next admissible move

Without this certificate, the pass is not allowed to conclude.

## Lemma-Splitting Discipline

When a proof frontier is too large, split only if the new sublemmas are:

- independently testable
- strictly smaller than the parent goal
- reusable or structurally necessary

Do not create placeholder lemmas with no proof route. Each split lemma needs:

- statement
- expected proof method
- concrete dependency list

## TeX Synchronization Rules

TeX updates must track proof checkpoints exactly:

- if a lemma closes, upgrade the prose from tentative to assertive
- if a lemma is only reduced, keep the prose local and conditional
- if a blocker appears, insert a visible TODO or provisional marker instead of
  silently implying completion

Every theorem section should carry a short source-of-truth note pointing to the
checkpoint or proof file that currently justifies it.

## Completion Gate

A theorem is complete only if all of the following hold:

1. every checkpoint under it is `closed`
2. no blocker certificates remain open
3. the TeX statement matches the proved statement exactly
4. the dependency graph has no unproved placeholder edge
5. the local proof validation command or review checklist passes

## Review Rhythm

Use short review cycles rather than long rescue cycles.

- after each pass, update the checkpoint table
- after every 3-5 passes, review whether the frontier decomposition is still
  valid
- if the same checkpoint reaches `reduced` three times without closure, force a
  structural change:
  - new lemma split
  - changed invariant
  - changed theorem statement
  - explicit external blocker

## Minimal Tracking Template

```text
Checkpoint: <name>
Status: <closed|reduced|blocked>
Frontier: <smallest remaining statement>
Depends on: <lemmas or files>
Artifacts:
  proof: <path>
  tex: <path>
  notes: <path or none>
Acceptance test: <command or checklist>
Next move: <single concrete action>
```
