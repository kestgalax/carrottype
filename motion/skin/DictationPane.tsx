import type { CSSProperties, FC, ReactNode } from "react";
import { accentAlpha } from "motion-os/core";
import {
  copy,
  card1,
  card2,
  card3,
  cardBox,
  cardHeader,
  configureButton,
  contentBox,
  headingBox,
  windowBox,
} from "./micPriority";
import { appStyle, darkPane, tokens } from "./theme";

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

/** Shipped `CarrotMark.svg` (Assets.xcassets), template-tinted like SwiftUI. */
const CarrotMark: FC<{ color: string; height?: number }> = ({ color, height = 28 }) => (
  <svg
    width={height}
    height={height}
    viewBox="0 0 64 64"
    fill={color}
    aria-hidden
  >
    <path d="M30 18C23 18 20 13 21 9C27 9 31 12 32 16C32 10 36 6 41 7C42 12 38 17 34 19Z" />
    <path d="M27 20H37C41 20 43 23 42 27L36 43C35 47 29 47 28 43L22 27C21 23 23 20 27 20Z" />
    <path d="M15 33C15 45.621008 21.456618 53 32 53C42.543382 53 49 45.621008 49 33C49 31.895431 48.104569 31 47 31C45.895431 31 45 31.895431 45 33C45 43.521849 40.206618 49 32 49C23.793382 49 19 43.521849 19 33C19 31.895431 18.104569 31 17 31C15.895431 31 15 31.895431 15 33ZM30 51L30 58C30 59.104569 30.895431 60 32 60C33.104569 60 34 59.104569 34 58L34 51C34 49.895431 33.104569 49 32 49C30.895431 49 30 49.895431 30 51ZM26 60L38 60C39.104569 60 40 59.104569 40 58C40 56.895431 39.104569 56 38 56L26 56C24.895431 56 24 56.895431 24 58C24 59.104569 24.895431 60 26 60Z" />
  </svg>
);

const NavGlyph: FC<{ kind: string; color: string }> = ({ kind, color }) => {
  const common = { width: 16, height: 16, viewBox: "0 0 16 16", fill: "none" as const };
  switch (kind) {
    case "mic":
      return (
        <svg {...common} aria-hidden>
          <rect x="6" y="1.5" width="4" height="7.5" rx="2" stroke={color} strokeWidth="1.4" />
          <path d="M3.5 7.5v.8a4.5 4.5 0 0 0 9 0v-.8" stroke={color} strokeWidth="1.4" strokeLinecap="round" />
          <path d="M8 12.2v2M5.5 14.2h5" stroke={color} strokeWidth="1.4" strokeLinecap="round" />
        </svg>
      );
    case "gear":
      return (
        <svg {...common} aria-hidden>
          <circle cx="8" cy="8" r="2.2" stroke={color} strokeWidth="1.4" />
          <path
            d="M8 1.8l.9 1.6 1.8-.2.9 1.6-1.1 1.4.6 1.7-1.7.7L8.6 11l-1.2-.1L6.5 11l-.8-1.5-1.7-.7.6-1.7L3.5 5l.9-1.6 1.8.2L8 1.8z"
            stroke={color}
            strokeWidth="1.2"
            strokeLinejoin="round"
          />
        </svg>
      );
    case "cpu":
      return (
        <svg {...common} aria-hidden>
          <rect x="4" y="4" width="8" height="8" rx="1.5" stroke={color} strokeWidth="1.4" />
          <path d="M6 2.5v1.5M10 2.5v1.5M6 12v1.5M10 12v1.5M2.5 6H4M2.5 10H4M12 6h1.5M12 10h1.5" stroke={color} strokeWidth="1.4" strokeLinecap="round" />
        </svg>
      );
    case "capsule":
      return (
        <svg {...common} aria-hidden>
          <rect x="2" y="5.5" width="12" height="5" rx="2.5" stroke={color} strokeWidth="1.4" />
        </svg>
      );
    case "drive":
      return (
        <svg {...common} aria-hidden>
          <rect x="2.5" y="3.5" width="11" height="9" rx="1.5" stroke={color} strokeWidth="1.4" />
          <circle cx="5.5" cy="10.5" r="0.9" fill={color} />
        </svg>
      );
    case "chart":
      return (
        <svg {...common} aria-hidden>
          <path d="M3 12.5V7.5M7 12.5V4.5M11 12.5V9" stroke={color} strokeWidth="1.6" strokeLinecap="round" />
        </svg>
      );
    case "text":
      return (
        <svg {...common} aria-hidden>
          <path d="M3.5 3.5h9M8 3.5v9M5.5 12.5h5" stroke={color} strokeWidth="1.4" strokeLinecap="round" />
        </svg>
      );
    default:
      return (
        <svg {...common} aria-hidden>
          <rect x="3" y="3" width="10" height="10" rx="1.5" stroke={color} strokeWidth="1.4" />
          <path d="M5.5 8h5M8 5.5v5" stroke={color} strokeWidth="1.4" strokeLinecap="round" />
        </svg>
      );
  }
};

const Toggle: FC<{ on: boolean }> = ({ on }) => (
  <div
    style={{
      width: 42,
      height: 24,
      borderRadius: 12,
      background: on ? appStyle.darkAccent : "rgba(120,120,128,0.32)",
      position: "relative",
      flexShrink: 0,
    }}
  >
    <span
      style={{
        position: "absolute",
        top: 2,
        left: on ? 20 : 2,
        width: 20,
        height: 20,
        borderRadius: 10,
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
      borderRadius: 10,
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
      left: 18,
      top: 0,
      height: cardHeader,
      display: "flex",
      alignItems: "center",
      fontSize: 13,
      fontWeight: 600,
      color: darkPane.textMuted,
      letterSpacing: "-0.01em",
      textTransform: "uppercase" as const,
    }}
  >
    {children}
  </div>
);

const Divider: FC<{ top: number }> = ({ top }) => (
  <div
    style={{
      position: "absolute",
      left: 18,
      right: 18,
      top,
      height: 1,
      background: darkPane.border,
      opacity: 0.85,
    }}
  />
);

/** Staged Settings → Dictation from shipped SwiftUI chrome (`AppStyle` tint). */
export const DictationPane: FC<Props> = ({
  fontFamily,
  activeMic,
  dim = 0,
  highlight = 0,
  ringOpacity = 0,
  press = 0,
  frame,
}) => {
  const buttonLeft = cardBox.width - 16 - configureButton.width;
  const buttonTop = card2.top + cardHeader + (card2.height - cardHeader - configureButton.height) / 2;
  const glow = accentAlpha(appStyle.effectAccent, 0.14 + 0.32 * highlight);
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
        <div
          style={{
            position: "absolute",
            left: 0,
            top: 0,
            right: 0,
            height: windowBox.titlebar,
            background: darkPane.sidebar,
            borderBottom: `1px solid ${darkPane.border}`,
            display: "flex",
            alignItems: "center",
            padding: "0 18px",
          }}
        >
          <TrafficLights />
          <div
            style={{
              position: "absolute",
              left: 0,
              right: 0,
              textAlign: "center",
              fontSize: 13,
              fontWeight: 600,
              color: darkPane.textMuted,
              pointerEvents: "none",
            }}
          >
            {copy.brand}
          </div>
        </div>

        {/* Sidebar — CarrotMark + SF-style rows + warm selection */}
        <div
          style={{
            position: "absolute",
            left: 0,
            top: windowBox.titlebar,
            width: windowBox.sidebar,
            bottom: 0,
            background: "rgba(44,44,46,0.55)",
            borderRight: `1px solid ${darkPane.border}`,
            display: "flex",
            flexDirection: "column",
            padding: "18px 10px 16px",
          }}
        >
          <div
            style={{
              display: "flex",
              alignItems: "center",
              gap: 10,
              padding: "4px 10px 18px",
            }}
          >
            <CarrotMark color={appStyle.darkAccent} height={26} />
            <span style={{ fontSize: 16, fontWeight: 650, letterSpacing: "-0.02em" }}>{copy.brand}</span>
          </div>

          <div style={{ display: "flex", flexDirection: "column", gap: 2, flex: 1 }}>
            {copy.nav.map((item, index) => {
              const active = index === 1;
              return (
                <div
                  key={item.title}
                  style={{
                    display: "flex",
                    alignItems: "center",
                    gap: 10,
                    padding: "7px 10px",
                    borderRadius: 6,
                    fontSize: 14,
                    fontWeight: active ? 600 : 450,
                    color: darkPane.text,
                    background: active ? darkPane.rowActive : "transparent",
                  }}
                >
                  <NavGlyph kind={item.symbol} color={active ? appStyle.darkAccent : darkPane.textMuted} />
                  <span style={{ lineHeight: 1.2 }}>{item.title}</span>
                </div>
              );
            })}
          </div>

          <div
            style={{
              marginTop: 8,
              padding: "10px 12px",
              borderRadius: 8,
              background: "rgba(255,255,255,0.04)",
              border: `1px solid ${darkPane.border}`,
              fontSize: 12,
              color: darkPane.textMuted,
            }}
          >
            <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 6 }}>
              <span style={{ color: darkPane.text, fontWeight: 600 }}>{copy.statusReady}</span>
              <span style={{ color: appStyle.darkAccent }}>●</span>
            </div>
            <div
              style={{
                marginTop: 8,
                fontSize: 12,
                fontWeight: 500,
                color: darkPane.text,
                textAlign: "center",
                padding: "5px 0",
                borderRadius: 6,
                background: "rgba(255,255,255,0.06)",
              }}
            >
              {copy.whatsNew}
            </div>
          </div>
        </div>

        {/* Detail pane */}
        <div style={{ position: "absolute", ...contentBox, left: contentBox.left }}>
          <div
            style={{
              position: "absolute",
              left: cardBox.left,
              top: headingBox.top,
              width: cardBox.width,
            }}
          >
            <div
              style={{
                fontSize: 26,
                fontWeight: 650,
                letterSpacing: "-0.02em",
                color: darkPane.text,
              }}
            >
              {copy.paneTitle}
            </div>
            <div
              style={{
                marginTop: 4,
                fontSize: 14,
                color: darkPane.textMuted,
                lineHeight: 1.35,
              }}
            >
              {copy.paneSubtitle}
            </div>
          </div>

          {/* Hotkey / dictation section */}
          <Card top={card1.top} height={card1.height}>
            <CardTitle>{copy.sectionHotkey}</CardTitle>
            <Divider top={cardHeader} />
            <div
              style={{
                position: "absolute",
                left: 18,
                right: 18,
                top: cardHeader + 8,
                display: "flex",
                alignItems: "center",
                justifyContent: "space-between",
                fontSize: 15,
              }}
            >
              <span>{copy.comboLabel}</span>
              <div
                style={{
                  height: 26,
                  padding: "0 10px",
                  borderRadius: 6,
                  background: "rgba(255,255,255,0.08)",
                  border: `1px solid ${darkPane.border}`,
                  display: "flex",
                  alignItems: "center",
                  fontSize: 13,
                  letterSpacing: "0.06em",
                }}
              >
                {copy.comboValue}
              </div>
            </div>
            <Divider top={cardHeader + 52} />
            <div
              style={{
                position: "absolute",
                left: 18,
                right: 18,
                top: cardHeader + 60,
                display: "flex",
                gap: 16,
                alignItems: "flex-start",
              }}
            >
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 15 }}>{copy.pushToTalk}</div>
                <div style={{ marginTop: 4, fontSize: 12, color: darkPane.textMuted, lineHeight: 1.35 }}>
                  {copy.pushToTalkHint}
                </div>
              </div>
              <Toggle on />
            </div>
          </Card>

          {/* Compact microphone priority */}
          <Card top={card2.top} height={card2.height}>
            <CardTitle>{copy.sectionPriority}</CardTitle>
            <Divider top={cardHeader} />
            <div
              style={{
                position: "absolute",
                left: 18,
                right: 18,
                top: cardHeader,
                bottom: 0,
                display: "flex",
                alignItems: "center",
                justifyContent: "space-between",
                gap: 12,
              }}
            >
              <span style={{ fontSize: 15 }}>{copy.activeLabel}</span>
              <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
                <span
                  style={{
                    fontSize: 14,
                    fontWeight: 500,
                    color: highlight > 0 ? darkPane.text : darkPane.textMuted,
                    maxWidth: 260,
                    overflow: "hidden",
                    textOverflow: "ellipsis",
                    whiteSpace: "nowrap",
                  }}
                >
                  {activeMic}
                </span>
                <div
                  style={{
                    width: configureButton.width,
                    height: configureButton.height,
                    borderRadius: 6,
                    background: "rgba(255,255,255,0.07)",
                    border: `1px solid ${darkPane.border}`,
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "center",
                    fontSize: 13,
                    fontWeight: 500,
                    transform: `scale(${1 - 0.02 * press})`,
                  }}
                >
                  {copy.configure}
                </div>
              </div>
            </div>
            <div
              style={{
                position: "absolute",
                right: 16 + configureButton.width + 10,
                bottom: 14,
                width: Math.min(220, 40 + activeMic.length * 7),
                height: 2,
                borderRadius: 2,
                background: appStyle.effectAccent,
                opacity: 0.75 * highlight,
                boxShadow: `0 0 16px ${glow}`,
              }}
            />
          </Card>

          {/* Formatting peek — keeps Form rhythm without stealing the hero */}
          <Card top={card3.top} height={card3.height}>
            <CardTitle>{copy.sectionFormatting}</CardTitle>
            <Divider top={cardHeader} />
            <div
              style={{
                position: "absolute",
                left: 18,
                right: 18,
                top: cardHeader + 14,
                display: "flex",
                alignItems: "center",
                justifyContent: "space-between",
                fontSize: 15,
              }}
            >
              <span>{copy.formatMode}</span>
              <span style={{ color: darkPane.textMuted }}>{copy.formatModeValue}</span>
            </div>
            <Divider top={cardHeader + 56} />
            <div
              style={{
                position: "absolute",
                left: 18,
                top: cardHeader + 72,
                fontSize: 14,
                color: appStyle.darkAccent,
                fontWeight: 500,
              }}
            >
              {copy.openModels}
            </div>
            <div
              style={{
                position: "absolute",
                left: 18,
                right: 18,
                top: cardHeader + 110,
                fontSize: 12,
                color: darkPane.textFaint,
              }}
            >
              {copy.retainClipboard}
            </div>
          </Card>

          {/* Effect click ring on «Настроить…» — carrot family, not system blue */}
          <div
            style={{
              position: "absolute",
              left: cardBox.left + buttonLeft,
              top: buttonTop,
              width: configureButton.width,
              height: configureButton.height,
              borderRadius: 6,
              border: `2px solid ${appStyle.effectAccent}`,
              boxShadow: `0 0 0 1px ${accentAlpha(appStyle.effectAccent, 0.18)}, 0 0 26px ${accentAlpha(
                appStyle.effectAccent,
                0.22 + 0.25 * press,
              )}`,
              background: accentAlpha(appStyle.effectAccent, 0.05 + 0.12 * press),
              opacity: ringOpacity,
              transform: `scale(${pulse})`,
              pointerEvents: "none",
            }}
          />
        </div>
      </div>

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
