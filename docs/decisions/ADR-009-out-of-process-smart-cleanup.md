# ADR-009: Out-of-process Smart Cleanup Helper

## Status

Accepted

## Context

ADR-005 runs Qwen3 Smart/Smart+ cleanup in-process via MLX. Even after unloading the model container and calling `Memory.clearCache()`, the host retains residual MLX/Metal heap. Over repeated Smart sessions the menu-bar app can stay far above cold-start footprint.

Product distribution (ADR-002) is GitHub Releases with Developer ID + notarization, not Mac App Store. App Sandbox is not enabled (Accessibility + mic capture).

## Decision

1. **Process boundary:** Smart/Smart+ MLX inference runs only in an embedded CLI helper: `CarrotType.app/Contents/MacOS/CarrotTypeCleanupHelper`.
2. **Lifecycle:** host spawns the helper per Smart/Smart+ cleanup request → one JSON request on stdin → one JSON response on stdout → helper exits. No keep-alive.
3. **IPC:** versioned local JSON (`v: 1`) over stdin/stdout. No network. Host maps failures/timeouts/crashes to Light fallback (existing `DictationPipeline` policy).
4. **Host dependencies:** the app target does not link MLX inference products (`MLXLLM` / `MLXLMCommon` / `MLXHuggingFace`). Hub download + package readiness stay in the host.
5. **Code shape:** MLX load/generate lives in a helper **core** module separate from the CLI `main` entrypoint, so a future transport change does not rewrite inference.
6. **Signing:** for Developer ID / notarization, both host and helper are signed (hardened runtime) and notarized as part of the `.app` bundle (`ops/deploy.md`).

## Future work (sandbox / Mac App Store)

- Current channel (ADR-002): Developer ID + notarized DMG. Embedded CLI helper is sufficient; Gatekeeper does not require XPC.
- **XPC is required only if** we later accept App Sandbox and/or Mac App Store distribution (out of MVP today because of Accessibility constraints).
- Migration then: replace `Process` + stdin/stdout with an XPC client/service. **Do not rewrite the MLX inference core** — only the transport/entrypoint.
- That change needs a **new ADR** (sandbox/MAS + transport). Do not silently rewrite IPC.

XPC alone does not guarantee a flat host: a keep-alive XPC service retains helper memory. Flat host still requires process exit (or equivalent teardown) after work.

## Consequences

- Host idle footprint after Smart sessions can return near cold start; peak ~1–2 GB appears only in the helper process and disappears on exit.
- Each Smart session pays cold model load latency (accepted tradeoff).
- Packaging must embed and (when notarizing) sign the helper binary.
- MLX Metal shaders (`mlx-swift_Cmlx.bundle`) must be copied into `Contents/Resources` (post-compile script in `macos/project.yml`). The helper’s `Bundle.main` resolves to the `.app`, so Resources are found. Do not drop a bare `.metallib` into `Contents/MacOS` — codesign treats it as unsigned code.

## Alternatives considered

- **In-process unload + `Memory.clearCache()` only (ADR-005):** reduces Metal residency but leaves MLX runtime heap in the host — insufficient for “no bloat over time.”
- **XPC keep-alive service now:** more ceremony; easy to leave the service resident; not required for non-sandbox Developer ID distribution.
- **Keep-alive helper with idle timeout:** helper RAM stays between sessions; rejected for this increment’s memory goal.
