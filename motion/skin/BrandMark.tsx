import type { FC } from "react";

type Props = {
  accent: string;
  label: string;
  size?: number;
};

/** Wordmark from the theme pilot `BrandMark` (dot + carrottype). */
export const BrandMark: FC<Props> = ({ accent, label, size = 30 }) => {
  return (
    <div
      style={{
        display: "flex",
        alignItems: "center",
        gap: size * 0.42,
      }}
    >
      <div
        style={{
          width: size * 0.34,
          height: size * 0.34,
          borderRadius: "50%",
          background: accent,
          boxShadow: `0 0 ${size * 0.5}px rgba(240, 135, 60, 0.45)`,
        }}
      />
      <span
        style={{
          fontSize: size,
          fontWeight: 500,
          letterSpacing: "-0.01em",
          color: label,
          lineHeight: 1,
        }}
      >
        carrottype
      </span>
    </div>
  );
};
