/**
 * Optional capture binding for a future Settings take.
 * `motion run` does not import this module. Remotion-only briefs pass with capture off.
 */

export type CaptureBrief = {
  template: "settings-toggle-payoff" | "sheet-result";
  windowTitle?: string;
  steps?: string[];
};

export type CaptureClip = {
  id: string;
  path: string;
};

export async function captureThemeSettings(_brief: CaptureBrief): Promise<{ clips: CaptureClip[] }> {
  throw new Error(
    "CarrotType capture is not wired. Theme briefs render Remotion-only (capture optional or off).",
  );
}
