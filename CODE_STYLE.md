# Code Style and Engineering Conventions

**Status:** Baseline rules; language-specific tooling must be confirmed from the repository before commands or configurations are added.

## 1. General principles

- Prefer readable, explicit code over clever or overly compressed implementations.
- Keep functions, modules, and components focused on one responsibility.
- Use descriptive names and consistent terminology from `PRD.md` and `ARCHITECTURE.md`.
- Avoid unrelated refactors, speculative abstractions, and duplicate sources of truth.
- Document non-obvious decisions and public interfaces, not every line.

## 2. Formatting and linting

- First inspect existing formatter, linter, type-checker, and configuration files.
- Use the repository's configured tools and versions; do not introduce a competing formatter without approval.
- Keep diffs focused and avoid formatting untouched files.
- Do not claim linting or formatting checks passed unless the command actually completed successfully.

## 3. Naming

- Follow the language's established conventions and existing project patterns.
- Use names that communicate intent; avoid unexplained abbreviations.
- Keep product terms consistent: task, workflow, approval, tool, verification, audit event.
- Use consistent casing for public types, modules, files, and environment-variable names.

## 4. Modules and dependencies

- Keep provider-specific integrations behind narrow adapters.
- Validate data at module and service boundaries.
- Avoid circular dependencies and unnecessary global mutable state.
- Add dependencies only when they provide clear value; explain material trade-offs.
- Pin or constrain versions using the repository's existing dependency-management strategy.

## 5. Error handling and logging

- Fail explicitly and preserve useful diagnostic context.
- Do not swallow exceptions or convert failures into success.
- Do not log secrets, access tokens, private keys, or unnecessary personal data.
- Use structured logs and stable error categories where supported.
- Apply timeouts and bounded retries to external calls.

## 6. Configuration and secrets

- Use environment-based or approved secret-manager configuration.
- Keep real credentials out of Git and examples.
- Validate required configuration at startup and provide actionable, non-sensitive errors.
- Document safe placeholders in `.env.example` if the project uses one.

## 7. UI conventions

- Follow `Design-system.md` for approved tokens, states, spacing, and accessibility.
- Reuse existing shared components and styling mechanisms.
- Provide loading, empty, error, disabled, and focus states where applicable.
- Do not use color alone to convey state.

## 8. Tests

- Follow `docs/TESTING.md`.
- Prefer deterministic tests with explicit fixtures.
- Test success, invalid input, failure, permission-denied, timeout, and boundary cases as relevant.
- Avoid tests that depend on live external services unless explicitly classified as integration tests.

## 9. Open decisions

Confirm language-specific formatting, linting, type checking, import sorting, test commands, and CI enforcement after inspecting the actual repository. Do not add hypothetical commands to documentation as if they are verified.
