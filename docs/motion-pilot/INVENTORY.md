# Motion pilot inventory

Classification of Remotion `src` trees and capture/adapters for the three Pass pilots
(`2026-11-13-island-livedraft-v3`, `2026-11-13-typing-speed`, `2026-11-13-theme`).
Source listing: 41 `.ts`/`.tsx` files under each pilot's `remotion/src` (2026-11-13).

## Core candidates (product-agnostic)

| Path | Why core |
|------|----------|
| `artifacts/motion-pilot/2026-11-13-island-livedraft-v3/remotion/src/components/DesktopStage.tsx` | Shared staged desktop atmosphere (gradient, notch brow, vignette) |
| `artifacts/motion-pilot/2026-11-13-typing-speed/remotion/src/components/DesktopStage.tsx` | Same stage shell as island/theme |
| `artifacts/motion-pilot/2026-11-13-theme/remotion/src/components/DesktopStage.tsx` | Same stage shell as island/typing |
| `artifacts/motion-pilot/2026-11-13-theme/remotion/src/components/EffectClick.tsx` | Effect-click language: accent ring + press flash (no cursor) |
| `artifacts/motion-pilot/2026-11-13-island-livedraft-v3/remotion/src/components/SettingsEnableScene.tsx` | Rings + stepper over `OffthreadVideo` (inline ring boxes on capture) |
| `artifacts/motion-pilot/2026-11-13-typing-speed/remotion/src/components/SettingsMeasureScene.tsx` | Ring highlights timed to AX frames on Settings capture |
| `artifacts/motion-pilot/2026-11-13-theme/remotion/src/components/SettingsThemeScene.tsx` | `EffectClick` overlays on Settings capture |
| `artifacts/motion-pilot/2026-11-13-island-livedraft-v3/remotion/src/CarrotTypeIslandPolish.tsx` | Master: Settings act → notch `clip-path` iris → staged act |
| `artifacts/motion-pilot/2026-11-13-theme/remotion/src/CarrotTypeThemeFilm.tsx` | Master: Settings act → control-centred iris → staged payoff |
| `artifacts/motion-pilot/2026-11-13-typing-speed/remotion/src/CarrotTypeTypingSpeedFilm.tsx` | Master: Settings act → Start-button iris → staged sheet family |
| `artifacts/motion-pilot/2026-11-13-island-livedraft-v3/remotion/src/components/EndCard.tsx` | Shared end-card shell (headline, subline, spring rise) |
| `artifacts/motion-pilot/2026-11-13-typing-speed/remotion/src/components/EndCard.tsx` | Same end-card pattern |
| `artifacts/motion-pilot/2026-11-13-theme/remotion/src/components/EndCard.tsx` | Same end-card pattern |
| `artifacts/motion-pilot/2026-11-13-island-livedraft-v3/remotion/src/lib/timings.ts` | Global beat map + iris/transition frame constants |
| `artifacts/motion-pilot/2026-11-13-typing-speed/remotion/src/lib/timings.ts` | Beat map + iris + staged sheet segment offsets |
| `artifacts/motion-pilot/2026-11-13-theme/remotion/src/lib/timings.ts` | Beat map + theme iris origin frames |
| `artifacts/motion-pilot/2026-11-13-island-livedraft-v3/remotion/src/Root.tsx` | Remotion composition registration |
| `artifacts/motion-pilot/2026-11-13-island-livedraft-v3/remotion/src/index.ts` | Remotion bundle entry |
| `artifacts/motion-pilot/2026-11-13-typing-speed/remotion/src/Root.tsx` | Remotion composition registration |
| `artifacts/motion-pilot/2026-11-13-typing-speed/remotion/src/index.ts` | Remotion bundle entry |
| `artifacts/motion-pilot/2026-11-13-theme/remotion/src/Root.tsx` | Remotion composition registration |
| `artifacts/motion-pilot/2026-11-13-theme/remotion/src/index.ts` | Remotion bundle entry |

## Skin candidates (CarrotType-specific)

| Path | Why skin |
|------|----------|
| `artifacts/motion-pilot/2026-11-13-island-livedraft-v3/remotion/src/components/StatusCapsule.tsx` | Dynamic Island / live-draft capsule chrome |
| `artifacts/motion-pilot/2026-11-13-theme/remotion/src/components/StatusCapsule.tsx` | Capsule recreation for theme payoff |
| `artifacts/motion-pilot/2026-11-13-island-livedraft-v3/remotion/src/components/LiveDraftBody.tsx` | Scripted live-draft transcript tiles |
| `artifacts/motion-pilot/2026-11-13-island-livedraft-v3/remotion/src/CarrotTypeIslandFilm.tsx` | Staged island result sequence (capsule + draft) |
| `artifacts/motion-pilot/2026-11-13-island-livedraft-v3/remotion/src/components/BeatLabel.tsx` | On-screen beat labels for island film |
| `artifacts/motion-pilot/2026-11-13-theme/remotion/src/components/ThemePayoffScene.tsx` | Staged Settings + capsule theme morph payoff |
| `artifacts/motion-pilot/2026-11-13-typing-speed/remotion/src/components/SheetChrome.tsx` | Native-style typing-test sheet chrome |
| `artifacts/motion-pilot/2026-11-13-typing-speed/remotion/src/components/TypingSheetRunning.tsx` | Sheet **Running** state (timer, prompt, progress) |
| `artifacts/motion-pilot/2026-11-13-typing-speed/remotion/src/components/TypingSheetResult.tsx` | Sheet **Result** state (WPM, Use) |
| `artifacts/motion-pilot/2026-11-13-typing-speed/remotion/src/components/StepRail.tsx` | Persistent story stepper (Statistics → test → result) |
| `artifacts/motion-pilot/2026-11-13-island-livedraft-v3/remotion/src/components/BrandMark.tsx` | CarrotType wordmark on stage |
| `artifacts/motion-pilot/2026-11-13-typing-speed/remotion/src/components/BrandMark.tsx` | CarrotType wordmark on stage |
| `artifacts/motion-pilot/2026-11-13-theme/remotion/src/components/BrandMark.tsx` | CarrotType wordmark on stage |
| `artifacts/motion-pilot/2026-11-13-island-livedraft-v3/remotion/src/lib/demoCopy.ts` | RU/EN marketing strings for island film |
| `artifacts/motion-pilot/2026-11-13-typing-speed/remotion/src/lib/demoCopy.ts` | RU/EN copy for sheet + rail + end card |
| `artifacts/motion-pilot/2026-11-13-theme/remotion/src/lib/demoCopy.ts` | RU/EN copy for theme establish + end card |
| `artifacts/motion-pilot/2026-11-13-island-livedraft-v3/remotion/src/lib/theme.ts` | Carrot palette, capsule metrics, fonts |
| `artifacts/motion-pilot/2026-11-13-typing-speed/remotion/src/lib/theme.ts` | Carrot accent + sheet colours + stage metrics |
| `artifacts/motion-pilot/2026-11-13-theme/remotion/src/lib/theme.ts` | Carrot accent + light/dark payoff tokens |
| `artifacts/motion-pilot/2026-11-13-typing-speed/remotion/src/CarrotTypeTypingSpeedFilm.tsx` | Wires sheet skin scenes into hybrid timeline (product story) |

## Adapter candidates

| Path / script | Why adapter |
|---------------|-------------|
| `/tmp/ctpilot/menupress` (host binary; see island/typing/theme `report.md`) | AX press exact `Настройки…` / `Settings…` on extras menu |
| `/tmp/ctpilot/ui` | AX traversal: sidebar rows, toggles, sheet buttons inside Settings |
| `/tmp/ctpilot/winid` | Resolve Settings `CGWindow` id for window-only capture |
| `/tmp/ctpilot/theme` (theme pilot only; `report.md` §4.1) | AX `menupick` on Theme pop-up (e.g. Светлая) |
| `artifacts/motion-pilot/2026-11-13-island-livedraft-v3/report.md` (§0.2 bash) | `screencapture -x -v -l<WINDOW_ID>` + FFmpeg crop/speed → `settings-enable.mp4` |
| `artifacts/motion-pilot/2026-11-13-typing-speed/report.md` (§4.1) | Same capture pipeline → `settings-measure.mp4` |
| `artifacts/motion-pilot/2026-11-13-theme/report.md` (§4.1) | Capture + timed `menupick` during `screencapture -l` |
| `artifacts/motion-pilot/2026-11-13-island-livedraft-v3/capture-settings-raw.mov` | Raw window-only screen recording (adapter output) |
| `artifacts/motion-pilot/2026-11-13-typing-speed/capture-settings-raw.mov` | Raw window-only screen recording |
| `artifacts/motion-pilot/2026-11-13-theme/capture-settings-raw.mov` | Raw window-only screen recording |
| `artifacts/motion-pilot/2026-11-13-island-livedraft-v3/remotion/public/settings-enable.mp4` | Prepared clip consumed by `SettingsEnableScene` |
| `artifacts/motion-pilot/2026-11-13-typing-speed/remotion/public/settings-measure.mp4` | Prepared clip consumed by `SettingsMeasureScene` |
| `artifacts/motion-pilot/2026-11-13-theme/remotion/public/settings-theme.mp4` | Prepared clip consumed by `SettingsThemeScene` |

## Proven template families

| Family id | Films | Hero |
|-----------|-------|------|
| `settings-toggle-payoff` | island-v3, theme | Settings control → visual result (`SettingsEnableScene` / `SettingsThemeScene` → `CarrotTypeIslandFilm` + `StatusCapsule` or `ThemePayoffScene`) |
| `sheet-result` | typing-speed | Sheet Ready → Running → Result (`SettingsMeasureScene` capture hand-off → `TypingSheetRunning` → `TypingSheetResult` + `StepRail`) |

## Additional proven families (Motion OS extract gate)

| Family id | Films | Hero |
|-----------|-------|------|
| `onboarding-tour` | `2026-11-13-onboarding-tour` | Welcome → Continue → Setup Mic / Accessibility / Ultra / local trial |
| `whats-new-sheet` | `2026-11-13-whats-new` | What’s New sheet: current release → cumulative history → Got it |

