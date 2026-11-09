# Secure Coding Checklist (OWASP Mobile Top 10)

Mapped to CarrotType (native macOS menu-bar dictation). Last pass: **2026-10-30** (`docs/superpowers/specs/2026-10-30-secure-coding-hardening-design.md`, ADR-015).

Statuses: **OK** / **Risk** / **N/A**.

| # | Category | Status | Severity |
|---|----------|--------|----------|
| 1 | Improper Platform Usage | Risk | Medium (inherent) |
| 2 | Insecure Data Storage | Risk | Low–Medium |
| 3 | Insecure Communication | Risk | Low–Medium |
| 4 | Insecure Authentication | N/A | — |
| 5 | Insufficient Cryptography | Risk | Low |
| 6 | Insecure Authorization | Risk | Low (mitigated) |
| 7 | Client Code Quality | Risk | Low–Medium |
| 8 | Code Tampering | Risk | Medium (unsigned DMG) |
| 9 | Reverse Engineering | N/A | MIT |
| 10 | Extraneous Functionality | OK | — |

---

## 1. Improper Platform Usage

- **Status:** Risk (inherent product surface)
- **Evidence:** Empty App Sandbox entitlements (`CarrotType.entitlements`); Hardened Runtime in `macos/project.yml`; mic/speech usage strings in `Info.plist`; Accessibility + HID paste (`TextInsertionService`, `SelectionTextService`); Wave Link localhost unmute (`MicMuteController`).
- **Residual:** Trusted Accessibility can inject keystrokes into any app — required for caret paste.
- **Mitigation:** Prompt AX only from Setup; mic only during session; no sandbox (product choice). ADR-007 / ADR-009 / ADR-011.

## 2. Insecure Data Storage

- **Status:** Risk
- **Evidence:** Session WAV under temp, deleted after pipeline (`AudioRecorder`, `AppState`); models under Application Support; stats opt-in aggregates only (`UsageStatsStore`, ADR-013); custom transform instructions in UserDefaults plaintext.
- **Residual:** Temp WAV race window; plaintext preferences/instructions; retain-clipboard keeps dictation text on pasteboard by design.
- **Mitigation:** Ephemeral audio; no transcript stats; retain-clipboard footer warns other apps can read pasteboard.

## 3. Insecure Communication

- **Status:** Risk
- **Evidence:** HTTPS model downloads; Whisper SHA-256; MLX `hubRevision` pins (ADR-015); Wave Link `ws://127.0.0.1`; no cloud STT.
- **Residual:** No TLS pinning; Parakeet via FluidAudio without app-level file SHA; Hub trust for unpinned tips historically.
- **Mitigation:** Closed network sinks (`.ai/constraints.md`); pins for Whisper + MLX; see `supply-chain.md`.

## 4. Insecure Authentication

- **Status:** N/A — no accounts, tokens, or remote auth for the product loop.

## 5. Insufficient Cryptography

- **Status:** Risk (Low)
- **Evidence:** CryptoKit SHA-256 for Whisper; Hub revision markers for MLX; no at-rest encryption of weights.
- **Residual:** Catalog JSON is the integrity root (bundled in the app binary).
- **Mitigation:** Pins in catalog; ADR-003 + ADR-015.

## 6. Insecure Authorization

- **Status:** Risk (Low after jail)
- **Evidence:** Helper stdin JSON; `modelDirectory` jail under Application Support `carrottype/models/` (ADR-015); custom instructions intentionally become LLM system prompt for transform.
- **Residual:** Same-UID Process IPC is not a security boundary against a fully compromised host.
- **Mitigation:** Path jail + `modelPathRejected`; helper exits after each run (ADR-009).

## 7. Client Code Quality

- **Status:** Risk
- **Evidence:** Pasteboard restore ~0.20s after paste; AX force-cast; large JSON on helper stdin bounded by UX selection size.
- **Residual:** Clipboard sniffing during restore window; no AX set-value paste rewrite.
- **Mitigation:** Shorter restore delay; prefer AX selection read before ⌘C fallback.

## 8. Code Tampering

- **Status:** Risk
- **Evidence:** Public unsigned / self-signed DMG (ADR-011); Gatekeeper Open Anyway; release script prints DMG SHA-256.
- **Residual:** No notarization until Developer ID; no runtime binary self-check.
- **Mitigation:** Prep path in `ops/deploy.md` + `macos/scripts/notarize-dmg.sh` + `ops/notarization.env.example` — do not claim notarized without evidence.

## 9. Reverse Engineering

- **Status:** N/A — MIT open source; obfuscation out of scope (ADR-011).

## 10. Extraneous Functionality

- **Status:** OK
- **Evidence:** No debug remote endpoints; Wave Link port scan is localhost-only experimental feature.
- **Residual:** Dev codesign bootstrap script is local tooling only.
- **Mitigation:** Keep experimental Wave Link clearly labeled in Settings.

---

## Related

- `docs/security/supply-chain.md`
- `.ai/constraints.md`
- ADR-003, ADR-009, ADR-011, ADR-015

## 0.5.0 updater review (ADR-017)

- One direct dependency, exact Sparkle 2.10.1 pin plus SPM binary checksum; closed sinks explicitly extended for GitHub update downloads.
- Persistent Keychain Ed25519 key; embedded public key only; signed feed without expiry and verify-before-extraction. No unsigned fallback. System profile and JavaScript disabled.
- Operation reservations cover queued start through mute restoration/processing; atomic install handoff and termination recheck. Abort unlocks future operations.
- Targeted production gate tests and isolated real Sparkle installer checks are required. Standard native UI, installed /Applications permissions, DMG/translocation and TCC retention remain manual acceptance checks; do not infer them from headless installer success.
