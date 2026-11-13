import type { StageTokens } from "motion-os/core";

/**
 * Palette sampled from the theme pilot (`lib/theme.ts`): stage stays Island-dark;
 * the Settings pane flips light/dark. Layout metrics that only served capture
 * clips stay out of this skin.
 */
export const lightPane = {
  window: "#FDFCFB",
  sidebar: "#F8F5F2",
  card: "#F1EDE9",
  text: "#1B1815",
  textMuted: "#6F6862",
  textFaint: "#9C948C",
  border: "#E4DED7",
  rowActive: "#F0E4DA",
} as const;

export const darkPane = {
  window: "#1E1F24",
  sidebar: "#1D1D1F",
  card: "#26272C",
  text: "#F2F2F3",
  textMuted: "rgba(242, 242, 243, 0.55)",
  textFaint: "rgba(242, 242, 243, 0.32)",
  border: "#32333A",
  rowActive: "#3A2C22",
} as const;

export type PaneColors = {
  window: string;
  sidebar: string;
  card: string;
  text: string;
  textMuted: string;
  textFaint: string;
  border: string;
  rowActive: string;
};

export const tokens: StageTokens = {
  bgDeep: "#08090B",
  bgMid: "#15171C",
  bgWarm: "#2A2119",
  label: "#F2F2F3",
  labelMuted: "rgba(242, 242, 243, 0.55)",
  labelFaint: "rgba(242, 242, 243, 0.32)",
  accent: "#F0873C",
  fontFamily:
    '-apple-system, BlinkMacSystemFont, "SF Pro Display", "SF Pro Text", "Helvetica Neue", Arial, sans-serif',
  orbWarm: "rgba(240, 135, 60, 0.20)",
  orbCool: "rgba(19, 26, 36, 0.55)",
  orbViolet: "rgba(180, 120, 70, 0.10)",
};

/** Stage box of the Theme value control inside `ThemePane`. */
export const paneBox = { left: 370, top: 110, width: 1180, height: 520, sidebar: 252 } as const;
export const themeRow = { top: 168, height: 58 } as const;
export const themePicker = {
  left: paneBox.left + paneBox.width - 40 - 168,
  top: paneBox.top + themeRow.top + (themeRow.height - 30) / 2,
  width: 168,
  height: 30,
  radius: 7,
} as const;

/** Stage-pixel centre of the Theme control. Shell iris opens here. */
export const iris = {
  x: themePicker.left + themePicker.width / 2,
  y: themePicker.top + themePicker.height / 2,
} as const;
