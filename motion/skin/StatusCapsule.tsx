import type { FC } from "react";

type Props = {
  mode: "light" | "dark";
  text: string;
  fontFamily: string;
};

/** Minimal capsule strip for theme payoff (not a full Island recreation). */
export const StatusCapsule: FC<Props> = ({ mode, text, fontFamily }) => {
  const light = mode === "light";
  return (
    <div
      style={{
        position: "absolute",
        left: 560,
        top: 720,
        width: 800,
        height: 56,
        borderRadius: 28,
        display: "flex",
        alignItems: "center",
        padding: "0 22px",
        background: light ? "rgba(255,255,255,0.92)" : "rgba(28,28,32,0.94)",
        color: light ? "#1B1815" : "#F2F2F3",
        fontFamily,
        fontSize: 16,
        fontWeight: 500,
        boxShadow: "0 18px 40px rgba(0,0,0,0.28)",
        letterSpacing: "-0.01em",
      }}
    >
      <span
        style={{
          width: 10,
          height: 10,
          borderRadius: 5,
          marginRight: 12,
          background: "#F0873C",
          flexShrink: 0,
        }}
      />
      <span style={{ overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>{text}</span>
    </div>
  );
};
