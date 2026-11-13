# Skin API draft (pre-extract)

Contracts for Task 8 (`motion-os` + consumer `motion/skin`). Source inventory: `INVENTORY.md`.

## motion.config (consumer)

```json
{
  "core": "motion-os@0.0.0-local",
  "template": "settings-toggle-payoff",
  "audio": "silent",
  "capture": "optional"
}
```

| Field | Values | Notes |
|-------|--------|-------|
| `core` | semver pin | Package that ships `motion-os/core` and `templates/` |
| `template` | `settings-toggle-payoff` \| `sheet-result` | Selects required `scenes` keys (below) |
| `audio` | `silent` (pilot default) | Future: bed / VO hooks |
| `capture` | `optional` \| `required` | When `required`, consumer must run adapter or supply clip paths in brief |

## Skin module exports (TypeScript intent)

Consumer package entry (e.g. `motion/skin/index.ts`):

```ts
export const tokens: {
  colors: Record<string, string>;
  fonts: Record<string, string>;
  radii: Record<string, number>;
};

export const scenes: Record<string, React.FC>; // required keys per template

export const copy: Record<string, string>;
```

- **tokens** — from pilot `lib/theme.ts` (palette, capsule metrics, sheet colours); layout-only metrics may later split into core.
- **scenes** — product-specific staged UI; core template wires iris, capture slot, and beat map.
- **copy** — from pilot `lib/demoCopy.ts` (RU/EN marketing strings keyed by scene).

## Template: `settings-toggle-payoff` — required scenes

| Scene key | Role | Pilot exemplars |
|-----------|------|-----------------|
| `Establish` | Stage + brand atmosphere | `BrandMark`, `DesktopStage` skin props |
| `SettingsAct` | Capture slot + highlight overlays | `SettingsEnableScene` (island), `SettingsThemeScene` (theme) |
| `Payoff` | Staged result after iris | `CarrotTypeIslandFilm` + capsule (island), `ThemePayoffScene` (theme) |
| `EndCard` | Closing headline / subline | Skin copy + core shell (`EndCard.tsx` in core) |

Films: island-livedraft-v3, theme (`INVENTORY.md` § Proven template families).

## Template: `sheet-result` — required scenes

| Scene key | Role | Pilot exemplars |
|-----------|------|-----------------|
| `Establish` | Stage + story setup | `BrandMark`, `StepRail` (rail may span acts) |
| `SheetReady` | Pre-test sheet chrome | `SheetChrome` (ready state) |
| `SheetRunning` | In-progress test | `TypingSheetRunning` |
| `SheetResult` | WPM / CTA payoff | `TypingSheetResult` |
| `EndCard` | Closing | Skin copy + core `EndCard` shell |

Film: typing-speed. `SettingsAct` equivalent (`SettingsMeasureScene`) lives in **core template timeline** between establish and iris; not a separate skin scene key in this family.

## Template: onboarding-tour — required scenes

- `Establish`
- `Welcome`
- `SetupSteps` (Mic → Accessibility → Ultra → local trial progression)
- `EndCard`

## Template: whats-new-sheet — required scenes

- `Establish`
- `WhatsNewSheet` (current release + history list)
- `Dismiss` (Got it / effect click)
- `EndCard`

## Adapter interface (optional)

```ts
type CaptureBrief = {
  template: "settings-toggle-payoff" | "sheet-result";
  windowTitle?: string;
  steps?: string[]; // AX actions, e.g. menupick
};

type CaptureAdapter = {
  capture(brief: CaptureBrief): Promise<{
    clips: { id: string; path: string }[];
    meta: Record<string, string>;
  }>;
};
```

Clip ids align with template capture slots, e.g. `settings-enable`, `settings-measure`, `settings-theme` (see `remotion/public/*.mp4` in adapter inventory).

---

## Inventory cross-check

Each `INVENTORY.md` row names its extraction target for that column: **Core** → `motion-os/core` or `templates/`; **Skin** → consumer `motion/skin`. The same source path may appear in both tables when core owns the post-extract timeline and skin keeps a pre-extract wiring reference (dual-classified rows are intentional, not duplicate mappings).

### Core candidates → `motion-os/core` or `templates/`

| Inventory path | Target | Rationale |
|----------------|--------|-----------|
| `…/components/DesktopStage.tsx` (3 pilots) | `motion-os/core/stage/DesktopStage` | Product-agnostic stage shell |
| `…/components/EffectClick.tsx` | `motion-os/core/effects/EffectClick` | Reusable highlight language |
| `…/components/SettingsEnableScene.tsx` | `templates/settings-toggle-payoff/SettingsAct` (core capture wrapper) | Generic rings + `OffthreadVideo` |
| `…/components/SettingsMeasureScene.tsx` | `templates/sheet-result/SettingsAct` (core capture wrapper) | AX-timed rings on capture |
| `…/components/SettingsThemeScene.tsx` | `templates/settings-toggle-payoff/SettingsAct` (variant) | `EffectClick` on capture |
| `…/CarrotTypeIslandPolish.tsx` | `templates/settings-toggle-payoff/timeline` (island variant) | Master: Settings → iris → staged act |
| `…/CarrotTypeThemeFilm.tsx` | `templates/settings-toggle-payoff/timeline` (theme variant) | Master: Settings → theme iris |
| `…/CarrotTypeTypingSpeedFilm.tsx` † | `templates/sheet-result/timeline` | Master: Settings → iris → sheet segments |
| `…/components/EndCard.tsx` (3 pilots) | `motion-os/core/scenes/EndCard` | Shared motion shell; copy from skin |
| `…/lib/timings.ts` (3 pilots) | `templates/<family>/timings` | Per-template beat maps |
| `…/Root.tsx` (3 pilots) | `motion-os/core/remotion/Root` (dev harness) | Composition registration |
| `…/index.ts` (3 pilots) | `motion-os/core/remotion/index` | Bundle entry |

**Count:** 22 inventory rows — all mapped (DesktopStage / EndCard / Root / index counted per pilot file path).

### Skin candidates → `motion/skin`

| Inventory path | Target | Scene / export |
|----------------|--------|----------------|
| `…/StatusCapsule.tsx` (island, theme) | `motion/skin/components/StatusCapsule` | `Payoff` (capsule chrome) |
| `…/LiveDraftBody.tsx` | `motion/skin/components/LiveDraftBody` | `Payoff` |
| `…/CarrotTypeIslandFilm.tsx` | `motion/skin/scenes/PayoffIsland` | `Payoff` |
| `…/BeatLabel.tsx` | `motion/skin/components/BeatLabel` | optional debug overlay |
| `…/ThemePayoffScene.tsx` | `motion/skin/scenes/PayoffTheme` | `Payoff` |
| `…/SheetChrome.tsx` | `motion/skin/components/SheetChrome` | `SheetReady` |
| `…/TypingSheetRunning.tsx` | `motion/skin/scenes/SheetRunning` | `SheetRunning` |
| `…/TypingSheetResult.tsx` | `motion/skin/scenes/SheetResult` | `SheetResult` |
| `…/StepRail.tsx` | `motion/skin/components/StepRail` | spans `Establish` → `SheetResult` |
| `…/BrandMark.tsx` (3 pilots) | `motion/skin/components/BrandMark` | `Establish` |
| `…/lib/demoCopy.ts` (3 pilots) | `motion/skin/copy` | `copy` export |
| `…/lib/theme.ts` (3 pilots) | `motion/skin/tokens` | `tokens` export |
| `…/CarrotTypeTypingSpeedFilm.tsx` † | `motion/skin` (reference composition) | Pre-extract wiring reference; superseded by `templates/sheet-result/timeline` + scene map |

**Count:** 20 inventory rows — all mapped.

† `CarrotTypeTypingSpeedFilm.tsx` is dual-classified: core timeline target above; skin row documents interim composition wiring until Task 8 extract.

### Adapter candidates (out of skin API scope)

Adapter rows in `INVENTORY.md` implement `CaptureAdapter` or supply static clips; they are not shipped in `motion/skin`. Task 8 may vendor scripts or document `/tmp/ctpilot` host binaries separately.

---

## Open extraction notes (for Task 8)

1. **Inline rings vs `EffectClick`** — island `SettingsEnableScene` vs theme; unify in core during extract.
2. **`lib/theme.ts` on skin** — may split layout metrics into core tokens vs brand palette on skin (see Task 2 report).
3. **`CarrotTypeTypingSpeedFilm.tsx` dual listing** — inventory Skin row is the product timeline reference; core owns `templates/sheet-result/timeline` after extract.
