# Workflow

```text
Idea -> Product Intent -> Stack ADR Gate -> Dev Environment -> Feature -> Tasks -> Implementation -> Review -> Release
```

## Phase Gates

### 1. Idea

- Fill `docs/product-intent.md`.
- Keep `docs/roadmap.md` Milestone 0 current.

### 2. Stack ADR Gate

- Do not scaffold application runtime code before `docs/decisions/ADR-002-runtime-stack.md` is Accepted.
- Update `docs/architecture.md` after the stack ADR is accepted.

### 3. Dev Environment

- Choose local tooling for the accepted stack.
- Document environments in `ops/environments.md`.
- Record CI expectations in `ops/ci.md`.

### 4. First Feature

- Create linked artifacts with `aidos new flow "<feature name>"` from the AIDOS tooling root.
- Run `npm run aidos:trace` and `npm run aidos:review` before merge.

See the lifecycle guide in your AIDOS clone: `docs/onboarding-project-lifecycle.md`.
