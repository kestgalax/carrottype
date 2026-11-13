# Motion OS tooling pin

CarrotType uses **Motion OS** as private maintainer tooling for short product films (changelog / What’s New / feature tours). It is not part of the shipped app and is not required for normal product builds or public CI.

## Pinned revision

| Field | Value |
| --- | --- |
| Repository | `kestgalax/motion-os` (private) |
| Pin | `557ec2c88a4f4db5a3cb43a189c383001a2e5a37` |
| Note | Beat-map override + subpath webpack aliases so skins import `motion-os/*` without npm link |

## Local setup

Requires read access to the private motion-os repository.

```bash
git clone https://github.com/kestgalax/motion-os.git ~/src/motion-os
# or sibling: ../motion-os next to this repo
cd ~/src/motion-os
git checkout 557ec2c88a4f4db5a3cb43a189c383001a2e5a37
npm install
export MOTION_OS_ROOT=~/src/motion-os   # or relative path from CarrotType root, e.g. ../motion-os
```

From the CarrotType root (with `MOTION_OS_ROOT` set):

```bash
npm run motion -- run motion/briefs/theme.md
npm run motion -- check motion/out/theme.mp4
```

There is **no** `motion-os` entry in `package.json` dependencies (same pattern as AIDOS / `AIDOS_ROOT`).

## Upgrade procedure

1. Choose a new motion-os commit on `kestgalax/motion-os` `master`.
2. Update the pin in this file.
3. Locally: `git -C "$MOTION_OS_ROOT" fetch && git -C "$MOTION_OS_ROOT" checkout <pin> && npm install`.
4. Re-run `npm run motion -- run motion/briefs/theme.md` and `check`.

## CI

Hosted product CI does **not** install private motion-os. Motion renders are local/maintainer-only unless a future workflow gains a read token and an explicit motion job (not required for app releases).

## Out of scope

- Publishing motion-os to npm
- Making motion-os public
- Bundling Remotion into the macOS app
