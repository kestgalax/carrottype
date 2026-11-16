import type { StageTokens } from "motion-os/core";

/**
 * Stage + pane tokens. Settings chrome must track shipped `AppStyle`
 * (`macos/CarrotType/Views/AppStyle.swift`) — not System Settings blue.
 */
export const appStyle = {
  /** `AppStyle.controlAccent` */
  controlAccent: "#A3471E",
  /** `AppStyle.accent(.dark)` */
  darkAccent: "#FFB589",
  /** Effect-click ring: between light/dark accents, still carrot family */
  effectAccent: "#F0873C",
} as const;

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

/** Dark Settings surface approximating `windowBackgroundColor` / grouped Form. */
export const darkPane = {
  window: "#1C1C1E",
  sidebar: "#2C2C2E",
  card: "#2C2C2E",
  text: "#F2F2F7",
  textMuted: "rgba(235, 235, 245, 0.60)",
  textFaint: "rgba(235, 235, 245, 0.30)",
  border: "rgba(84, 84, 88, 0.65)",
  rowActive: "rgba(255, 181, 137, 0.14)",
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
  accent: appStyle.effectAccent,
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
