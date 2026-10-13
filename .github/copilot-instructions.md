# DevFlow AI — GitHub Copilot Instructions

Follow the repository-wide instructions in **[`AGENTS.md`](../AGENTS.md)**. That file is the single universal source of agent rules for this project — the working protocol, engineering rules, documentation rules, security boundaries, and the required handoff format. Read it before making changes.

This file is a thin adapter. Do not add engineering, security, or lifecycle rules here: a rule written in two places will drift, and `AGENTS.md` always wins.

## Repository state

This repository contains **documentation and specifications only**. There is no application code, no dependency manifest, no test suite, no migration, and no CI. Verify that yourself with `git status --short` and `git ls-files` before asserting anything about what exists, and never report a feature as implemented or a test as passing without evidence.

Orientation: start at [`PROJECT_CONTEXT.md`](../PROJECT_CONTEXT.md); use [`docs/DOCUMENTATION_INDEX.md`](../docs/DOCUMENTATION_INDEX.md) to find which document is authoritative for the subject you are changing.

## Working notes

- Make focused, testable changes; follow existing architecture and conventions.
- Never expose credentials or bypass tool-execution security controls.
- Do not rely on the gitignored `.agents/`, `.claude/`, `.codex/`, or `.opencode/` trees, or on `graphify-out/`: they are machine-local and, for this checkout, the graph is stale. See [`CLAUDE.md`](../CLAUDE.md).
- After any documentation change, run `powershell -File tools/validate-docs.ps1` and report the actual result.
- Run relevant checks and report actual results and limitations.
- Do not commit, push, or publish unless explicitly asked.
