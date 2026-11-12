# AIDOS tooling pin

CarrotType runs AIDOS as external governance tooling. The product repository does not require a sibling `../AIDOS` checkout.

## Pinned revision

| Field | Value |
| --- | --- |
| Repository | `kestgalax/AIDOS` |
| Pin | `be33ba2829793479f8df80842051b35e6a8f413c` |
| Note | Merge of PR [#2](https://github.com/kestgalax/AIDOS/pull/2) on `main` (Milestone 8 + ADR-008 tip `74a4d8b`) |
| Contract defaults | No `schema` / no `contractVersion` in this repo yet (legacy-compatible). Opt-in later is a separate decision. |

## Local setup

```bash
git clone https://github.com/kestgalax/AIDOS.git ~/src/AIDOS
cd ~/src/AIDOS
git checkout be33ba2829793479f8df80842051b35e6a8f413c
npm install
export AIDOS_ROOT=~/src/AIDOS
```

From the CarrotType root:

```bash
npm run aidos:validate
npm run aidos:trace
npm run aidos:review
# optional, flow-scoped:
# node scripts/run-aidos.mjs closure <review-slug>
```

`AIDOS_ROOT` is the supported way to point at a checkout. Installing `aidos` onto `PATH` also works once a distribution exists; until then prefer `AIDOS_ROOT`.

## Upgrade procedure

1. Choose a new AIDOS commit/tag on `kestgalax/AIDOS` `main`.
2. Update the pin in this file and in `.github/workflows/macos.yml` (`ref:`).
3. Locally: `git -C "$AIDOS_ROOT" fetch && git -C "$AIDOS_ROOT" checkout <pin> && npm install`.
4. Re-run validate/trace/review and record any new findings before merging the pin bump.

## CI

Hosted governance checks out the same pin into `.aidos`, runs `npm install` there, and sets `AIDOS_ROOT`. Without `AIDOS_READ_TOKEN`, hosted governance is skipped; local evidence remains required.

## Out of scope for this pin

- Flipping `schema: 2` or `contractVersion: 2`
- Publishing AIDOS to npm
- Changing application behavior or release version
