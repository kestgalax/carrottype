# Agent Operating Instructions

This file is the required entry point for AI agents working in this repository.

## Required Reading Order

Before planning or changing anything, read these files in order:

1. `README.md` (product-facing; keep marketing tone if editing)
2. `docs/product-intent.md`
3. `docs/roadmap.md`
4. `docs/architecture.md`
5. Current ADRs in `docs/decisions/`
6. `.ai/constitution.md`
7. The role file for your task:
   - `.ai/planner.md`
   - `.ai/developer.md`
   - `.ai/reviewer.md`

Also respect `.ai/constraints.md`, `.ai/workflow.md`, and `.ai/memory.md`.

## Global Rules

- Preserve product intent and architecture before optimizing local details.
- Do not introduce a runtime stack, STT/cleanup engine, or distribution trust model without an ADR.
- Keep changes small, reviewable, and traceable.
- After every completed implementation task, update `docs/roadmap.md`.
- Update other documentation when behavior, workflow, architecture, or decisions change.
- Do not remove project memory unless explicitly instructed by a human maintainer.

## Traceability

Every meaningful change should connect to at least one of: product intent, roadmap item, feature/task spec, ADR, review finding, or release note.

## Completion Standard

A task is not complete until:

- requested functionality or documentation is implemented;
- relevant verification is run (or skipped checks explained);
- architecture and ADR consistency are checked;
- `docs/roadmap.md` reflects completed work and next focus;
- open risks are reported.
