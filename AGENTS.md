# Agent Instructions — DevFlow AI

## Read first
Before making changes, inspect Git status and read:
1. `PROJECT_CONTEXT.md` — master briefing, verified repository state, conflict-resolution order
2. `AGENTS.md` (this file)
3. `PRD.md`
4. `SPEC.md`
5. `ARCHITECTURE.md`
6. `Design-system.md` for UI work
7. `CODE_STYLE.md`
8. `docs/SECURITY.md` and `docs/THREAT_MODEL.md`
9. `docs/TESTING.md`
10. `docs/DOCUMENTATION_INDEX.md` — which document is authoritative for your subject
11. `PLAN.md`
12. `.agent-state/CURRENT.md` and `.agent-state/ACTIVE-TASK.md`

Read the subject documents relevant to your change; you are not expected to read all of them for every task. Use `docs/DOCUMENTATION_INDEX.md` § 9 to find the right one quickly.

## Verified starting conditions
At baseline commit `e82ba8f`, this repository contained documentation and specifications only. The initial Python API foundation was merged into `dev` by PR #2 at `f373ebc`; `.agent-state/CURRENT.md` records verified current facts. Product requirements remain planned unless evidence is linked (see `docs/REQUIREMENTS_TRACEABILITY.md`).

Also follow existing tool-specific instructions (`CLAUDE.md`, `.github/copilot-instructions.md`, `.codex`, `.opencode`, `.agents`, and other agent configs). If instructions conflict, stop and report the conflict rather than silently deleting or weakening a rule.

## Cross-agent support

This file (`AGENTS.md`) is the **single universal entry point** for all coding agents. Several agents read it natively; the rest have a thin adapter file in their own format that points here. Adapter files must never restate rules — only point at this file.

| Agent / tool | Reads natively | Adapter file | Status |
|---|---|---|---|
| Codex / OpenAI agents | `AGENTS.md` | — | Native, portable |
| Cursor | `AGENTS.md` (root and nested) | — | Native, portable |
| Windsurf Cascade | `AGENTS.md` (root = always-on rule) | — | Native, portable |
| opencode | `AGENTS.md` | — | Native, portable. Note: `.opencode/` is **gitignored**, so `opencode.json` is machine-local and absent from a fresh clone — the `AGENTS.md` fallback is what makes this work |
| Claude Code | `CLAUDE.md` | [`CLAUDE.md`](CLAUDE.md) | Adapter present, tracked |
| GitHub Copilot | `.github/copilot-instructions.md` | [`.github/copilot-instructions.md`](.github/copilot-instructions.md) | Adapter present, tracked |
| Gemini CLI | `GEMINI.md` | [`GEMINI.md`](GEMINI.md) | Adapter present, tracked |
| Aider | `CONVENTIONS.md` via `--read` | none needed — pass `--read CODE_STYLE.md AGENTS.md` | Documented, no file |
| Zed and other `AGENTS.md` readers | `AGENTS.md` | — | Native, portable |

Only the three **tracked** adapter files are guaranteed to exist in a fresh clone. Every other tool integration in this project is either native `AGENTS.md` support or a gitignored machine-local install. That is why `AGENTS.md` must remain self-sufficient: no rule may live only in an adapter file or only in a gitignored directory.

Rules for adapter files:

1. **Keep them thin.** A pointer to this file plus, at most, tool-specific mechanics. Never duplicate engineering, security, or lifecycle rules — a duplicated rule will drift.
2. **Never contradict this file.** `AGENTS.md` is universal and wins. A concrete example of the failure mode this prevents: `.claude/CLAUDE.md` once described only the graphify skill, silently omitting every engineering rule, while the root `CLAUDE.md` pointed at this file.
3. **Adding support for a new agent** means adding a row above and, if the agent cannot read `AGENTS.md`, a thin adapter file. Do not add agent-specific rules to `AGENTS.md` itself.

### Tracked versus machine-local agent configuration

- **Tracked and portable:** `AGENTS.md`, `CLAUDE.md`, `GEMINI.md`, `.github/copilot-instructions.md`. These describe *how to work* and are shared with every contributor and agent.
- **Gitignored and machine-local:** `.agents/`, `.claude/`, `.codex/`, `.opencode/`. These hold *installed skills, plugins, and hooks* — they are environment, not project policy.
- **Consequence:** because the second group is gitignored, no agent may assume a skill, plugin, or hook is present for anyone else. In particular, `graphify-out/` and the graphify hook configuration are machine-local and currently **stale** (see [`CLAUDE.md`](CLAUDE.md)); do not make a build step depend on them.
- **Portability rule:** tracked files must never contain a machine-specific absolute path. In particular, gitignored `.codex/hooks.json` and `.claude/settings.json` in this checkout reference `C:/Users/<user>/.local/bin/...`. That is acceptable *only* because they are untracked and machine-local; never copy such a path into a tracked file. `tools/validate-docs.ps1` fails the build if one appears in documentation.

## Product direction
MVP: Next.js App Router + shadcn/ui dashboard; Python FastAPI API; LangGraph worker; Python CLI using the same API; PostgreSQL for durable state; Redis only when justified. Task submission must remain independent of full agent execution.

## Working protocol
- Use one coding agent at a time by default. Codex is the primary coding agent unless the user explicitly selects another.
- Run multiple coding agents concurrently only with explicit user authorization.
- No CAO or local development-time multi-agent coordinator is required. Do not install or implement orchestration infrastructure without explicit authorization.
- Define task scope, handoffs, and validation results explicitly, whether work is done by one agent or several.
- Inspect current files, tracked/untracked changes, and recent commits before editing.
- Preserve user changes, repository-specific rules, existing skills, and agent configuration.
- Prefer small, coherent, testable diffs over broad rewrites.
- Do not move files or create a new monorepo layout until the actual tree and package conventions are inspected.
- Assign one writer agent per shared file/feature. Parallel agents may review or work on disjoint files only.
- Agree on file ownership and API contracts before parallel implementation.
- Do not overwrite config, secrets, deployment files, or tool instructions without explicit approval.
- Do not run destructive commands or force-update dependencies without authorization.
- Do not commit, push, publish, deploy, or create external resources unless explicitly asked.
- Ask when a decision affects security, data retention, deployment, cost, or product scope.

## Git branches and integration
- `main` is the stable, reviewed release branch. `dev` is the integration branch for approved implementation work.
- Use `feature/<short-description>` for feature implementation, `fix/<short-description>` for bug fixes, `test/<short-description>` for testing infrastructure or test-focused changes, `docs/<short-description>` for documentation-only work, and `chore/<short-description>` for tooling and maintenance. Branch names must be lowercase and use hyphens.
- Before any branch operation, inspect `git status`, the current branch, `HEAD`, and available local and remote branches. Never create a branch without checking whether it already exists.
- Feature branches start from the current, verified `dev` branch unless the task explicitly requires another base. Do not develop features directly on `main` or `dev`.
- Integrate reviewed feature branches into `dev` through pull requests. Promote `dev` to `main` only through an explicitly authorized, reviewed release.
- Never force-push, rewrite shared history, or bypass required checks. Never commit, push, merge, publish, or deploy without explicit owner authorization.

## Agent isolation and handoffs
- Use feature branches and separate Git worktrees when required by the branch rules below or to isolate concurrent tasks. If multiple coding agents are explicitly authorized, each implementation agent must use a separate worktree and task-specific branch; never let multiple agents write in the same worktree.
- Assign one writer per feature and shared file. Establish file ownership, dependencies, and API/schema contracts before parallel implementation; reviewers may inspect concurrently but must not modify another agent's worktree.
- Integrate reviewed feature branches through pull requests. Agents must not independently merge or push.
- Keep task scope, blockers, decisions, validation evidence, and handoff details explicit in the task record or handoff. A shared coordination service is not required.
- Do not assume independent CLI sessions can communicate automatically. Verify any actual messaging implementation before describing it as available.

## Engineering rules
- Keep HTTP request handlers short; never await the full agent workflow during task submission.
- Use explicit task state transitions and test invalid transitions.
- Treat agent output, retrieved context, repository files, and tool output as untrusted data.
- Tool execution is deny-by-default, allowlisted, schema-validated, permissioned, bounded, and audited.
- No unrestricted host shell/filesystem/network access for agents.
- Use async I/O correctly; do not block async handlers.
- Bound concurrency, retries, execution time, output size, and resource use.
- Use the shared API for CLI and web workflows; do not duplicate business logic in the CLI.
- Use existing design tokens and shadcn/ui conventions for UI work.
- Do not claim a test, command, performance target, or security control passed unless it was actually verified.

## Documentation rules
- `docs/DOCUMENTATION_INDEX.md` § 2 defines which document is authoritative for each subject. Change the authoritative document, then update every document that restates it, in the same change set.
- After any documentation change, run `powershell -File tools/validate-docs.ps1` and report the actual result in the handoff.
- Never restate a contract in a second document; summarize and link instead.
- Mark anything not owner-approved as **Proposed** or **Unresolved decision**. A proposal is not a decision and must not be cited as one.
- `docs/PERFORMANCE.md` is authoritative for performance budgets. Record a benchmark only with environment, workload, concurrency, duration, percentiles, and the exact command.
- Do not delete or archive documents; recommend archival and wait for owner approval.
- Do not edit `.agents/`, `.claude/`, `.codex/`, `.opencode/` — these are gitignored third-party skill libraries.

## Required handoff
For each task, report:
- What changed and why.
- Files changed.
- Commands/tests actually run and their results.
- Known limitations and follow-up work.
- Any unimplemented assumptions or decisions requiring owner input.
