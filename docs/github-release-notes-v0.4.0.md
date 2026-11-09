# CarrotType v0.4.0 — GitHub Release notes

**Distribution:** public MIT repository. DMG without Apple Developer ID notarization; first launch may require **System Settings → Privacy & Security → Open Anyway**.

## Download

`CarrotType-0.4.0.dmg` — Apple Silicon, macOS 14+, build 24. Model weights are downloaded separately.

SHA-256: `0e7f4e3d97590bc122d33fe1be7078fd684cce7e282dc206e0edc78588b2c481`.

## What changed

- **One dictation model: Parakeet Ultra.** The STT picker and alternative Whisper, Parakeet v3 and Apple SpeechAnalyzer offerings are removed. Ultra retains Russian/English auto language, live draft and the existing offline file-based final transcription.
- **Simpler Models pane:** Ultra state, download/cancel/retry/delete; an already-installed Ultra is reused without a new download. Whisper/Apple adapters and the WhisperMetalKit dependency are removed.
- **Explicit migration:** old or unknown saved STT selections map to Ultra. Downloads never start automatically. If only a retired model is installed, download Ultra explicitly in Models before dictating.
- **Optional legacy cleanup:** Storage lists known retired model files separately, with confirmation before deletion. Old weights are not deleted automatically; Ultra, formatting models, unknown experimental packages and shared Apple speech assets are preserved. The Apple entry removes only CarrotType's local preparation marker.

Formatting Off/Light/Smart/Smart+/Gemma, Translate/Custom bindings, hold-to-talk, Wave Link, microphone/meter, RU/EN, clipboard/recovery and opt-in statistics remain. In-app updates are a later version, not included here.

## Install / update

1. Quit the running CarrotType, including any Debug test copy.
2. Open the DMG and drag **CarrotType** into **Applications**, replacing the previous application.
3. If Gatekeeper blocks launch: attempt to open CarrotType in Finder, then **System Settings → Privacy & Security → Open Anyway**, and confirm. Right-click → Open alone may be insufficient.
4. Recheck **Microphone** and **Accessibility** permissions if macOS requests them. Existing settings, formatting models, bindings and statistics remain.
5. In Models, download **Parakeet Ultra** if it is not already installed. An older STT installation alone does not provide offline dictation in 0.4.0.

Retain old weights until the Ultra migration is accepted if you want to return to 0.3.10. Removing them later is optional; using the retired model again in an older application may require re-downloading it.

## Verification and limits

- Debug 0.4.0 (24), production catalog/migration/legacy-storage tests, clipboard/helper regressions and existing live-draft/Wave Link checks passed. The maintainer confirmed the manual checklist and explicitly authorized publication on 2026-11-10.
- Clean Release arm64 build passed. Final DMG integrity, deep app signature, Ultra-only resource catalog, absence of Whisper linkage/framework, helper path jail and MLX shaders were verified. Installer layout/background were preserved byte-for-byte from the checksum-verified 0.3.10 DMG.
- Supplementary local synthetic RU/EN comparison with v3 found comparable results on two samples, including the same RU substitution. This is not a broad quality or speed benchmark; no claim of universal model superiority.
- No new inference runtime or network sink. With Ultra installed, dictation remains on-device; a full independent offline network audit remains deferred.
- Existing CGEvent paste-acknowledgement, selection-copy clipboard ambiguity and FluidAudio downloader residuals remain documented. This release simplifies the product and is not a claim that those risks are resolved.
