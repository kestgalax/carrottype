# ADR-018: Two offered cleanup models and bounded dictation rules

## Status

Accepted for implementation in 0.8.0 — maintainer explicitly chose Qwen3 0.6B + Gemma, added independent System/Light/Dark theme, then instructed implementation of the current stage. Publication requires its own Debug/manual gate.

## Context

The maintainer wants fewer offered cleanup models, control over dictation formatting and independent theme selection. Existing prompts use a single fixed editor instruction; transform instructions replace it. Reusing that replacement slot for dictation preferences would erase baseline constraints and risk changing selection transforms. Existing Smart+ users must retain their useful settings/weights. Synthetic evaluation also exposes literal losses despite a preservation prompt.

## Decision

Offer Qwen3 0.6B and Gemma 4 E2B for new cleanup/transform choices. Keep Off/Light. Retain the Smart+ catalog record, runtime and installed weights for existing active selections/bindings and Storage, marked legacy/non-downloadable; never suggest it for new choices or fallback. Existing selections continue until explicitly changed. Correct Gemma license metadata to Gemma (the pinned upstream card), retaining model revisions. This narrows ADR-003/005/010 offerings, not their history.

Persist bounded local DictationRules (three cleanup switches, preserve/paragraph layout, at most 1000 characters of additional preferences). Snapshot them when dictation starts. A shared prompt builder always keeps literal-cleanup constraints; these preferences do not use the transform instruction-replacement slot. Versioned helper v3 carries explicit purpose and rules; rejects incompatible requests. Translate/Custom retain their independent instructions/framing and model selection.

Light removes only unambiguous hesitation tokens, preserves line breaks and meaningful words such as 'like'/'ну'. Empty LLM output remains a visible fallback rather than silent loss of speech. Deterministically empty Light results deliver no insertion/history/statistics. LLM generation uses token-based input/output budgeting, context preflight and completion stop reason; a length-limited/invalid result is rejected instead of inserted. Conservative protected number/negation/URL/code/outer-quote/language checks reject observed losses to visible Light fallback, with possible false rejections of valid edits. This is not a guarantee of semantic fidelity; evaluate real model output separately. Do not strip meaningful quotes/code from dictation results.

Text-only trial reserves the existing installation/operation gate and uses the same formatting path with a captured configuration; no microphone, pasteboard, recovery history or statistics. Cancellation/quit join helper teardown before releasing the gate. No transcript persistence.

System/Light/Dark is a separate local preference, System default; apply live to app windows/sheets/Capsule without remounting Settings or changing the system. Keep semantic menu template behavior and accessibility preferences.

No new STT/runtime/network/trust/dependency is introduced; ADR-009 process-per-request and signing, ADR-012 transforms and ADR-016 Ultra-only STT remain. GigaAM is deferred. User model deletion/download remains explicit. Future releases retain signed Debug/manual and separate publication authorization.

## Alternatives

- Delete Smart+ record/runtime/files: rejected, breaks existing active selections/bindings and user preservation requirements. Retain a compatibility-only record instead.
- Use generic transform instructions for preferences: rejected, replaces baseline dictation policy and couples the two workflows.
- Rely only on a preservation prompt/fixed word-count generation cap: rejected after observed model loss and token/output-length concerns.
- Replace the MLX runtime or STT/model weights: outside authorized scope; keep existing pinned packages.

## Consequences

New users see fewer models; legacy packages still require explicit deletion. Dictation preferences and theme add small local versioned preferences, without transcript storage. Conservative validation can fall back on otherwise valid edits, and model compliance/semantic fidelity remains imperfect. Qwen comparative quality/latency/RAM and full interactive/system-theme/device checks remain unverified. The per-version signed Debug/manual/publication gate is unchanged.
