# Motion demo agent pilot (feasibility)

Date: 2026-11-13  
Status: **Local experiment only — do not commit or push until pilot Pass**  
Owner: maintainer + coordinator (this chat)  
Related product: CarrotType (communication of changes, not product features)

## Goal

Validate the hypothesis that an agent pipeline can, from a textual change description plus access to a Debug CarrotType build, produce a **finished** short motion demo **without manual editing**.

If the hypothesis fails, distribution channels (GitHub, Telegram) do not matter yet. If it passes, maintainer may later decide whether to bake motion demos into the release process — that decision is **out of scope** for this pilot and requires a separate design/ADR.

## Success criteria (Pass)

- One playable local file (mp4 or webm), duration ≤ 60 seconds (target 20–40 s).
- Content matches the pilot brief (Full Dynamic Island + live draft, **no speech**).
- Viewer can understand what changed / how it looks.
- No human remounting, trimming, or title fixes after the agents finish.
- Reviewer stage returns Pass against the Cursor plan and § Success criteria.

## Fail / Partial

| Outcome | Meaning |
|--------|---------|
| **Fail** | No usable video; environment blocker (e.g. Screen Recording denied); silent pivot to synthetic Remotion as primary path; or “needs a human hand” to finish. |
| **Partial** | Video exists and real UI was captured, but review finds material gaps (unclear brief, broken flow, bad titles) — hypothesis “turnkey” not yet true. |

Environment failures (missing Screen Recording permission, etc.) are recorded as **environment Fail**, not as “model stupidity”.

## Non-goals (this pilot)

- Telegram bot, website, public “feature story” feed
- Publishing to GitHub Releases
- Changing CarrotType product code for demo convenience
- Committing or pushing pilot artifacts, plans, or this spec until Pass + explicit maintainer OK
- Synthetic/Remotion-first demos (allowed only after explicit maintainer agreement following a capture Fail)
- Voiceover, TTS, microphone, or spoken dictation in the pilot clip
- Updating `docs/roadmap.md` / AIDOS process as part of the experiment

## Approach

**Approach 1 (chosen):** real UI screen capture + GUI-driven agent, then light FFmpeg trim/titles.

Not chosen for the pilot primary path:

- Debug demo-scripts inside the app (weaker “from text alone” hypothesis)
- Remotion/synthetic recreation of Island UI (exception-only later)

## Pilot brief

**Source of truth:** existing Dynamic Island + live draft product docs/notes (Full capsule; live draft only in full capsule). No invented features.

**On-screen story (no speech):**

1. Open Settings → Dynamic Island (or equivalent path to Full + live draft controls).
2. Show **Full** mode and where **live draft** is enabled / visible in settings and/or calm capsule chrome **without** mic or spoken audio.
3. End on one clear “result frame” (Full + live draft available / status visible).

**Out of brief:** Minimal and Menu-bar-only modes (enough signal from Full + live draft alone to judge process fit).

**Titles:** minimal on-screen labels (feature name / one short phrase). No voiceover.

**UI language:** whichever locale is stable on the Debug build; Russian titles allowed.

## Agent pipeline (Orca orchestration)

Three sequential supervised workers in one Run. Coordinator does not improvise a substitute plan for OpenCode and does not skip review.

| Stage | Agent | Model | Role |
|-------|--------|--------|------|
| 1. Plan | `cursor` | Cursor default (stronger planner) | Full plan + design of the run: UI steps, capture method, FFmpeg steps, pass/fail checks, TCC/window risks. Deliverable: self-contained plan/spec. |
| 2. Execute | `opencode` | `opencode/deepseek-v4.1-flash` | Execute the plan only: launch Debug → GUI → screen capture → trim/titles → one video + `report.md`. |
| 3. Review | `opencode` | Prefer `zai/glm-5.3`; on billing/auth failure fallback `Naomi/glm-5.3` or `opencode-go/glm-5.3` | Independent review vs Cursor plan + Pass criteria. Output `review.md` with Pass/Partial/Fail and blockers. Does **not** remount; fixes only if maintainer starts a new round. |

**Orchestration rules:**

- Start workers with `orca orchestration worker-start` (`--agent cursor` then `--agent opencode`).
- Execute depends on Plan (`--deps`); Review depends on Execute.
- OpenCode execute and review **must** use different models.
- If Zai fails to start, record the error and use the GLM fallback without waiting on billing.

**Executor input must include:** pilot brief, how to build/run Debug, artifact paths, Pass/Fail rules, and hard bans (no publish, no product-code changes for demo, no silent synthetic primary path).

## Environment

- Same Mac as the coordinator; Debug CarrotType build from this repo (build/launch if not running).
- Pilot needs screen capture permission for real UI; mic not required.
- Workers must not quietly switch to synthetic video if capture is blocked.

## Artifacts (local only)

Suggested directory (untracked until maintainer allows commit after Pass):

`artifacts/motion-pilot/2026-11-13-island-livedraft/`

- `*.mp4` or `*.webm` — final demo
- `plan.md` (or path named by Cursor planner)
- `report.md` — executor evidence (commands, failures)
- `review.md` — reviewer verdict

Do **not** commit or push these (or this design file) until pilot Pass and explicit maintainer approval.

## Verdict → process decision

| Verdict | Follow-up |
|--------|-----------|
| **Pass** | Maintainer may later design optional motion-as-release-step (channels, bot, GitHub). Separate design/ADR. Still no auto-commit of this pilot. |
| **Partial** | Fix pipeline/prompts/plan; retry. Do not design Telegram/GitHub yet. |
| **Fail** | Document blocker. Do not embed into development process. Channels stay parked. |

Embedding motion into CarrotType development workflow is a **maintainer decision after Pass**, not an automatic outcome of the experiment.

## Traceability

- Product intent: communication of shipped changes (orthogonal to caret-paste loop).
- Pilot feature slice: Dynamic Island Full + live draft (ADR-014 / v0.9.0 Island settings context).
- Stack note (future, not required for Pass): Remotion/HyperFrames/etc. remain optional post tools; primary bet is real-app capture.
