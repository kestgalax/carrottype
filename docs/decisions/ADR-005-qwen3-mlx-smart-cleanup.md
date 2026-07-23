# ADR-005: On-device Smart Cleanup via MLX Swift (Qwen3)

## Status

Accepted

## Context

ADR-003 defined cleanup modes Off / Light / Smart / Smart+ with Qwen3 as the Smart model family. Until now Smart silently fell back to Light heuristics (ADR-004). Users need real on-device punctuation and filler cleanup without sending text to the cloud.

## Decision

1. **Runtime:** [mlx-swift-lm](https://github.com/ml-explore/mlx-swift-lm) (`MLXLLM` + `MLXLMCommon` + `MLXHuggingFace`) with Hugging Face Hub download (`swift-huggingface`) and tokenizers (`swift-transformers`).
2. **Models:**
   - Smart → `mlx-community/Qwen3-0.6B-4bit` (`cleanup.qwen3-0.6b-4bit`)
   - Smart+ → `mlx-community/Qwen3-1.7B-4bit` (`cleanup.qwen3-1.7b-4bit`)
3. **Platform:** Apple Silicon only for Smart/Smart+. Intel Macs keep Off/Light.
4. **Lifecycle:** load on first Smart session; unload after idle timeout (~90s) together with STT (AppState resource pass).
5. **Failure policy:** if Smart generation fails or the package is not Ready, fall back to Light heuristics so the STT result is never discarded.
6. **Catalog:** both packages are `downloadable: true`; UI offers download when Smart/Smart+ is selected before Ready.

## Consequences

- Smart cleanup is a real MLX inference path, not an alias of Light.
- App binary depends on MLX + Hub packages; first Smart download is hundreds of MB.
- Memory peak during Smart sessions is higher; idle footprint stays low via unload.

## Alternatives considered

- **Cloud LLM cleanup:** rejected for product privacy intent.
- **Bundle Qwen weights in the `.app`:** rejected for release size (ADR-003).
- **llama.cpp instead of MLX:** MLX is the Apple Silicon-native path already used by the mlx-community 4-bit Qwen3 packages.
