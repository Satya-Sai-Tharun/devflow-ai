# 0005. Model provider strategy and spend controls

- **Status:** **Proposed** — owner approved the free-first *direction*; the concrete provider set and limits need confirmation
- **Date:** 2026-10-12
- **Deciders:** project owner (direction recorded as approved); agent recommendation for specifics
- **Related requirements:** PR-005, PR-009, PR-010, PR-013
- **Related documents:** `PROJECT_CONTEXT.md` §3, `docs/AGENT_RUNTIME.md`, `docs/THREAT_MODEL.md` (denial-of-wallet), `docs/PERFORMANCE.md`

## Context

Background agent execution needs a model, but the project must remain testable without inference cost and must not depend on any provider's free tier, limits, or continued availability. `PROJECT_CONTEXT.md` records the owner-approved staged strategy:

1. deterministic mock adapter first,
2. then a local provider such as Ollama,
3. hosted free tiers only as optional adapters.

The unresolved questions are which providers are actually permitted, what the numeric budgets are, and how spend is bounded — an unbounded agent with a paid provider is a denial-of-wallet vulnerability, treated as a security issue in `docs/THREAT_MODEL.md`.

## Decision (recommended)

**Keep orchestration provider-agnostic; make the mock adapter the default; treat everything else as opt-in configuration.**

1. **Interface first.** All model access goes through the agent adapter interface in `docs/AGENT_RUNTIME.md`. Graph and domain code never import a provider SDK directly.
2. **Mock is the default in tests and CI.** Deterministic, seeded, network-free. Every lifecycle, retry, failure, approval, and progress test runs against it. This is non-negotiable — it is what makes the workflow testable at zero cost.
3. **Local provider is the default for real development.** Ollama or equivalent behind the same adapter. Document hardware requirements, memory needs, model size, and expected speed honestly, including the fact that quality and latency depend on the machine.
4. **Hosted providers are optional adapters, disabled by default.** Enabling one requires explicit configuration **and** an explicit spend limit. No hosted provider may be required for any core test, CI job, or the first vertical slice.
5. **Mandatory spend controls** (details in `docs/AGENT_RUNTIME.md` § budgets): per-call output/token caps, per-task token and step caps, per-task wall-clock deadline, bounded retries, a global concurrency limit on model calls, and a circuit breaker that blocks further model calls once a configured budget is exhausted.
6. **Usage is recorded** per task and per attempt (provider, model, tokens, duration, outcome) so cost is observable rather than guessed.

## Alternatives considered

- **Provider SDK called directly from graph nodes.** Rejected: it contradicts ADR 0001, makes provider switching a rewrite, and scatters credentials and spend logic across the codebase.
- **Hosted provider only, no mock.** Rejected: tests become non-deterministic, slow, and cost money; CI would require live credentials.
- **Local-only, forbidding hosted models permanently.** Rejected as an architecture constraint, though it remains a valid *policy* choice for a self-hosted deployment. The adapter must permit either.
- **Auto-routing across providers by cost/capability from the start.** Deferred: routing policy requires measured quality and cost data that does not exist yet. Premature routing adds failure modes and obscure debugging.
- **Free-tier hosted provider as the primary path.** Explicitly rejected by the owner: free tiers change or disappear, and core architecture must not depend on them.
- **Fine-tuning or self-hosted GPU inference.** Out of scope; revisit only with measured need and hardware budget.

## Consequences

**Positive:** zero-cost deterministic testing; no vendor lock-in; providers swappable without domain changes; spend is bounded and observable; the project stays runnable on a developer laptop.

**Negative / accepted costs:** local model quality and speed are hardware-dependent and may be insufficient for complex tasks — this must be documented rather than hidden; every adapter adds a translation layer and normalization work; provider capability differences (tool calling, context length, streaming) must be expressed in the interface rather than assumed.

**Residual risk:** a model may still produce unsafe or incorrect output regardless of provider. This is not solved by provider choice — it is managed by verification, sandboxing, approval gates, and the invariant that model output never grants permission.

## Verification

- **Unit:** the mock adapter is deterministic — the same input yields the same output across runs.
- **Integration:** switching the configured provider requires no change to graph or domain code (verified by running the same test suite against mock and a second adapter).
- **Integration:** exhausting the budget circuit breaker halts further model calls and surfaces a distinct, honest error state rather than a silent failure.
- **CI:** the default test suite makes no network calls (verify by running it with egress blocked).
- **Evaluation:** any live-provider evaluation is optional, separately labeled, cost-controlled, and never a required gate. No evaluation results exist yet.

## Open questions for the owner

1. Are hosted model providers permitted at all for this project, or is local-only the policy?
2. Which local runtime and model? What hardware is the baseline, which sets realistic expectations?
3. What are the concrete spend ceilings — per task, per day, and globally?
4. Is any live-provider test permitted in CI, or do all such tests remain manually invoked?
