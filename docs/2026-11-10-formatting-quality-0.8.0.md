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
