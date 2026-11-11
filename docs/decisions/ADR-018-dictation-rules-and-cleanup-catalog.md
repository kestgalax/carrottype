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

## Accepted rework — explicit rules and separate tone (2026-11-10)

Maintainer approved the R1–R4 completion plan by instructing «продолжаем тогда?». Extend the existing value contract, preserving saved fields/custom text with defaults for absent new keys. Add opt-in exact whole-word removal (comma/newline-separated words, bounded), lowercase prose, omit final sentence full stop, and separate opt-in business tone. No natural-language rule parser. Off continues to mean no baseline cleanup/model; explicit exact controls apply independently even with Off, clearly labelled in UI. New exact controls default off/empty; business tone remains saved but inactive without a model.

Order: remove explicitly listed whole words before model/base processing, then model or safe Light fallback, then exact controls again. Lowercase prose, including names, but preserve fenced/inline code, URL/email and identifiable technical tokens. Final full-stop removal preserves ?/!, ellipses, decimal/version numbers and recognised abbreviations, and operates inside closing quotation marks. Ambiguous abbreviations may conservatively retain the point; disclose examples. Empty final text never inserts/counts. Exact operations are idempotent. Validation compares model output with the explicitly word-filtered input, so permitted word removal is not rejected as loss.

Business tone uses its own dictation prompt, retaining fact/intent/question/negative/numeric/code constraints and independent transform instructions. No guarantee of semantic fidelity; fixed plus held-out real-model evaluation gates readiness. Report exact-controls completion separately from model generation, unchanged output and model failure. Tone rewriting rejects both removed and invented question marks; ordinary literal cleanup retains its prior ability to punctuate an unpunctuated spoken question. Use typed non-sensitive failure categories (missing, budget, timeout, incomplete, rejected, other); fallback retains exact controls. No transcript logging, engine/weights/runtime/network/trust changes. Signed Debug and manual/publication gates remain.

## Alternatives

- Delete Smart+ record/runtime/files: rejected, breaks existing active selections/bindings and user preservation requirements. Retain a compatibility-only record instead.
- Use generic transform instructions for preferences: rejected, replaces baseline dictation policy and couples the two workflows.
- Rely only on a preservation prompt/fixed word-count generation cap: rejected after observed model loss and token/output-length concerns.
- Replace the MLX runtime or STT/model weights: outside authorized scope; keep existing pinned packages.

## Consequences

New users see fewer models; legacy packages still require explicit deletion. Dictation preferences and theme add small local versioned preferences, without transcript storage. Conservative validation can fall back on otherwise valid edits, and model compliance/semantic fidelity remains imperfect. Qwen comparative quality/latency/RAM and full interactive/system-theme/device checks remain unverified. The per-version signed Debug/manual/publication gate is unchanged.

## Debug feedback: custom rule priority and intent preservation

Maintainer tested Gemma with explicit word removal, final punctuation, lowercase and business tone, and supplied a local evaluation text. Custom presentation/word rules override the generic filler/capitalization defaults; meaning/language/facts/values/code protection stays higher priority. An explicitly requested tone may change wording while retaining facts, questions, intentions and certainty; default/no-custom formatting stays literal. No generic transform instruction replacement or new engine.

Actual AppState text-trial evaluation confirmed delivery of rules but inconsistent model compliance. Broad few-shot style examples contaminated unrelated casing/removal requests and were rejected. Losing an existing question mark is now conservatively rejected to visible Light fallback, to avoid presenting a question as an asserted decision (valid edits can also be rejected). Result UI always names the actual applied mode and makes fallback prominent. These controls do not prove semantic fidelity or make combined/business rules dependable; further quality acceptance is open. User text remains local evaluation input and is not committed as a fixture.


### First-sentence initial case (maintainer addition)

Add an independent `lowercaseFirstLetter` opt-in (missing saved key defaults false). After model/base/fallback and word removal, lowercase only the first letter, skipping leading punctuation/space/digits/emoji; preserve all remaining case, including names and later sentences. If a protected code/URL/email/technical token leads the text, leave the start unchanged rather than editing data or advancing to a later sentence. Full prose lowercase takes precedence, with the redundant first-letter toggle disabled but its saved value retained. No prompt, model/runtime, transform or default change.

## Settings location (2026-11-12)

The approved settings-organization extraction moves the dictation shortcut and the existing
formatting selector, exact rules, model preferences/My Rules and text trial into Settings →
Dictation; General now holds application preferences only. The Ready-only cleanup selection still
uses the same `ModelManager` path as Models. This is a location/UI change, not a change to the
decisions above: rules, prompt purpose, persistence keys, models, helper protocol and validation
are unchanged.
