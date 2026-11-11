# 0.8.0 formatting quality observations

Synthetic inputs, local installed Gemma 4 E2B, current pinned package/runtime, temperature 0, non-streaming user delivery via v3 helper stream completion. No model download or user transcript. Trace: [P4](2026-11-10-post-dictation-formatting-audit.md), [ADR-018](decisions/ADR-018-dictation-rules-and-cleanup-catalog.md).

This is a small diagnostic corpus, not an accuracy benchmark or broad guarantee. Human semantic review is separate from controller/IPC unit checks. Single cold helper timings include load/tokenization/generation/exit, with no repeated comparison or measured peak RAM. Qwen is not installed and was not tested. No model revisions or sampling settings changed.

## Findings

| Case | Observed model behavior | Delivery policy |
|---|---|---|
| `эм привет как дела`, fillers on | `Привет, как дела?` | Accept |
| Same, cleanup switches off | Retains `эм привет как дела` | Accept; punctuation not guaranteed |
| Custom spelling of керроттайп | Produces CarrotType | Accept |
| Explicit self-correction | Removes hesitation, may keep both rejected/corrected variants | Model limitation, no claim of deterministic correction |
| Paragraph preference | Punctuation improves, may stay one paragraph | Model limitation |
| Number/negation | Model omitted `15 процентов` | Reject complete LLM output; visible Light fallback retains source |
| Outer quotation marks | Model removed whole-text quotes | Reject; fallback |
| Fenced Swift code | Model removed fences | Reject; fallback keeps fenced text/indentation |
| English `um I like…` | Model introduced Cyrillic `Ум` | Reject; fallback removes um and keeps meaningful like |
| Inner quoted speech | Kept `«я не согласен»` | Accept |
| Question as transcript | Kept question rather than answering it | Accept; one observation only |
| Context overflow | Helper returns generationFailed before generation | Whole-source Light fallback, no partial insertion |
| Translate | `Hi, how are you?` | Independent transform instructions, dictation rules absent |

The original verbose prompt was too conservative and copied the raw transcript; the shorter direct prompt improved some cases. These trials show why editing preferences must be visible/testable and why protected-literal loss needs controller checks. The checks cover literal numbers, selected negations, URLs, fenced code, whole-text quotation wrappers and introduced Cyrillic in Latin-only input. They can reject a valid edit (number reformatting/self-correction), and cannot detect every paraphrase, name error or semantic omission. Absence of a detected loss is not proof of fidelity.

## Reproduce explicitly

After a local Debug build, using an already installed model under the existing helper jail:

```sh
python3 scripts/evaluate-formatting.py \
  --helper macos/.derivedData/Build/Products/Debug/CarrotType.app/Contents/MacOS/CarrotTypeCleanupHelper \
  --mode gemma \
  --model-directory "$HOME/Library/Application Support/carrottype/models/cleanup.gemma4-e2b-4bit" \
  --output /tmp/carrottype-gemma-formatting.json
```

Use mode smart and its installed directory for a later Qwen comparison; this tool never installs weights. Synthetic text/results written only to the explicitly supplied output. Final local artifact: `dist/.builds.noindex/CarrotType-0.8.0-model-eval-final.json`. See [Debug acceptance/limits](debug-review-v0.8.0.md); no release permission inferred from automated or synthetic checks.

## Maintainer custom-rule diagnostic (Gemma, actual text trial)

The maintainer reported four rules: always remove ну; no final full stop; lowercase only; business style, then provided a Russian message to test. Tested through the actual `AppState.runFormattingTrial` → captured `DictationRules` → `DictationPipeline.formatText` → helper path, not a parallel prompt-only mock. Separate temporary bundle/defaults/stat root, global hotkeys disabled; existing installed Gemma weights read locally. No microphone/clipboard/history/statistics writes, downloads or raw maintainer message committed. Evaluation source/logs with the supplied message remain temporary local inputs only.

Original behavior: individual removal/final-stop/casing instructions reached Gemma and were partly applied; casing also lost other punctuation. The four-rule combination lowercased/removed the final stop, but ignored business tone and lost question marks. A separate synthetic case containing a protected numeric value fell back to Light, which does not interpret free-text preferences. Thus the trial wiring is working, but the result cannot be assumed to reflect successful rule compliance.

Prompt review identified conflicting generic filler/capitalization/no-paraphrase instructions. Preferences now explicitly outrank presentation defaults; only an explicit style request may change wording while retaining facts/intent. Generic few-shot style examples were rejected because they contaminated unrelated casing/removal requests. Original transcript framing and no-custom literal behavior are retained. Existing-question-mark loss is conservatively rejected; the result heading names the actual mode and fallback warning is prominent.

Final observed trial results (single runs, not a benchmark):

| Input/rules | Observed result | Assessment |
|---|---|---|
| Maintainer message + all four rules | Gemma, 16.98 s; lowercase, no last full stop; both source questions remain | Business wording still not applied; not a four-rule pass |
| Synthetic two sentences + no final stop | `Это первое предложение. Это последнее предложение` | Requested final stop removed, interior stop retained |
| Synthetic casing-only | `привет анна проверим carrottype сегодня` | Lowercase applied but unrequested punctuation lost; partial compliance |
| Synthetic business-only | Conversational wording retained | Style request not reliably followed |
| Synthetic combination with protected value | Light fallback, 8.18 s | Model result rejected; custom rules not applied, now clearly labelled |

Word-removal examples succeeded in the diagnostic, but the maintainer message itself has no ну, so it cannot establish that property. The model still does not reliably execute the full combined/style request. Do not present this diagnostic or a safer failure as a successful business-tone fix. A possible follow-up is explicit structured word/case/final-punctuation controls (deterministic application) with model tone separately evaluated; no natural-language regex parser/new model/engine is introduced here.

Synthetic counterparts are added to `scripts/fixtures/formatting-quality.json`; the raw maintainer message is not a repository fixture. Question-intent rejection has production validation checks. Qwen remains absent/unmeasured. Further arbitrary-rule quality acceptance and this version's manual/release gate remain open.


## R1–R3 rework: exact controls and separately assessed tone

Authorized after the R1–R4 plan on 2026-11-10; branch `feat/deterministic-formatting-0.8` starts from fetched main and retains the unreleased 0.8 commits. No model/runtime/weights/network change.

Exact acceptance cases live in `scripts/tests/FormattingRulesChecks.swift`: standalone/combined whole-word removal, substring/hyphen boundaries, lowercasing, interior vs terminal punctuation, quotations, ellipses, abbreviations, decimals/version numbers, newlines, code/URL/email/identifiers, defaults and idempotence. Same production path tested under Off/Light, model success, missing model and every typed failure; explicit deletion consuming all speech yields empty output without a model call. Old preferences decode with all prior fields/custom text retained and new options disabled. Native AppState checks verify final controls, stage statuses, gate/cancellation, clipboard/history/statistics invariants.

Two bounded business-prompt candidates were compared through actual AppState trial, not transform mock output: initial Russian editor instruction vs English professional-editing instruction in the original-language contract. No few-shot examples, no new model, no guard relaxation. Second candidate retained because it preserved questions in the synthetic RU example and improved the separate held-out professional wording; **neither candidate passes overall tone acceptance**.

| Synthetic case (same installed Gemma) | Candidate 1 | Candidate 2 |
|---|---|---|
| Informal project discussion | Rewritten, but omitted greeting (~9.35 s) | Wording effectively unchanged (~8.85 s) |
| Negative budget, 15 percent | Rewritten (~6.20 s) | Rejected; safe fallback (~6.07 s) |
| Two product questions | Rejected (~6.00 s) | Wording edited, two questions retained (~6.04 s) |
| English budget question | Rejected (~6.10 s) | Rejected (~6.01 s) |
| Held-out RU report/name/time/percent | Rejected (~6.38 s) | Professional wording, name/time/percent/negation/question retained (~6.92 s) |

These single cold-load observations are not latency benchmarks or proof of general semantic fidelity. The retained candidate initially returned an extra question on the private maintainer message (~14.19 s). Tone's guard now rejects invented as well as missing question marks; actual AppState rerun returned Light plus exact controls (~15.13 s), with tone marked failed. The first three requested settings work; **the four-rule scenario is still not accepted**. The private message contains no target word «ну», so deletion is established on synthetic inputs. No private message is stored here or in fixtures.

Reproducible synthetic real-AppState diagnostic: `python3 scripts/verify-formatting-app.py --build-log <successful Debug log> --model-quality`. Opt-in, installed Gemma only, no downloads, isolated temporary preferences/statistics/host identity, no microphone/clipboard writes. `structured-*` fixtures are public synthetic examples; this command prints observations, not a semantic PASS. Qwen is absent/unevaluated. Current UI calls tone experimental and distinguishes unchanged wording, generation and failure. Further product/model-quality decision is required before calling this tone feature release-ready; R3 quality gate remains open.
