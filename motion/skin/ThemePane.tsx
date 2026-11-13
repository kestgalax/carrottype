import type { FC } from "react";
import type { PaneColors } from "./theme";
import { paneBox, themeRow } from "./theme";

type Props = {
  colors: PaneColors;
  fontFamily: string;
  paneTitle: string;
  paneSub: string;
  section: string;
  themeLabel: string;
  themeValue: string;
  nav: readonly string[];
};

/** Staged General pane: sidebar + Theme row. No capture clip. */
export const ThemePane: FC<Props> = ({
  colors,
  fontFamily,
  paneTitle,
  paneSub,
  section,
  themeLabel,
  themeValue,
  nav,
}) => {
  const active = nav[0];
  return (
    <div
      style={{
        position: "absolute",
        left: paneBox.left,
        top: paneBox.top,
        width: paneBox.width,
        height: paneBox.height,
        display: "flex",
        borderRadius: 16,
        overflow: "hidden",
        background: colors.window,
        color: colors.text,
        fontFamily,
        boxShadow: "0 28px 70px rgba(0, 0, 0, 0.38)",
      }}
    >
      <div
        style={{
          width: paneBox.sidebar,
          background: colors.sidebar,
          padding: "22px 14px",
          display: "flex",
          flexDirection: "column",
          gap: 2,
        }}
      >
        {nav.map((item) => (
          <div
            key={item}
            style={{
              padding: "8px 12px",
              borderRadius: 8,
              background: item === active ? colors.rowActive : "transparent",
              color: item === active ? colors.text : colors.textMuted,
              fontSize: 14,
              fontWeight: item === active ? 600 : 450,
            }}
          >
            {item}
          </div>
        ))}
      </div>
      <div style={{ position: "relative", flex: 1 }}>
        <div style={{ position: "absolute", left: 36, top: 32, fontSize: 28, fontWeight: 650, letterSpacing: "-0.02em" }}>
          {paneTitle}
        </div>
        <div style={{ position: "absolute", left: 36, top: 74, fontSize: 14, color: colors.textMuted }}>{paneSub}</div>
        <div
          style={{
            position: "absolute",
            left: 36,
            top: themeRow.top - 28,
            fontSize: 12,
            letterSpacing: "0.04em",
            textTransform: "uppercase",
            color: colors.textFaint,
            fontWeight: 650,
          }}
        >
          {section}
        </div>
        <div
          style={{
            position: "absolute",
            left: 28,
            right: 28,
            top: themeRow.top,
            height: themeRow.height,
            borderRadius: 12,
            background: colors.card,
            border: `1px solid ${colors.border}`,
          }}
        >
          <div
            style={{
              position: "absolute",
              left: 16,
              top: 0,
              height: themeRow.height,
              display: "flex",
              alignItems: "center",
              fontSize: 15,
            }}
          >
            {themeLabel}
          </div>
          <div
            style={{
              position: "absolute",
              right: 12,
              top: (themeRow.height - 30) / 2,
              width: 168,
              height: 30,
              borderRadius: 7,
              border: `1px solid ${colors.border}`,
              background: colors.window,
              display: "flex",
              alignItems: "center",
              justifyContent: "space-between",
              padding: "0 10px",
              fontSize: 14,
            }}
          >
            <span>{themeValue}</span>
            <span style={{ color: colors.textFaint, fontSize: 10 }}>⌃</span>
          </div>
        </div>
      </div>
    </div>
  );
};
