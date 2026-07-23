# Environments

## Local (developer)

- OS: macOS 14+ (Apple Silicon preferred)
- Runtime: Swift / **Xcode 15+ (full Xcode.app)**
- Package manager: Swift Package Manager (via Xcode); app project via XcodeGen (`macos/project.yml`)
- App sources: `macos/CarrotType/`
- Generate project:

```bash
cd macos
xcodegen generate
open CarrotType.xcodeproj
```

- Tooling clone: sibling `../AIDOS` (see `aidos.config.json`)
- Governance validation (from project root):

```bash
npm run aidos:validate
npm run aidos:trace
npm run aidos:review
```

### Permissions checklist

- Microphone: required for capture (usually persists by Bundle ID across Rebuild).
- Accessibility: required for caret paste. After an Xcode Rebuild, macOS treats the binary as new — enable the **current** CarrotType row again (there may be duplicates; remove old ones with −).

CarrotType polls TCC only while mic or Accessibility is still missing; once both are Granted, polling stops and `didBecomeActive` / return from System Settings refresh status.

### Resource budget (idle vs peak)

| Mode | Expected footprint |
|------|--------------------|
| **Idle** (menu bar only, Settings closed, Ready) | Carbon hotkey + menu bar; **no** AVAudioEngine, **no** 30 Hz timers, **no** permission poll, STT/cleanup models unloaded right after each session |
| **Settings open** | Optional mic level meter (`AudioLevelMonitor`) while the window is visible |
| **Recording** | Session-scoped `AudioRecorder` + 30 Hz level decay for notch waveform; optional temporary unmute (ADR-007) is HAL/Wave Link only — does not keep an idle engine |
| **Peak (dictation)** | Load active STT (Whisper ggml or Parakeet CoreML) + optional Qwen3 MLX for Smart cleanup; unload immediately when the session ends |

### Build / run

1. Open `macos/CarrotType.xcodeproj` in Xcode (or `xcodegen generate` in `macos/`)
2. First MLX build may need Metal tooling: `xcodebuild -downloadComponent MetalToolchain`
3. CLI builds that pull mlx-swift / mlx-swift-lm may need:

```bash
cd macos
xcodebuild -project CarrotType.xcodeproj -scheme CarrotType \
  -destination 'platform=macOS,arch=arm64' \
  -skipPackagePluginValidation -skipMacroValidation \
  COMPILER_INDEX_STORE_ENABLE=NO build
```

4. Run the **CarrotType** scheme on “My Mac”
5. Menu bar icon → **Настройки…**
6. Grant Microphone + Accessibility; download Whisper Base (or Parakeet); optional Smart Qwen3
7. After Rebuild: if Accessibility shows off, click **Зарегистрировать эту сборку**, enable the new list entry

### Note on this machine

If `xcodebuild` reports that only Command Line Tools are active, install Xcode from the App Store and run:

```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

## Test

- Unit: XCTest for pure logic (planned: catalog decode, readiness rules)
- Manual E2E (after inference wiring): TextEdit + browser field; airplane mode for local models

## Staging / Production

- Not used as hosted services for MVP
- “Production” = GitHub Release `.dmg` from `macos/scripts/build-release-dmg.sh`
- v1: unsigned / self-signed + Gatekeeper Right-click → Open (`ops/deploy.md`)
- Later: Developer ID + notarization (same DMG script, paid Apple Developer)
