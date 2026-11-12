# Product Intent

## Context

Typing is slow for many tasks; cloud STT tools send audio off-device. Existing open-source tools (e.g. voice dictation apps) show demand for local push-to-talk, but this project starts from a narrower goal: one reliable caret paste loop on macOS, not a voice studio.

## Mission

Turn speech into text at the caret with one hotkey — fully local, private, and fast.

## Vision

Anyone can speak into any macOS app and get accurate text without leaving the keyboard flow or sending audio to the cloud.

## Intent

Build a macOS background / menu-bar app whose primary loop is:

1. Global hotkey starts recording.
2. Same hotkey stops recording: **press again** in toggle mode (default), or **release** when Walkie-talkie is on in Settings (hold-to-talk only). The modes are mutually exclusive; same dictation shortcut either way.
3. On-device STT (Parakeet Ultra only from 0.4.0; explicit download, existing installed Ultra reused) produces text. Optional live draft (ADR-014) may show adapting interim text in the Status Capsule while speaking (periodic full-buffer Parakeet preview); mic and session WAV start immediately even while Parakeet loads (v0.3.6); paste still happens only after stop via the WAV. Escape cancel with non-empty preview can offer Copy from the Capsule without pasting (v0.3.5). Dynamic Island settings may replace that status capsule with a minimal indicator or leave status to the menu bar; live draft is available only in the full capsule.
4. Optional cleanup / post-dictation formatting (Light heuristics, Qwen3 0.6B or Gemma) formats text without rewriting meaning.
5. Text is inserted at the current caret in the frontmost app.
6. Optional: keep the result on the clipboard after paste so ⌘V still works if focus moved. Starting with 0.3.10, the last completed non-empty dictation is also available to Copy from RAM until replaced, explicitly cleared, or app exit; no transcript history is written to disk. A dispatched paste is not a verified insertion in the receiving app.
7. UI language follows the system (RU/EN) with an in-app override.

**Secondary loop** (ADR-012): transform **bindings** (hotkey + Translate with a user language pair, or Custom instruction + model) read the current text selection, run an on-device LLM, and show the result in the Status Capsule (Copy / Close, optional direction) without replacing the selection. Fresh default: Translate on ⌥' with pair ru↔en. Uses the same local cleanup packages as Smart formatting; does not require formatting to be active for dictation.

Prefer a small, dependable MVP over feature breadth. Inspiration from products like TypeWhisper / Voicebox is allowed for UX direction only — no code or branding copying.

## Principles

- Local-first privacy
- Minimal friction (hotkey → paste)
- Explicit over magic
- Human control of when recording starts/stops

## Non-Goals

- Not a voice studio or voice-cloning product
- Not a cloud-first SaaS
- Not multi-platform in MVP
- Not a full IDE/plugin ecosystem

## Trade-Offs

```text
Latency & reliability of the hotkey→paste loop > Feature breadth
Local privacy > Cloud convenience
Maintainability of a small app shell > Premature multi-platform abstraction
```

## Success Criteria

- Hotkey can start/stop capture without focusing a dedicated UI.
- Transcription runs fully on-device for the chosen model path.
- Resulting text is inserted at the caret of the frontmost app.
- Audio is not uploaded by default.
- First successful end-to-end carrottype session is documented and reproducible.
- Setup UI makes readiness, active STT, and formatting mode obvious without rebuilding the app.

## Setup trial (0.6.0)

Setup guides microphone → Accessibility → Ultra → an optional local trial. Ready still uses the existing permissions/model requirements. The trial is explicitly started/stopped/cancelled by the user, runs on-device, and delivers its final text in Settings rather than at an external caret. It does not automatically change clipboard, Last Dictation or usage statistics. Only completion Boolean persists; trial text stays in RAM. Ordinary dictation and selection transforms retain their existing behavior.

## Application updates (0.5.0, ADR-017)

Manual in-app checks and opt-in automatic checks/downloads use signed GitHub Release assets. Dictation remains local and independent of update availability. Installation waits for active dictation/text processing, preserves external model/settings/statistics storage, and does not force a background restart. No profiling or transcript upload. The first updater-enabled installation is manual; notarization remains separate.

## Current product status (2026-11)

**Release 0.11.1 (36)** is prepared as a metadata-only bugfix draft/PR from the accepted `f0cff02` fix: update notes and What's New share one RU/EN resolution rule, the Sparkle presentation language follows an explicit in-app choice on the next launch, the background-download toggle explains its dependency on automatic checks, and quitting during active work drains before an install-on-quit instead of cancelling. `willInstallUpdateOnQuit` remains `false` (ADR-017) and no forced relaunch is introduced. **Release 0.11.0 (35)** with the Settings organization is published stable/latest. **v0.10.0** added the local typing-speed calibration. **v0.9.0** dedicated Dynamic Island settings with Full/default, minimal and menu-bar-only dictation presentation, released after accepted Debug and publication authorization; stored live-draft choice and transform/recovery result panels retained. **v0.8.2** cumulative missed-release notes offline and in signed standard update UI, published after signed Debug acceptance and explicit authorization. **v0.8.1** opt-in native macOS launch at sign-in, published after revised signed Debug and explicit authorization, with no automatic recording. **v0.8.0** exact word/case/first-initial/final-period controls shared by dictation/trial/fallback, two cleanup offerings with legacy compatibility and System/Light/Dark theme; released after explicit Debug acceptance, retaining disclosed experimental tone limits. **v0.7.0** native settings/accessibility/confirmation polish, General formatting access and selected carrot-microphone A brand; published after signed Debug review and explicit authorization, retaining all useful functions and local/update trust boundaries. **v0.6.2** coordinated session lifecycle, awaited teardown and generation-safe live draft; released after Debug delivery and explicit publication authorization. **v0.6.1** offline What’s New and structured localized signed update notes, released after its own Debug acceptance. **v0.6.0** guided setup/local trial, compact transform bindings and actual formatting feedback. **v0.5.0** signed native GitHub app updates with opt-in checks/downloads and installation deferred until active work ends (ADR-017), published after Debug delivery and explicit authorization. **v0.4.0** Ultra-only STT, explicit migration and optional confirmed legacy-model cleanup (ADR-016), released after separate Debug acceptance. **v0.3.10** last dictation recovery in RAM, ownership-aware clipboard restore, visible operation errors and bounded cleanup helper IPC; Debug manually accepted before release. **v0.3.8** Storage Settings: installed packages inventory plus catalog-scoped Hugging Face download cache clear. **v0.3.7** Secure Coding hardening (ADR-015): helper model-path jail, MLX Hub `hubRevision` pins, clipboard restore/copy honesty; notarization still optional prep only. **v0.3.6** live draft starts recording before Parakeet model load so speech during cold start is not lost; Capsule preview attaches when ready; final paste unchanged. **v0.3.5** Escape cancel during live draft with non-empty preview keeps a **Copy / Close** Capsule snapshot (no caret paste); normal stop unchanged. **v0.3.4** adds optional **live draft** in the Status Capsule (ADR-014): while speaking with Parakeet, the Capsule shows an adapting preview (full-buffer offline re-transcribe); paste still only after stop via the session WAV. Default off. **v0.3.3** added optional **Parakeet Ultra** beside Parakeet TDT 0.6B v3; the default download for a new install stays v3. **v0.3.2** adds a month **character** total next to successful dictations in Settings → Statistics, and moves typing speed (WPM) above Bindings. **v0.3.1** is a packaging patch: the unsigned DMG install window no longer shows `.background` / `.fseventsd`. **v0.3.0** ships **local opt-in usage statistics** (ADR-013). Also includes Walkie-talkie, Selection Transform (ADR-012), optional Gemma cleanup (ADR-010), Status Capsule chrome, OOP cleanup helper (ADR-009). Since **0.4.0**, Ultra is the sole offered/default STT (ADR-016); old weights are retained for explicit optional cleanup. Distribution posture (ADR-011): **MIT** source; repository **may be public**; notarization is optional later.

## Dictation preferences — 0.8.0

Optional local rules guide filler/repetition/self-correction handling, paragraphs and term spelling without turning dictation into translation or answering questions. The base instruction preserves meaning/language/numbers/negations; model compliance is not guaranteed. General exposes a text-only local trial and honest Light fallback when formatting fails. Rules apply to the next session and remain separate from Translate/Custom. Existing Smart+ users/bindings retain compatibility; new choices are Qwen3 0.6B/Gemma. Independent System/Light/Dark theme defaults to System, matching language's system-first approach. No transcript persistence or model/default STT change.

Explicit presentation/word/tone preferences override generic cleanup defaults. A requested tone may change wording while retaining content and intent; without such a request the cleanup stays literal. Free-text preferences are model guidance, not guaranteed executable rules. Trial feedback must name the actual applied mode and make rejected model output/Light fallback clear.


0.8 rework: explicit word deletion, prose lowercase and last-sentence full-stop controls are deterministic opt-ins independent of model availability, including when Off is selected. Existing preferences/custom text are preserved. Model-based business tone is separately labelled experimental and must not be presented as reliably completed merely because generation or safe fallback succeeded. Current quality acceptance is open.

## Dynamic Island — 0.9.0 (published)

The maintainer accepted the signed Debug and authorized publication («можно публиковать»). Version 0.9.0 (33) packages the approved Full/Minimal/Menu-bar-only presentation modes and dedicated untranslated Dynamic Island pane, with preserved live-draft preference and transform/recovery exceptions. Application source is frozen at `0908750`; only metadata/notes/history/docs change. Published stable/latest as 0.9.0 (33) after verified Release/draft/signatures and Codex final gate. GigaAM is not part of this release.

## Dynamic Island modes — pre-release prototype (2026-11-11)

The maintainer approved a focused presentation choice for the next Debug prototype: Full capsule (default), Minimal indicator, or Menu bar only, configured in a dedicated Settings pane. This changes only the visibility/shape of dictation status, not local dictation, result delivery, RAM recovery or trust boundaries. Transform results and paste-failure recovery remain visible in every mode; when the status capsule is suppressed, a Light fallback warning stays available in the menu and Details. No version or publication is assigned by this prototype.

## Typing-speed calibration — 0.10.0 (authorized, draft prepared)

Statistics gains an optional local **Measure…** sheet for choosing the existing estimate more
accurately. It is a small native 30-second typing calibration, not a game, account or ranking:
RU/EN text with Easy/Medium/Advanced difficulty is composed from original bundled corpora, and
the result stays in RAM. Only an explicit **Use N WPM** writes the existing global setting;
cancelling, closing, repeating or an out-of-range/unsupported result never changes it, and
collection stays exactly as the user left it. The feature needs no model, microphone,
Accessibility, network or Ready state and stores no attempt text, keys or history.

The maintainer accepted the delivered signed Debug and authorized publication:
«мне нравится, можем публиковать». Release 0.10.0 (34) freezes application behavior at
`1736262`, preserves manual WPM editing and the untranslated Dynamic Island pane, and excludes
GigaAM and the separate settings reorganization. Individual device/IME/VoiceOver/TCC outcomes
were not enumerated; those independent limits remain. The verified draft/PR awaits the Codex
final gate; stable/latest remains 0.9.0 (33) until that gate.


## 0.10.0 publication closeout — 2026-11-12 (Moscow)

Maintainer accepted the delivered Debug and explicitly authorized publication: «мне нравится, можем публиковать». Stable/latest **0.10.0 (34)** published at 2026-11-11T21:09:29Z (00:09 Moscow, November 12). Accepted application code `1736262`, metadata `7c1dfdc`, immutable tag/source `v0.10.0` / `3b14844`; final premerge head `99a7bbc` differs from the tag only in documentation. PR #31 merged as `bd387d8`. Final-head hosted macOS checks **43099456972 passed** (5m46s); private hosted AIDOS explicitly skipped, local validate/trace/review passed.

Correction to preparation-era statements: the docs-only `99a7bbc` push automatically created a second CI run; earlier run 43096217758 was superseded. Thus the prior “no duplicate run” statement is incorrect. GitHub Actions major outage delayed scheduling; final-head CI subsequently succeeded. No workflow/runner bypass or unverified CI success was used.

Coordinator independently checked PR/head/tag/application-source freeze and successful final-head CI, reran authenticated draft signature/identity/version/length/URL gate, merged the exact checked head, and published the already verified draft. Post-publication `verify-update-release.py --published` passed public latest/archive signatures, metadata, URLs and asset digests. Native resolved Sparkle CLI with isolated manual-A build33 identity and production public key probed the live HTTPS latest feed: exit0, update available; probe only, no installation (log `dist/public-native-0.10.0.log`). DMG/ZIP/feed hashes remain those recorded above. Self-signed/unnotarized posture, candidate-code fixture and independent device/IME/VoiceOver/TCC limitations remain. No installed app, user preferences/models/login items or private keys were changed/exported.

Next authorized work: settings reorganization (General, Dictation including formatting, Text actions) on a new branch/worktree from updated main, via **OpenCode 2** under the maintainer’s latest instruction «давай тогда через opencode продолжим». Codex retains design/review. Direct ZCode readiness did not work; do not claim it is executing. No publication authorization for that future version is inferred.

## Settings organization — 0.11.0 (authorized, draft prepared)

The maintainer accepted the delivered Settings organization Debug and authorized publication:
«все ок, можно публиковать», correcting the version because stable is already 0.10.0 (34). Release
**0.11.0 (35)** freezes application behavior at `6cb6212`, so only version metadata, RU/EN notes,
immutable history and documentation change. The sidebar is ordered **General / Dictation / Text
actions / Dynamic Island / Setup / Models / Storage / Statistics**: General owns language, theme,
updates and launch-at-login; Dictation owns the existing shortcut/PTT/clipboard controls plus the
existing Ready-only formatting selector, exact rules, model preferences/My Rules and text trial;
Text actions owns the unchanged Translate/Custom bindings.

Window size, the 720×520 minimum, saved values and defaults are unchanged; only the navigation
list scrolls while Details, version and What’s New stay pinned. No runtime, engine, model, prompt,
helper, dictation/transform, statistics, updater, trust, network, dependency or history change.
GigaAM is excluded. Individual device/IME/VoiceOver/TCC outcomes were not enumerated. Published
stable/latest as 0.11.0 (35) on 2026-11-12 after the verified draft, hosted CI and public gate;
tag `v0.11.0` is `791603e`, PR #32 merged as `b1ba27e`.
