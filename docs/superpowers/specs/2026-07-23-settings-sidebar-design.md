# Design: Settings NavigationSplitView

## Traceability

- Product Intent: `docs/product-intent.md` (Setup UI readiness transparency)
- UX base: `docs/specs/ux-setup-status.md`
- Roadmap: Settings shell polish for expansion

## Goal

Replace the single scrolling Settings `Form` with a fixed sidebar + detail layout so new settings can grow as panes without infinite scroll, while keeping Status as a compact non-pane signal.

## Decisions

| Decision | Choice |
|----------|--------|
| Navigation | `NavigationSplitView(columnVisibility: .constant(.all))` inside SwiftUI `Settings` scene |
| Sidebar collapse | Never (locked visible) |
| Window title | `carrottype` only |
| Panes | General, Setup, Models, Storage |
| Icons (SF Symbols) | General `info.square`, Setup `gear`, Models `cpu`, Storage `internaldrive` |
| Status | Compact sidebar header (Ready/Almost/Blocked + version); **Details…** when not Ready opens checklist in detail (no sidebar item) |
| Details deep-link | Missing permissions → Setup; missing STT → Models |
| First-run | Welcome Form section / overlay; Continue → Setup (or Models if permissions already OK) |
| Default pane (post first-run) | General if Ready, else Setup |
| Dependencies | None (native SwiftUI only) |

## Pane contents

- **General:** hotkey capture, retain clipboard, language
- **Setup:** microphone, input device, meter, unmute experimental, Accessibility
- **Models:** STT picker/rows + post-dictation formatting
- **Storage:** disk used + delete unused

## Out of scope

- Colored System Settings–style icon tiles
- Settings search
- Collapsible sidebar
- New preference features beyond layout
- Third-party settings packages / private API swizzling
- ADR (layout-only change)

## Implementation notes

- Do not remount Settings on language change (mic meter lifecycle).
- Keep `SettingsWindowChromeFix` and `.windowResizability(.contentMinSize)`.
- Widen default window for sidebar + detail (~700×560).
