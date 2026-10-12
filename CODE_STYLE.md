# Code Style and Engineering Conventions

## General
- Favor readable, typed, cohesive code over clever abstractions.
- Keep changes focused; avoid unrelated formatting churn.
- Name modules and functions by responsibility.
- Validate at system boundaries and keep domain invariants in domain code.
- Document non-obvious tradeoffs, not self-evident syntax.
- Do not commit secrets, local environment files, caches, build outputs, or generated data unless explicitly required.

## Python
- Use type annotations for public functions, domain models, and API contracts.
- Use Pydantic at request/response boundaries and explicit domain validation for lifecycle transitions.
- Keep I/O boundaries visible; use async functions for async I/O and avoid blocking the event loop.
- Use structured exceptions and stable error codes at API boundaries.
- Configure format/lint/type-check tools after inspecting current project conventions; do not introduce duplicate tooling without reason.
- Tests should be deterministic and avoid real provider/network calls by default.

## TypeScript and React
- Use strict TypeScript and explicit types for API contracts.
- Avoid `any`; prefer narrowing and schema validation for untrusted input.
- Keep components small and focused. Separate server state, UI state, and derived state.
- Use Server Components by default when interaction is not required.
- Use Client Components only where needed; avoid unnecessary effects and duplicate state.
- Reuse shadcn/ui and existing design tokens.
- Make loading, empty, error, reconnecting, and permission states explicit.
- Respect keyboard access, visible focus, semantic HTML, and reduced-motion preferences.

## API and domain
- Version public API routes (`/api/v1/...`).
- Keep request and response schemas explicit and stable.
- Use consistent structured error responses and correlation IDs.
- Enforce task ownership and authorization on task reads and event streams.
- Make task transitions transactional and auditable.
- Design job handlers to tolerate duplicate delivery and retries.

## Performance
- Benchmark before and after optimization.
- Track API server time separately from queue, LLM, and tool time.
- Avoid N+1 queries, unbounded concurrency, large synchronous payloads, and noisy frontend rerenders.
- Add caching only with an explicit invalidation strategy.
- Do not optimize based solely on intuition or report unmeasured claims.

## Git and coordination
- Inspect `git diff` and `git status` before and after work.
- Avoid force pushes and history rewriting.
- Do not commit/push unless requested.
- For parallel agents, define ownership and avoid overlapping edits.
