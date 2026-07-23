# CarrotType

Локальная macOS-диктовка: **hotkey → запись → on-device STT → вставка у курсора**.

Проект ведётся через AIDOS (sibling `../AIDOS`).

## Start Here

1. `docs/product-intent.md`
2. `docs/architecture.md`
3. `docs/decisions/` (особенно ADR-002 … ADR-006)
4. `docs/specs/ux-setup-status.md`
5. `macos/README.md` — приложение
6. `ops/deploy.md` — сборка `.dmg` и GitHub Release

## Status

**v0.1.0** опубликован как unsigned DMG (GitHub Releases). Дальше: заполнить `docs/stt-ru-en-quality-note.md` перед сменой `recommended` STT, затем нотаризация. Roadmap: `docs/roadmap.md`.

## Install from GitHub (unsigned DMG)

1. Скачайте `CarrotType-*.dmg` из Releases (или соберите локально — ниже).
2. Перетащите приложение в Applications.
3. **ПКМ → Открыть** (Gatekeeper), либо `xattr -dr com.apple.quarantine /Applications/CarrotType.app`.
4. Настройки → Микрофон + Accessibility → скачайте Whisper Base (или другой STT) → при необходимости **Сделать активным**.

Нотаризация появится после покупки Apple Developer — см. `ops/deploy.md`.

## Build DMG locally

```bash
./macos/scripts/build-release-dmg.sh
# → dist/CarrotType-0.1.0.dmg
```

## Dev

```bash
cd macos
xcodegen generate
open CarrotType.xcodeproj
```

Нужен **полный Xcode**, не только Command Line Tools. Подробности: `ops/environments.md`.

## AIDOS checks

```bash
npm run aidos:validate
npm run aidos:trace
npm run aidos:review
```
