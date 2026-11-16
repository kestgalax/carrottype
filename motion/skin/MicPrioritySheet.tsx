import type { FC } from "react";
import { Easing, interpolate } from "remotion";
import { accentAlpha } from "motion-os/core";
import {
  copy,
  doneButton,
  rowsBefore,
  sheetBox,
  sheetColors,
  sheetRows,
} from "./micPriority";

type Props = {
  fontFamily: string;
  accent: string;
  /** Frame local to the sheet payoff beat. */
  frame: number;
};

const clamp = { extrapolateLeft: "clamp" as const, extrapolateRight: "clamp" as const };
const ease = Easing.inOut(Easing.cubic);

/** Payoff-local beat map for the sheet act. */
export const sheetTimeline = {
  enter: [0, 16],
  grab: 96,
  dragStart: 100,
  dragEnd: 180,
  drop: 184,
  badgeOut: [166, 182],
  badgeIn: [178, 192],
  doneRing: [204, 216, 236, 250],
  donePress: [220, 224, 234],
  exit: [252, 276],
} as const;

const MicGlyph: FC<{ color: string }> = ({ color }) => (
  <svg width={22} height={26} viewBox="0 0 22 26" fill="none" aria-hidden>
    <rect x="8" y="2" width="6" height="12" rx="3" stroke={color} strokeWidth="1.7" />
    <path d="M4.5 12v1.5a6.5 6.5 0 0 0 13 0V12" stroke={color} strokeWidth="1.7" strokeLinecap="round" />
    <path d="M11 20v3.5M7.5 23.5h7" stroke={color} strokeWidth="1.7" strokeLinecap="round" />
  </svg>
);

const Chevron: FC<{ direction: "up" | "down"; color: string; opacity: number }> = ({
  direction,
  color,
  opacity,
}) => (
  <svg width={22} height={22} viewBox="0 0 22 22" fill="none" style={{ opacity }} aria-hidden>
    <path
      d={direction === "up" ? "M5.5 13.5l5.5-5.5 5.5 5.5" : "M5.5 8.5l5.5 5.5 5.5-5.5"}
      stroke={color}
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
    />
  </svg>
);

const slotY = (index: number): number => sheetRows.top + index * sheetRows.height;

/** Sheet act: drag the promoted mic from slot 3 to slot 1, then Готово. */
export const MicPrioritySheet: FC<Props> = ({ fontFamily, accent, frame }) => {
  const enter = interpolate(frame, [sheetTimeline.enter[0], sheetTimeline.enter[1]], [0, 1], clamp);
  const exit = interpolate(frame, [sheetTimeline.exit[0], sheetTimeline.exit[1]], [0, 1], {
    ...clamp,
    easing: Easing.inOut(Easing.quad),
  });

  const drag = interpolate(frame, [sheetTimeline.dragStart, sheetTimeline.dragEnd], [0, 1], {
    ...clamp,
    easing: ease,
  });

  const lift = interpolate(
    frame,
    [sheetTimeline.grab, sheetTimeline.grab + 10, sheetTimeline.dragEnd, sheetTimeline.drop + 8],
    [0, 1, 1, 0],
    clamp,
  );

  const badgeOut = interpolate(frame, sheetTimeline.badgeOut, [1, 0], clamp);
  const badgeIn = interpolate(frame, sheetTimeline.badgeIn, [0, 1], clamp);

  const ringOpacity = interpolate(frame, sheetTimeline.doneRing, [0, 1, 1, 0], clamp);
  const press = interpolate(frame, sheetTimeline.donePress, [0, 1, 0], clamp);

  const rows = rowsBefore.map((row, index) => {
    let target = index;
    if (row.name === "kest Microphone") target = 0;
    if (row.name === "Elgato Wave Link Voice") target = 1;
    if (row.name === "MacBook Pro Microphone") target = 2;
    const y = slotY(index) + (slotY(target) - slotY(index)) * drag;
    const lifted = row.name === "kest Microphone";
    const promoted = row.name === "kest Microphone";
    const macDefault = row.name === "MacBook Pro Microphone";
    const status = macDefault || promoted ? copy.statusActive : row.status;
    const activeFade = promoted ? badgeIn : macDefault ? badgeOut : 1;
    return { row, y, lifted, status, activeFade };
  });

  const sheetScale = (0.975 + 0.025 * enter) * (1 - 0.035 * exit);
  const sheetOpacity = enter * (1 - exit);

  return (
    <div
      style={{
        position: "absolute",
        left: sheetBox.left,
        top: sheetBox.top - 10 * exit,
        width: sheetBox.width,
        height: sheetBox.height,
        borderRadius: sheetBox.radius,
        background: sheetColors.sheet,
        border: `1px solid ${sheetColors.sheetBorder}`,
        boxShadow: "0 40px 110px rgba(0, 0, 0, 0.62)",
        fontFamily,
        color: sheetColors.text,
        overflow: "hidden",
        opacity: sheetOpacity,
        transform: `scale(${sheetScale})`,
        transformOrigin: "50% 45%",
      }}
    >
      <div
        style={{
          position: "absolute",
          left: sheetBox.padding,
          top: 28,
          fontSize: 27,
          fontWeight: 650,
          letterSpacing: "-0.02em",
        }}
      >
        {copy.sheetTitle}
      </div>

      <div
        style={{
          position: "absolute",
          left: sheetBox.padding,
          top: 72,
          width: sheetBox.width - sheetBox.padding * 2,
          fontSize: 15.5,
          lineHeight: 1.5,
          color: sheetColors.textMuted,
        }}
      >
        {copy.sheetCaption}
      </div>

      <div
        style={{
          position: "absolute",
          left: 24,
          right: 24,
          top: 156,
          height: 1,
          background: sheetColors.border,
        }}
      />

      {rows.map(({ row, y, lifted, status, activeFade }) => {
        const active = Boolean(status);
        return (
          <div
            key={row.name}
            style={{
              position: "absolute",
              left: 12,
              right: 12,
              top: y,
              height: sheetRows.height,
              borderRadius: 10,
              background: lifted ? `rgba(46, 47, 54, ${0.97 * lift})` : "transparent",
              border: lifted ? `1px solid ${accentAlpha(accent, 0.5 * lift)}` : "1px solid transparent",
              boxShadow: lifted ? `0 20px 44px rgba(0, 0, 0, ${0.32 * lift})` : "none",
              transform: `scale(${1 + 0.014 * lift})`,
              zIndex: lifted ? 2 : 1,
              display: "flex",
              alignItems: "center",
            }}
          >
            <div style={{ position: "absolute", left: sheetRows.iconX - 12, top: 0, height: "100%", display: "flex", alignItems: "center" }}>
              <MicGlyph color={sheetColors.textMuted} />
            </div>
            <div
              style={{
                position: "absolute",
                left: sheetRows.textX - 12,
                top: 0,
                bottom: 0,
                display: "flex",
                flexDirection: "column",
                justifyContent: "center",
                gap: 4,
              }}
            >
              <div style={{ fontSize: 18, fontWeight: 450, letterSpacing: "-0.01em" }}>{row.name}</div>
              {active ? (
                <div style={{ fontSize: 14, color: sheetColors.textMuted, opacity: activeFade }}>
                  {status}
                </div>
              ) : null}
            </div>
            <div
              style={{
                position: "absolute",
                right: 22,
                top: 0,
                bottom: 0,
                display: "flex",
                alignItems: "center",
                gap: 14,
                color: accent,
                opacity: 0.55 + 0.45 * (lifted ? lift : 0),
              }}
            >
              <Chevron direction="up" color={accent} opacity={0.8} />
              <Chevron direction="down" color={accent} opacity={0.55} />
            </div>
          </div>
        );
      })}

      <div
        style={{
          position: "absolute",
          left: 24,
          right: 24,
          top: sheetBox.height - 78,
          height: 1,
          background: sheetColors.border,
        }}
      />

      <div
        style={{
          position: "absolute",
          right: doneButton.right,
          bottom: doneButton.bottom,
          width: doneButton.width,
          height: doneButton.height,
          borderRadius: 9,
          background: "#2F6BE8",
          color: "#FFFFFF",
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          fontSize: 17,
          fontWeight: 600,
          transform: `scale(${1 - 0.03 * press})`,
          boxShadow: `0 0 0 ${ringOpacity * 3}px ${accentAlpha(accent, 0.10 * ringOpacity)}`,
        }}
      >
        {copy.done}
      </div>

      {/* Effect click ring on Готово — no cursor */}
      <div
        style={{
          position: "absolute",
          right: doneButton.right - 4,
          bottom: doneButton.bottom - 4,
          width: doneButton.width + 8,
          height: doneButton.height + 8,
          borderRadius: 11,
          border: `2px solid ${accent}`,
          boxShadow: `0 0 0 1px ${accentAlpha(accent, 0.18)}, 0 0 26px ${accentAlpha(
            accent,
            0.25 + 0.3 * press,
          )}`,
          opacity: ringOpacity,
          pointerEvents: "none",
        }}
      />
    </div>
  );
};
