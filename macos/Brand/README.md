# CarrotType A brand masters

Selected by the maintainer on 2026-11-10: native UI A + geometric carrot A. Original paths authored for CarrotType; repository MIT terms apply. No competitor vector/font/code copied; no trademark clearance claim.

- `CarrotType-Mark.svg`: editable colored mark, green leaves `#557B4C`, root `#D0632F`.
- `CarrotType-AppIcon.svg`: same mark on the neutral native icon tile, 64-unit editable geometry.
- `CarrotType-Template.svg`: 18-point monochrome template, same silhouette. Copied into `CarrotMark.imageset`; Xcode preserves vector representation. Only the idle menu uses this mark. Recording/processing/error icons and labels are retained.

Export deterministic PNGs for all macOS slots with full Xcode selected:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift macos/scripts/render-brand.swift
python3 scripts/verify-brand.py
```

The renderer implements the deliberately small SVG subset used by these masters, not a general SVG import pipeline. Do not paste arbitrary SVGs into it. Color/geometry changes must be reflected in the related masters/template source, then verified. The Xcode app icon feeds AppKit, Sparkle and the installer app icon automatically. Installer arrow accent lives in `packaging/dmg/layout.sh`; regenerate with `render-dmg-background.swift`. This does not package or publish a DMG.

Legacy: the original 0.6.2 1024px export is archived in `docs/design/0.7.0/legacy/app-icon-0.6.2-1024.png`; all old assets remain in git history/tag v0.6.2. New PNG slot filenames replace opaque old export filenames. No models are bundled in these assets.
