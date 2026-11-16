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
import { appStyle } from "./theme";

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

const MicGlyph: FC<{ color: string; filled?: boolean }> = ({ color, filled }) =>
  filled ? (
    <svg width={18} height={22} viewBox="0 0 18 22" fill="none" aria-hidden>
      <rect x="5.5" y="1.5" width="7" height="11" rx="3.5" fill={color} />
      <path
        d="M2.5 10.5v1a6.5 6.5 0 0 0 13 0v-1"
        stroke={color}
        strokeWidth="1.6"
        strokeLinecap="round"
      />
      <path d="M9 17v3M5.5 20h7" stroke={color} strokeWidth="1.6" strokeLinecap="round" />
    </svg>
  ) : (
    <svg width={18} height={22} viewBox="0 0 18 22" fill="none" aria-hidden>
      <rect x="5.5" y="1.5" width="7" height="11" rx="3.5" stroke={color} strokeWidth="1.6" />
      <path
        d="M2.5 10.5v1a6.5 6.5 0 0 0 13 0v-1"
        stroke={color}
        strokeWidth="1.6"
        strokeLinecap="round"
      />
      <path d="M9 17v3M5.5 20h7" stroke={color} strokeWidth="1.6" strokeLinecap="round" />
    </svg>
  );

const CheckGlyph: FC<{ color: string }> = ({ color }) => (
  <svg width={12} height={12} viewBox="0 0 12 12" fill="none" aria-hidden>
    <circle cx="6" cy="6" r="5.1" fill={color} />
    <path
      d="M3.6 6.1l1.6 1.6 3.2-3.2"
      stroke="#1C1C1E"
      strokeWidth="1.4"
      strokeLinecap="round"
      strokeLinejoin="round"
    />
  </svg>
);

const BoltGlyph: FC<{ color: string }> = ({ color }) => (
  <svg width={12} height={12} viewBox="0 0 12 12" fill="none" aria-hidden>
    <circle cx="6" cy="6" r="5.1" stroke={color} strokeWidth="1.2" />
    <path d="M7.2 2.8L4.4 6.6h1.7L4.8 9.2 7.8 5.4H6.1L7.2 2.8z" fill={color} />
  </svg>
);

const DragGrabber: FC<{ color: string; opacity: number }> = ({ color, opacity }) => (
  <svg width={14} height={22} viewBox="0 0 14 22" fill="none" style={{ opacity }} aria-hidden>
    {[5, 11, 17].map((y) => (
      <g key={y}>
        <circle cx="4" cy={y} r="1.35" fill={color} />
        <circle cx="10" cy={y} r="1.35" fill={color} />
      </g>
    ))}
  </svg>
);

const slotY = (index: number): number => sheetRows.top + index * sheetRows.height;

/**
 * Sheet act matched to shipped `MicrophonePrioritySheet` + `AppStyle` tint
 * (carrot accent — not System Settings blue).
 */
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
    const unavailable = row.name === "Elgato Wave Link Voice";
    const showActive = promoted ? badgeIn > 0.05 : macDefault ? badgeOut > 0.05 : false;
    const activeFade = promoted ? badgeIn : macDefault ? badgeOut : 1;
    return { row, y, lifted, unavailable, showActive, activeFade, promoted };
  });

  const sheetScale = (0.975 + 0.025 * enter) * (1 - 0.035 * exit);
  const sheetOpacity = enter * (1 - exit);
  const tint = appStyle.darkAccent;

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
          right: sheetBox.padding,
          top: 20,
          height: 32,
          display: "flex",
          alignItems: "center",
          justifyContent: "space-between",
        }}
      >
        <div style={{ fontSize: 17, fontWeight: 650, letterSpacing: "-0.02em" }}>{copy.sheetTitle}</div>
        <div
          style={{
            position: "relative",
            minWidth: doneButton.width,
            height: doneButton.height,
            padding: "0 14px",
            borderRadius: 6,
            background: tint,
            color: "#1C1C1E",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            fontSize: 13,
            fontWeight: 650,
            transform: `scale(${1 - 0.03 * press})`,
            boxShadow: `0 0 0 ${ringOpacity * 3}px ${accentAlpha(accent, 0.12 * ringOpacity)}`,
          }}
        >
          {copy.done}
          <div
            style={{
              position: "absolute",
              inset: -4,
              borderRadius: 9,
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
      </div>

      <div
        style={{
          position: "absolute",
          left: sheetBox.padding,
          top: 60,
          width: sheetBox.width - sheetBox.padding * 2,
          fontSize: 12.5,
          lineHeight: 1.45,
          color: sheetColors.textMuted,
        }}
      >
        {copy.sheetCaption}
      </div>

      <div
        style={{
          position: "absolute",
          left: 0,
          right: 0,
          top: 142,
          height: 1,
          background: sheetColors.border,
        }}
      />

      <div
        style={{
          position: "absolute",
          left: 14,
          right: 14,
          top: 154,
          bottom: 16,
          borderRadius: 10,
          background: "rgba(255,255,255,0.03)",
          border: `1px solid ${sheetColors.border}`,
          overflow: "hidden",
        }}
      />

      {rows.map(({ row, y, lifted, unavailable, showActive, activeFade, promoted }, index) => {
        const isActive =
          promoted ? badgeIn > 0.5 : row.name === "MacBook Pro Microphone" && badgeOut > 0.5;
        const micColor = isActive ? tint : sheetColors.textMuted;
        return (
          <div
            key={row.name}
            style={{
              position: "absolute",
              left: 18,
              right: 18,
              top: y,
              height: sheetRows.height,
              borderRadius: 8,
              background: lifted ? `rgba(58, 58, 60, ${0.97 * lift})` : "transparent",
              border: lifted ? `1px solid ${accentAlpha(accent, 0.45 * lift)}` : "1px solid transparent",
              boxShadow: lifted ? `0 18px 40px rgba(0, 0, 0, ${0.3 * lift})` : "none",
              transform: `scale(${1 + 0.012 * lift})`,
              zIndex: lifted ? 2 : 1,
              display: "flex",
              alignItems: "center",
            }}
          >
            {index > 0 ? (
              <div
                style={{
                  position: "absolute",
                  left: 44,
                  right: 40,
                  top: 0,
                  height: 1,
                  background: sheetColors.border,
                  opacity: lifted ? 0 : 0.85,
                }}
              />
            ) : null}

            <div
              style={{
                position: "absolute",
                left: sheetRows.iconX - 10,
                top: 0,
                height: "100%",
                display: "flex",
                alignItems: "center",
              }}
            >
              <MicGlyph color={micColor} filled={isActive} />
            </div>

            <div
              style={{
                position: "absolute",
                left: sheetRows.textX - 10,
                top: 0,
                bottom: 0,
                display: "flex",
                flexDirection: "column",
                justifyContent: "center",
                gap: 3,
              }}
            >
              <div
                style={{
                  fontSize: 15,
                  fontWeight: 450,
                  letterSpacing: "-0.01em",
                  color: unavailable ? sheetColors.textMuted : sheetColors.text,
                }}
              >
                {row.name}
              </div>
              <div
                style={{
                  display: "flex",
                  alignItems: "center",
                  gap: 10,
                  fontSize: 12,
                  color: sheetColors.textMuted,
                  minHeight: 16,
                }}
              >
                {showActive ? (
                  <span
                    style={{
                      display: "inline-flex",
                      alignItems: "center",
                      gap: 5,
                      opacity: activeFade,
                    }}
                  >
                    <CheckGlyph color={tint} />
                    {copy.statusActive}
                  </span>
                ) : null}
                {unavailable ? (
                  <span style={{ display: "inline-flex", alignItems: "center", gap: 5 }}>
                    <BoltGlyph color={sheetColors.textMuted} />
                    {copy.statusUnavailable}
                  </span>
                ) : null}
              </div>
            </div>

            <div
              style={{
                position: "absolute",
                right: 16,
                top: 0,
                bottom: 0,
                display: "flex",
                alignItems: "center",
                color: sheetColors.textMuted,
              }}
            >
              <DragGrabber
                color={sheetColors.textMuted}
                opacity={0.35 + 0.55 * (lifted ? lift : 0.25)}
              />
            </div>
          </div>
        );
      })}
    </div>
  );
};
