# Gemini CLI Instructions

Read and follow @AGENTS.md before working on this repository.

`AGENTS.md` is the universal source of agent rules for this project: the working
protocol, engineering rules, documentation rules, security boundaries, and the
required handoff format. Do not duplicate those rules here; treat this file as a
pointer so the rules cannot drift apart.

This repository contains **documentation and specifications only** — there is no
application code, dependency manifest, test suite, migration, or CI. Verify that
state yourself with `git status --short` and `git ls-files` before asserting
anything about what exists.

Start with `PROJECT_CONTEXT.md` for orientation and
`docs/DOCUMENTATION_INDEX.md` to find which document is authoritative for the
subject you are about to change.

## Gemini-specific notes

- Context file name: this project supplies `GEMINI.md`. If your configuration
  overrides `contextFileName`, keep this file as the entry point rather than
  pointing directly at `AGENTS.md`, so tool-specific notes such as these survive.
- Prefer `read_file`/`search_file_content` over shell equivalents when inspecting
  documentation, and do not run `graphify` commands expecting useful output:
  the graph at `graphify-out/` is machine-local, gitignored, and stale. See
  `CLAUDE.md` for the full caveat.
- When you finish a task, produce the handoff described in `AGENTS.md`
  § Required handoff. Do not claim any test, command, or performance target
  passed unless you actually ran it and can report the result.
