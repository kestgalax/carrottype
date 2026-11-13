# Motion OS — Design

**Date:** 2026-11-13  
**Status:** Approved (maintainer 2026-11-13); implementation plan `docs/superpowers/plans/2026-11-13-motion-os.md`  
**Related:** `docs/superpowers/specs/2026-11-13-motion-demo-agent-pilot-design.md`  
**Provenance:** CarrotType motion pilot (`artifacts/motion-pilot/`) — Island live-draft, typing-speed, theme System/Light/Dark

---

## 1. Product intent

**Motion OS** is a separate system (eventual dedicated repository) that turns a **text brief** into a **finished short product film** (seconds to ~1 minute) for changelog / What’s New / feature tours — without requiring a human to edit a timeline.

It is the motion analogue of **AIDOS**: durable intent, architecture, ADRs, agent roles, and a delivery lifecycle — specialized for **change storytelling** and **overview tours**, not for writing application code.

### What it is

- Turnkey path: brief → plan → (optional capture) → Remotion compose → checks → mp4 + report  
- Shared **production OS**: template families, effect-click language, DoD, CLI runner  
- Per-product **skin** for visual identity and product-specific scenes  
- Optional **capture adapters** (e.g. macOS Accessibility window capture) — never required for a Remotion-only Pass when the brief allows staged UI

### What it is not

- A GUI video editor or marketing finishing suite  
- A replacement for long-form brand films  
- Tied to a single product’s UI components  
- Dependent on Orca (or any external orchestrator) for the happy path  
- A publisher to GitHub/Telegram (channels are out of scope for MVP)

### Success (closed kit MVP)

- `motion init` + `motion run` produce mp4 + report **without** an external orchestrator  
- Remotion-only path always works; capture adapters are opt-in  
- At least one core template family + first consumer skin can reproduce a known Pass film  
- Automated `check`: duration ≤ 60 s, cursor/click policy, silent-by-default (audio bed optional later)  
- Public open-source positioning only after **2–3** products have dogfooded successfully

---

## 2. Decisions locked in brainstorm

| Decision | Choice |
|----------|--------|
| Product form | Full product: brief → mp4 with CLI/`init` (AIDOS-like OS), not playbook-only and not kit-without-runner |
| Capture | Remotion **core**; capture adapters **optional** (hybrid when available) |
| Distribution | Private multi-project kit first; public after 2–3 products |
| Extract timing | After **1–2 more** CarrotType films (new template families), then extract — not now |
| Repo topology | **Core package + per-consumer skins** (not monorepo-of-everything, not copy-only starter) |
| Agents | Built-in **`motion run` required**; external orchestrator (Orca/Cursor) **optional** accelerator over the same artifacts/roles |

---

## 3. Architecture

### 3.1 Repository: `motion-os` (core)

```text
motion-os/
  cli/              # init | plan | run | check
  core/             # Remotion shell, stage, ClickReveal (ring / press / iris), end card
  templates/        # family contracts: settings-toggle-payoff, sheet-result, …
  adapters/         # interfaces + reference implementations (e.g. macos-ax)
  .ai/ + docs/      # intent, architecture, ADRs, planner/developer/reviewer roles, DoD
```

### 3.2 Consumer repository (e.g. CarrotType)

```text
<product>/
  motion/
    skin/           # tokens, fonts, brand chrome, product Remotion scenes
    briefs/         # markdown briefs (input)
    adapters/       # optional app-specific capture bindings
    out/            # mp4, plan.md, report.md, review.md (local artifacts)
  motion.config.*   # core version, template family, silence/audio policy
```

### 3.3 Skin API boundary

- **Core never imports** product application UI or `macos/` (or equivalent) sources.  
- **Skin exports** scenes and tokens that satisfy a **template family contract**.  
- **Adapters** implement a narrow capture interface (window id / clip paths / metadata); `run` skips them when absent.  
- Until extract, CarrotType pilot folders under `artifacts/motion-pilot/` must label in `report.md` what would become **core** vs **skin** vs **adapter**.

### 3.4 Runtime flow (`motion run`)

```text
brief
  → plan.md
  → optional adapter capture → assets/
  → Remotion compose(template + skin [+ capture assets])
  → check (duration, no-cursor policy, audio policy)
  → out/*.mp4 + report.md
```

Pass without capture is valid when the brief selects a staged-only story.

### 3.5 Agent model

| Path | Role |
|------|------|
| **Required** | CLI runner executes plan → render → check; writes report |
| **Optional** | External orchestrator runs planner / executor / reviewer agents against the same playbook and artifact layout (multi-model review, parallel work) |

Orca is a preferred *operator* for humans who already use it — not a runtime dependency of Motion OS.

---

## 4. Template families (from pilot)

Proven in CarrotType pilot (evidence under `artifacts/motion-pilot/`):

| Family | Example | Notes |
|--------|---------|--------|
| **settings-toggle → visual payoff** | Island enable → capsule; Theme System/Light/Dark | Closest siblings; hybrid Settings capture + Remotion payoff |
| **sheet → result** | Typing speed Ready → Running → Result | Different hero surface; iris-from-control language shared |

**House rules carried into core:**

- Prefer **effect clicks** (ring + press + iris/wipe from control); **no mouse cursor** as the click language  
- Silent master by default; no noise ambient unless explicitly briefed later  
- Hybrid when capture helps truthfulness; staged Remotion for “in action” that live GUI automation cannot reliably show  

Before extract: ship **1–2 additional** CarrotType films that exercise **new** families (not clones of toggle→payoff), and document core/skin/adapter split in each report.

---

## 5. Lifecycle until extract

1. Finish theme pilot loop (review done: Pass; optional F1 version-label fix before any distribution).  
2. Short retro: Island / typing / theme → inventory → core vs skin vs adapter.  
3. Produce **1–2** more CarrotType films with **new** template families; mark boundaries in `report.md`.  
4. Draft skin API + DoD inside `artifacts/motion-pilot/` (still in-product).  
5. Create `motion-os` repo; move primitives + playbook + CLI skeleton.  
6. CarrotType becomes first consumer (`motion/` + dependency on core).  
7. Second/third product dogfood → then consider public release.

**Explicit non-goals until after MVP kit:** channel publishing, TTS/VO pipeline, cloud render, timeline GUI, baking Orca into the product.

---

## 6. Relationship to CarrotType

- CarrotType remains the **dogfood product**, not the home of Motion OS long-term.  
- Pilot artifacts stay under `artifacts/motion-pilot/` until extract; no requirement to commit them for the design to be valid.  
- Product code under `macos/` must not be edited for demo convenience (pilot rule preserved).  
- This design does **not** change CarrotType runtime architecture; it only constrains how motion work is organized and later extracted.

---

## 7. Risks and open points

| Risk | Mitigation |
|------|------------|
| Premature extract before template diversity | Gate extract on +1–2 new-family films |
| Skin API too vague → copy-paste Remotion apps | Draft contract from Island/typing/theme before extract |
| Capture adapters become accidental core dependency | Remotion-only must Pass for staged briefs; CI/check enforces adapter optional |
| External orchestrator habits leak into required path | Document `motion run` as sole required turnkey; Orca examples stay in ops/docs |
| Version / branding mismatches in films (theme F1) | `check` may later flag on-screen version vs capture metadata |

**Open (not blocking this design):** final package name (`motion-os` vs brand name); audio bed mux policy beyond silent default; exact brief front-matter schema.

---

## 8. Self-review notes

- No TBD placeholders for locked decisions; opens called out in §7.  
- Consistent with pilot design: hybrid optional, effect clicks, silent default, no product edits for demos.  
- Scope is one system (Motion OS) plus an explicit pre-extract CarrotType phase — not an implementation plan for the CLI yet.  
- Ambiguity resolved: runner is mandatory; orchestrator is optional; capture is optional; extract is deferred.
