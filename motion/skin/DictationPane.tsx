import type { CSSProperties, FC, ReactNode } from "react";
import { accentAlpha } from "motion-os/core";
import { copy, card1, card2, card3, cardBox, cardHeader, configureButton, contentBox, windowBox } from "./micPriority";
import { darkPane, tokens } from "./theme";

type Props = {
  fontFamily: string;
  activeMic: string;
  /** 0 → crisp window, 1 → fully dimmed behind the sheet. */
  dim?: number;
  /** 0→1 accent glow on the active microphone value (after the sheet closes). */
  highlight?: number;
  /** Configure button ring opacity (0 hides it). */
  ringOpacity?: number;
  /** 0→1 press amount for the Configure button. */
  press?: number;
  frame: number;
};

const TrafficLights: FC = () => (
  <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
    {["#FF5F57", "#FEBC2E", "#28C840"].map((color) => (
      <span
        key={color}
        style={{ width: 12, height: 12, borderRadius: 6, background: color, display: "block" }}
      />
    ))}
  </div>
);

const Toggle: FC<{ on: boolean }> = ({ on }) => (
  <div
    style={{
      width: 58,
      height: 32,
      borderRadius: 16,
      background: on ? "#0A84FF" : "rgba(255,255,255,0.16)",
      position: "relative",
      transition: "none",
    }}
  >
    <span
      style={{
        position: "absolute",
        top: 3,
        left: on ? 29 : 3,
        width: 26,
        height: 26,
        borderRadius: 13,
        background: "#FFFFFF",
        boxShadow: "0 1px 2px rgba(0,0,0,0.35)",
      }}
    />
  </div>
);

const Card: FC<{ top: number; height: number; children: ReactNode }> = ({ top, height, children }) => (
  <div
    style={{
      position: "absolute",
      left: cardBox.left,
      top,
      width: cardBox.width,
      height,
      borderRadius: 12,
      background: darkPane.card,
      border: `1px solid ${darkPane.border}`,
      overflow: "hidden",
    }}
  >
    {children}
  </div>
);

const CardTitle: FC<{ children: ReactNode }> = ({ children }) => (
  <div
    style={{
      position: "absolute",
      left: 22,
      top: 0,
      height: cardHeader,
      display: "flex",
      alignItems: "center",
      fontSize: 18,
      fontWeight: 600,
      color: darkPane.text,
      letterSpacing: "-0.01em",
    }}
  >
    {children}
  </div>
);

const Divider: FC<{ top: number }> = ({ top }) => (
  <div
    style={{
      position: "absolute",
      left: 22,
      right: 22,
      top,
      height: 1,
      background: darkPane.border,
      opacity: 0.7,
    }}
  />
);

const RowLabel: FC<{ top: number; children: ReactNode }> = ({ top, children }) => (
  <div
    style={{
      position: "absolute",
      left: 22,
      top,
      height: 56,
      display: "flex",
      alignItems: "center",
      fontSize: 17,
      color: darkPane.text,
    }}
  >
    {children}
  </div>
);

/** Staged Settings → Dictation pane from the approved mockup A. No capture clip. */
export const DictationPane: FC<Props> = ({
  fontFamily,
  activeMic,
  dim = 0,
  highlight = 0,
  ringOpacity = 0,
  press = 0,
  frame,
}) => {
  const buttonLeft = cardBox.width - 20 - configureButton.width;
  const buttonTop = card2.top + cardHeader + (card2.height - cardHeader - configureButton.height) / 2;
  const glow = accentAlpha(tokens.accent, 0.14 + 0.32 * highlight);
  const pulse = 1 + 0.006 * Math.sin(frame / 6);

  const shadow = [
    "0 34px 80px rgba(0, 0, 0, 0.45)",
    dim > 0 ? `inset 0 0 0 1px rgba(255,255,255,${0.05 * (1 - dim)})` : undefined,
  ]
    .filter(Boolean)
    .join(", ");

  const windowStyle: CSSProperties = {
    position: "absolute",
    left: windowBox.left,
    top: windowBox.top,
    width: windowBox.width,
    height: windowBox.height,
    borderRadius: windowBox.radius,
    overflow: "hidden",
    background: darkPane.window,
    border: `1px solid ${darkPane.border}`,
    boxShadow: shadow,
    fontFamily,
    color: darkPane.text,
  };

  return (
    <div style={{ position: "absolute", inset: 0 }}>
      <div style={windowStyle}>
        {/* Title bar */}
        <div
          style={{
            position: "absolute",
            left: 0,
            top: 0,
            right: 0,
            height: windowBox.titlebar,
            background: "#24252B",
            borderBottom: `1px solid ${darkPane.border}`,
            display: "flex",
            alignItems: "center",
            padding: "0 20px",
          }}
        >
          <TrafficLights />
          <div
            style={{
              position: "absolute",
              left: 0,
              right: 0,
              textAlign: "center",
              fontSize: 15,
              fontWeight: 600,
              color: darkPane.textMuted,
              pointerEvents: "none",
            }}
          >
            CarrotType
          </div>
        </div>

        {/* Sidebar */}
        <div
          style={{
            position: "absolute",
            left: 0,
            top: windowBox.titlebar,
            width: windowBox.sidebar,
            bottom: 0,
            background: darkPane.sidebar,
            padding: "24px 16px",
            display: "flex",
            flexDirection: "column",
            gap: 4,
          }}
        >
          {copy.nav.map((item, index) => {
            const active = index === 1;
            return (
              <div
                key={item}
                style={{
                  padding: "9px 14px",
                  borderRadius: 8,
                  fontSize: 17,
                  fontWeight: active ? 600 : 450,
                  color: active ? "#FFFFFF" : darkPane.textMuted,
                  background: active ? "#2F6BE8" : "transparent",
                }}
              >
                {item}
              </div>
            );
          })}
        </div>

        {/* Content */}
        <div style={{ position: "absolute", ...contentBox, left: contentBox.left }}>
          <div
            style={{
              position: "absolute",
              left: cardBox.left,
              top: 28,
              fontSize: 34,
              fontWeight: 650,
              letterSpacing: "-0.02em",
              color: darkPane.text,
            }}
          >
            {copy.paneTitle}
          </div>

          {/* Hotkey card */}
          <Card top={card1.top} height={card1.height}>
            <CardTitle>{copy.sectionHotkey}</CardTitle>
            <Divider top={cardHeader} />
            <RowLabel top={cardHeader}>{copy.comboLabel}</RowLabel>
            <div
              style={{
                position: "absolute",
                right: 20,
                top: cardHeader + (56 - 32) / 2,
                height: 32,
                padding: "0 14px",
                borderRadius: 8,
                background: "rgba(255,255,255,0.08)",
                border: `1px solid ${darkPane.border}`,
                display: "flex",
                alignItems: "center",
                fontSize: 16,
                letterSpacing: "0.08em",
                color: darkPane.text,
              }}
            >
              {copy.comboValue}
            </div>
            <Divider top={cardHeader + 56} />
            <RowLabel top={cardHeader + 56}>{copy.pushToTalk}</RowLabel>
            <div
              style={{
                position: "absolute",
                right: 20,
                top: cardHeader + 56 + 12,
              }}
            >
              <Toggle on />
            </div>
          </Card>

          {/* Compact microphone priority card */}
          <Card top={card2.top} height={card2.height}>
            <CardTitle>{copy.sectionPriority}</CardTitle>
            <Divider top={cardHeader} />
            <RowLabel top={cardHeader}>{copy.activeLabel}</RowLabel>
            <div
              style={{
                position: "absolute",
                left: 276,
                top: cardHeader,
                height: card2.height - cardHeader,
                display: "flex",
                alignItems: "center",
                fontSize: 17,
                fontWeight: 500,
                color: highlight > 0 ? darkPane.text : darkPane.textMuted,
              }}
            >
              {activeMic}
            </div>
            <div
              style={{
                position: "absolute",
                left: 276,
                top: cardHeader + (card2.height - cardHeader) / 2 + 18,
                width: 200,
                height: 2,
                borderRadius: 2,
                background: tokens.accent,
                opacity: 0.75 * highlight,
                boxShadow: `0 0 16px ${glow}`,
              }}
            />
            <div
              style={{
                position: "absolute",
                left: buttonLeft,
                top: buttonTop - card2.top,
                width: configureButton.width,
                height: configureButton.height,
                borderRadius: 8,
                background: "rgba(255,255,255,0.07)",
                border: `1px solid ${darkPane.border}`,
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                fontSize: 16,
                fontWeight: 500,
                color: darkPane.text,
                transform: `scale(${1 - 0.02 * press})`,
              }}
            >
              {copy.configure}
            </div>
          </Card>

          {/* Formatting card — keeps the form rhythm below the compact row */}
          <Card top={card3.top} height={card3.height}>
            <CardTitle>{copy.sectionFormatting}</CardTitle>
            <Divider top={cardHeader} />
            <RowLabel top={cardHeader}>{copy.autocorrect}</RowLabel>
            <div style={{ position: "absolute", right: 20, top: cardHeader + 12 }}>
              <Toggle on={false} />
            </div>
            <Divider top={cardHeader + 56} />
            <RowLabel top={cardHeader + 56}>Умные кавычки</RowLabel>
            <div style={{ position: "absolute", right: 20, top: cardHeader + 68 }}>
              <Toggle on />
            </div>
          </Card>

          {/* Effect click language: ring on «Настроить…» only */}
          <div
            style={{
              position: "absolute",
              left: cardBox.left + buttonLeft,
              top: buttonTop,
              width: configureButton.width,
              height: configureButton.height,
              borderRadius: 8,
              border: `2px solid ${tokens.accent}`,
              boxShadow: `0 0 0 1px ${accentAlpha(tokens.accent, 0.18)}, 0 0 26px ${accentAlpha(
                tokens.accent,
                0.22 + 0.25 * press,
              )}`,
              background: accentAlpha(tokens.accent, 0.05 + 0.12 * press),
              opacity: ringOpacity,
              transform: `scale(${pulse})`,
              pointerEvents: "none",
            }}
          />
        </div>
      </div>

      {/* Sheet backdrop dim */}
      {dim > 0 ? (
        <div
          style={{
            position: "absolute",
            left: windowBox.left,
            top: windowBox.top,
            width: windowBox.width,
            height: windowBox.height,
            borderRadius: windowBox.radius,
            background: `rgba(0, 0, 0, ${0.62 * dim})`,
          }}
        />
      ) : null}
    </div>
  );
};
