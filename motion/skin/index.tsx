import type { FC } from "react";
import { AbsoluteFill, interpolate } from "remotion";
import { ClickRing, EndCard } from "motion-os/core";
import type { SettingsTogglePayoffScenes } from "motion-os/templates/settings-toggle-payoff";
import { BrandMark } from "./BrandMark";
import { ThemePane } from "./ThemePane";
import { darkPane, iris, lightPane, themePicker, tokens } from "./theme";

export { iris, tokens };

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

const SettingsAct: FC<{ frame: number }> = ({ frame }) => {
  const light = interpolate(frame, [34, 48], [0, 1], clamp);
  const colors = light > 0.5 ? lightPane : darkPane;
  const ringOpacity = interpolate(frame, [16, 26, 78, 96], [0, 1, 1, 0], clamp);
  const press = interpolate(frame, [36, 38, 48], [0, 1, 0], clamp);
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

const Payoff: FC<{ frame: number }> = ({ frame }) => {
  const opacity = interpolate(frame, [8, 20], [0, 1], clamp);
  return (
    <AbsoluteFill style={{ opacity }}>
      <ThemePane
        colors={lightPane}
        fontFamily={tokens.fontFamily}
        paneTitle={copy.paneTitle}
        paneSub={copy.paneSub}
        section={copy.section}
        themeLabel={copy.themeLabel}
        themeValue={copy.themeLight}
        nav={copy.nav}
      />
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
