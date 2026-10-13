# 0007. Runtime versions and package managers

- **Status:** **Accepted** — approved by the project owner on 2026-10-13
- **Date:** 2026-10-12 (proposed); 2026-10-13 (accepted)
- **Deciders:** project owner
- **Related requirements:** PR-013, PR-015
- **Related documents:** `PLAN.md` Milestone 1, `CODE_STYLE.md`, `docs/TESTING.md`

> **Owner decision (2026-10-13):** **Python 3.12.x** with **`uv`**; **Node.js 22 LTS** with **`pnpm`**; a **single monorepo**. Tooling: **pytest**, **Ruff**, **Pyright**, **ESLint**, **TypeScript checking**, **Vitest**, and **Playwright**.

## Context

The repository contains **no dependency manifests and no lockfiles** — verified: no project-owned `pyproject.toml`, `requirements.txt`, or `package.json`. `PLAN.md` Milestone 1 requires selecting "Python/Node versions and package managers" and establishing format/lint/type-check/test commands; its exit criterion is "reproducible setup and baseline checks". `PRD.md` success metrics include "reproducibility of local setup and tests".

This decision is low-risk and easily reversible, but it blocks the entire developer foundation, so pinning it early unblocks everything else.

## Decision (recommended)

1. **Python:** a single pinned minor version, declared in one authoritative place, with a committed lockfile. Recommended: a modern stable Python 3.12.x line, pinned via `.python-version` plus a `requires-python` constraint. Recommended package manager: **`uv`** for its speed and lockfile determinism — with plain `pip` + a compiled lock as the conservative fallback if the owner prefers minimal tooling.
2. **Node.js:** a pinned LTS line (Node 22 LTS class) declared via `engines` in `package.json` and `.nvmrc`. Recommended package manager: **`pnpm`** for strict, non-flat dependency resolution and efficient disk use, which suits a monorepo-shaped layout. `npm` remains an acceptable fallback.
3. **One manifest per concern, one lockfile per manifest, committed.** No unpinned installs in CI. No mixing package managers within a language.
4. **Tooling selected minimally, once, and recorded:** Python — pytest, Ruff (lint + format), and one type checker (mypy **or** Pyright, not both). TypeScript — ESLint, `tsc --noEmit`, Vitest, and Playwright for browser flows. Record the *reason* for each choice in `CODE_STYLE.md`/`docs/TESTING.md` rather than installing every candidate.
5. **Node.js is not required for the core backend.** It is required only for the dashboard and its tooling.

## Alternatives considered

- **`pip` + `requirements.txt` only.** Maximum familiarity and zero extra tooling. Rejected as the primary recommendation because it lacks a first-class universal lockfile with hashes and transitive pinning; still viable if the owner prefers minimal dependencies.
- **Poetry or PDM.** Both capable and mature. Viable; `uv` is recommended purely for speed and single-binary simplicity. This is a preference, not a correctness difference — the owner may override freely.
- **Conda.** Rejected: heavy operational surface for a project that does not need non-Python binary dependencies.
- **`npm` or `yarn` instead of `pnpm`.** All acceptable. `pnpm` recommended for strict resolution that surfaces undeclared dependencies early; no correctness barrier to `npm`.
- **Deno or Bun for the dashboard.** Rejected: Next.js App Router support and ecosystem maturity favor Node.js; the project should not absorb runtime novelty alongside an unproven architecture.
- **No version pinning (use "latest").** Rejected: directly contradicts the reproducibility success metric and makes "works on my machine" the expected failure mode.

## Consequences

**Positive:** reproducible installs and CI; a defined baseline for the first committed code; faster CI with cached dependency installs; fewer "which version are you on" defects.

**Negative / accepted costs:** contributors must install the chosen package managers; version upgrades become deliberate, reviewed changes rather than incidental ones; an extra manifest/lockfile pair to maintain.

**Note:** choosing these does **not** authorize installing anything. Per `PROJECT_CONTEXT.md` §10, dependency installation requires presenting the dependency list and rationale, and this documentation task must not install dependencies.

## Verification

- **CI/local:** a clean clone plus the documented install command produces a working environment without manual steps — record the exact commands actually run.
- **Check:** dependency installation is refused when the pinned runtime version does not match.
- **Check:** lockfiles are committed and CI installs strictly from the lock (frozen/locked mode), so an undeclared dependency fails rather than silently resolving.
- **Review:** no tool is added that duplicates an existing one without a recorded reason.

## Open questions for the owner

1. Approve `uv` + `pnpm`, or prefer `pip`/`npm` for familiarity?
2. Any constraint on the Python or Node version from an existing environment or host?
3. One type checker for Python — mypy or Pyright?
4. Is the repository intended to remain a single package, or become a monorepo (which affects package-manager and workspace configuration)?
