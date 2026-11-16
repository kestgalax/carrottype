import type { FC } from "react";
import { AbsoluteFill, interpolate } from "remotion";
import { EndCard } from "motion-os/core";
import type { BeatMap, SettingsTogglePayoffScenes } from "motion-os/templates/settings-toggle-payoff";
import { BrandMark } from "./BrandMark";
import { DictationPane } from "./DictationPane";
import { MicPrioritySheet } from "./MicPrioritySheet";
import { copy, iris as irisPoint } from "./micPriority";
import { tokens } from "./theme";

export { copy, tokens };
export const iris = irisPoint;

/**
 * 0.12.0 mic priority film (~28 s). One active skin per consumer root
 * (motion-os pin 557ec2c): this film owns `motion/skin/index.tsx`. The 0.8.0
 * theme skin wiring is preserved in `themeFilm.tsx` for re-runs of
 * `motion/briefs/theme.md`.
 */
export const beats: BeatMap = {
  establish: { from: 0, to: 36 },
  settings: { from: 36, to: 292 },
  iris: { from: 264, to: 292 },
  payoff: { from: 264, to: 660 },
  endcard: { from: 660, to: 756 },
  duration: 756,
};

const clamp = {
  extrapolateLeft: "clamp" as const,
  extrapolateRight: "clamp" as const,
};

const Establish: FC<{ frame: number }> = ({ frame }) => {
  const opacity = interpolate(frame, [0, 10], [0, 1], clamp);
  return (
    <AbsoluteFill style={{ alignItems: "center", justifyContent: "center", opacity }}>
      <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 18 }}>
        <BrandMark accent={tokens.accent} label={tokens.label} size={34} />
        <div style={{ color: tokens.labelMuted, fontFamily: tokens.fontFamily, fontSize: 18 }}>
          {copy.establishEyebrow}
        </div>
      </div>
    </AbsoluteFill>
  );
};

/** Settings local frames 0 → 256. Compact row, then an effect click on «Настроить…». */
const SettingsAct: FC<{ frame: number }> = ({ frame }) => {
  const fade = interpolate(frame, [0, 16], [0, 1], clamp);
  const rise = (1 - fade) * 12;
  const ringOpacity = interpolate(frame, [118, 134, 190, 206], [0, 1, 1, 0], clamp);
  const press = interpolate(frame, [168, 172, 182], [0, 1, 0], clamp);
  return (
    <AbsoluteFill style={{ opacity: fade, transform: `translateY(${rise}px)` }}>
      <DictationPane
        fontFamily={tokens.fontFamily}
        activeMic={copy.activeMicBefore}
        ringOpacity={ringOpacity}
        press={press}
        frame={frame}
      />
    </AbsoluteFill>
  );
};

/** Payoff local frames 0 → 462. Sheet drag act, Готово, then the compact row payoff. */
const Payoff: FC<{ frame: number }> = ({ frame }) => {
  const dim = interpolate(frame, [0, 18, 264, 300], [0, 1, 1, 0], clamp);
  const highlight = interpolate(frame, [320, 360], [0, 1], clamp);
  const noteOpacity = interpolate(frame, [316, 348], [0, 1], clamp);
  const promoted = frame >= 262;
  return (
    <AbsoluteFill>
      <DictationPane
        fontFamily={tokens.fontFamily}
        activeMic={promoted ? copy.activeMicAfter : copy.activeMicBefore}
        dim={dim}
        highlight={highlight}
        frame={frame}
      />
      <MicPrioritySheet fontFamily={tokens.fontFamily} accent={tokens.accent} frame={frame} />
      <AbsoluteFill
        style={{
          opacity: noteOpacity,
          alignItems: "center",
          justifyContent: "flex-end",
          paddingBottom: 84,
        }}
      >
        <div
          style={{
            color: tokens.labelMuted,
            fontFamily: tokens.fontFamily,
            fontSize: 17,
            letterSpacing: "0.01em",
          }}
        >
          {copy.appliedNote}
        </div>
      </AbsoluteFill>
    </AbsoluteFill>
  );
};

const End: FC<{ frame: number }> = ({ frame }) => (
  <EndCard
    frame={frame}
    headline={copy.headline}
    subline={copy.subline}
    tokens={tokens}
    disclaimer={copy.disclaimer}
    mark={<BrandMark accent={tokens.accent} label={tokens.label} size={22} />}
  />
);

export const scenes: Partial<SettingsTogglePayoffScenes> = {
  Establish,
  SettingsAct,
  Payoff,
  EndCard: End,
};
