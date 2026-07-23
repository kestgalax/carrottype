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
4. **Lifecycle (superseded for process boundary by ADR-009):** Smart/Smart+ MLX inference runs in a session-scoped helper process that exits after each cleanup. Within the helper, load → generate → exit (optional `Memory.clearCache()` before exit is fine but exit is the host-footprint guarantee). Host does not keep an MLX model container. Leaving Smart/Smart+ no longer needs in-process unload of Qwen weights.
5. **Failure policy:** if Smart generation fails or the package is not Ready, fall back to Light heuristics so the STT result is never discarded.
6. **Catalog:** both packages are `downloadable: true`; UI offers download when Smart/Smart+ is selected before Ready. Settings copy frames Smart as optional (try Off/Light first).

## Consequences

- Smart cleanup is a real MLX inference path, not an alias of Light.
- MLX inference links into the cleanup helper binary (ADR-009); host keeps Hub download deps. First Smart download is hundreds of MB.
- Memory peak during Smart sessions is higher in the helper; host idle footprint stays near cold start because the helper exits.

## Alternatives considered

- **Cloud LLM cleanup:** rejected for product privacy intent.
- **Bundle Qwen weights in the `.app`:** rejected for release size (ADR-003).
- **llama.cpp instead of MLX:** MLX is the Apple Silicon-native path already used by the mlx-community 4-bit Qwen3 packages.
