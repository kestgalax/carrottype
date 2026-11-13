import type { FC } from "react";
import { AbsoluteFill, interpolate } from "remotion";
import { ClickRing, EndCard } from "motion-os/core";
import type { BeatMap, SettingsTogglePayoffScenes } from "motion-os/templates/settings-toggle-payoff";
import { BrandMark } from "./BrandMark";
import { StatusCapsule } from "./StatusCapsule";
import { ThemePane } from "./ThemePane";
import { darkPane, iris, lightPane, themePicker, tokens } from "./theme";

export { iris, tokens };

/**
 * ~23 s dogfood beat map aligned with the theme Pass pilot (staged-only remake).
 * Shell default remains ~8 s for fixtures; this skin overrides duration.
 */
export const beats: BeatMap = {
  establish: { from: 0, to: 30 },
  settings: { from: 30, to: 260 },
  iris: { from: 230, to: 260 },
  payoff: { from: 230, to: 580 },
  endcard: { from: 580, to: 690 },
  duration: 690,
};

const clamp = {
  extrapolateLeft: "clamp" as const,
  extrapolateRight: "clamp" as const,
};

/** English strings from the theme pilot `demoCopy` end card and General pane. */
export const copy = {
  headline: "Theme · System / Light / Dark",
  subline: "General → Appearance and language",
  establishEyebrow: "Theme — since 0.8.0",
  disclaimer: "Applies immediately · language is separate · CarrotType",
  paneTitle: "General",
  paneSub: "Appearance, updates and launch at login",
  section: "Appearance and language",
  themeLabel: "Theme",
  themeSystem: "System",
  themeLight: "Light",
  themeDark: "Dark",
  capsuleLight: "Listening…",
  capsuleDark: "Draft ready — paste anywhere",
  holdNote: "Dark applies live · no Settings remount",
  nav: ["General", "Dictation", "Text actions", "Dynamic Island", "Setup", "Models", "Storage", "Statistics"],
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

/** Local frames inside Settings sequence (global 30 → 260). System → Light via effect click. */
const SettingsAct: FC<{ frame: number }> = ({ frame }) => {
  const light = interpolate(frame, [70, 88], [0, 1], clamp);
  const colors = light > 0.5 ? lightPane : darkPane;
  const ringOpacity = interpolate(frame, [40, 52, 100, 120], [0, 1, 1, 0], clamp);
  const press = interpolate(frame, [70, 74, 88], [0, 1, 0], clamp);
  return (
    <AbsoluteFill>
      <ThemePane
        colors={colors}
        fontFamily={tokens.fontFamily}
        paneTitle={copy.paneTitle}
        paneSub={copy.paneSub}
        section={copy.section}
        themeLabel={copy.themeLabel}
        themeValue={light > 0.5 ? copy.themeLight : copy.themeSystem}
        nav={copy.nav}
      />
      <ClickRing
        left={themePicker.left}
        top={themePicker.top}
        width={themePicker.width}
        height={themePicker.height}
        radius={themePicker.radius}
        opacity={ringOpacity}
        press={press}
        frame={frame}
        accent={tokens.accent}
      />
    </AbsoluteFill>
  );
};

/** Local frames inside Payoff (global 230 → 580). Light → Dark + capsule hold. */
const Payoff: FC<{ frame: number }> = ({ frame }) => {
  const dark = interpolate(frame, [70, 90], [0, 1], clamp);
  const colors = dark > 0.5 ? darkPane : lightPane;
  const mode = dark > 0.5 ? "dark" : "light";
  const ringOpacity = interpolate(frame, [20, 34, 70, 90], [0, 1, 1, 0], clamp);
  const press = interpolate(frame, [62, 66, 78], [0, 1, 0], clamp);
  const capsuleOpacity = interpolate(frame, [100, 120], [0, 1], clamp);
  const noteOpacity = interpolate(frame, [200, 220], [0, 1], clamp);
  return (
    <AbsoluteFill>
      <ThemePane
        colors={colors}
        fontFamily={tokens.fontFamily}
        paneTitle={copy.paneTitle}
        paneSub={copy.paneSub}
        section={copy.section}
        themeLabel={copy.themeLabel}
        themeValue={dark > 0.5 ? copy.themeDark : copy.themeLight}
        nav={copy.nav}
      />
      <ClickRing
        left={themePicker.left}
        top={themePicker.top}
        width={themePicker.width}
        height={themePicker.height}
        radius={themePicker.radius}
        opacity={ringOpacity}
        press={press}
        frame={frame}
        accent={tokens.accent}
      />
      <AbsoluteFill style={{ opacity: capsuleOpacity }}>
        <StatusCapsule
          mode={mode}
          text={dark > 0.5 ? copy.capsuleDark : copy.capsuleLight}
          fontFamily={tokens.fontFamily}
        />
      </AbsoluteFill>
      <AbsoluteFill
        style={{
          opacity: noteOpacity,
          alignItems: "center",
          justifyContent: "flex-end",
          paddingBottom: 120,
        }}
      >
        <div
          style={{
            color: tokens.labelMuted,
            fontFamily: tokens.fontFamily,
            fontSize: 18,
            letterSpacing: "0.02em",
          }}
        >
          {copy.holdNote}
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
