# CarrotType (macOS)

Native menu bar app: hotkey → record → on-device STT → paste at caret.

## Open / build

```bash
cd macos
xcodegen generate
open CarrotType.xcodeproj
```

Or from CLI (with full Xcode selected):

```bash
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
xcodebuild -project CarrotType.xcodeproj -scheme CarrotType \
  -configuration Debug -destination 'platform=macOS,arch=arm64' \
  -skipPackagePluginValidation -skipMacroValidation \
  COMPILER_INDEX_STORE_ENABLE=NO build
```

## Release DMG

```bash
../macos/scripts/build-release-dmg.sh   # from macos/: ./scripts/build-release-dmg.sh
```

See `../ops/deploy.md`.

## First-run checklist

1. Run the app (menu bar icon).
2. Open **Settings** → download **Whisper Base (~148 MB)** (or Small / Turbo q5 / Parakeet).
3. Allow **Microphone**.
4. Enable **Accessibility** for CarrotType (debug builds may need re-enable after rebuild).
5. Status should become **Ready**.

## Dictate

1. Focus a text field in any app.
2. Press the hotkey (default **⌥/**) — recording starts.
3. Speak, then press the hotkey again — processing, then text is pasted at the caret.

Models: `~/Library/Application Support/carrottype/models/`

Engines: WhisperMetalKit (ggml), FluidAudio Parakeet (CoreML), Qwen3 MLX cleanup.
