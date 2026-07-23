# ADR-001: Initial Project Structure

## Status

Accepted

## Context

This project needs an explicit structure before implementation starts.

Planned product form: Native macOS menu bar / background app with global hotkey

## Decision

Use AIDOS repository artifacts for intent, architecture, decisions, execution, and governance.

## Alternatives

- Start with code only.
  Rationale: rejected because agents need durable context.

## Consequences

- AI agents have a deterministic entry point.
- Project memory is stored with the repository.
- Runtime stack is governed by `ADR-002-runtime-stack.md`.
