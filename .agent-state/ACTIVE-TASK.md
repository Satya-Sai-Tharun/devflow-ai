# Active Task

**Task ID:** DOC-001  
**Title:** Reconcile and approve the project source-of-truth documentation  
**Status:** Draft prepared for review; not yet reconciled against the user's local tree.

## Objective

Create a consistent documentation baseline for DevFlow AI, using the four document roles shown in the supplied reference (PRD, design system, architecture, agent instructions) and supporting security, style, testing, and planning documents.

## Scope

- `PRD.md`
- `Design-system.md`
- `ARCHITECTURE.md`
- `AGENTS.md`
- `CODE_STYLE.md`
- `docs/SECURITY.md`
- `docs/TESTING.md`
- `PLAN.md`
- `.agent-state/CURRENT.md`
- `.agent-state/ACTIVE-TASK.md`
- Review/update `README.md` to link the approved docs.

## Procedure

1. Inspect Git state and existing documents.
2. Merge, do not blindly overwrite, existing repository-specific guidance.
3. Keep proposals and open decisions clearly labeled.
4. Review links, terminology, file casing, and cross-document consistency.
5. Run Markdown/link checks if the repository has suitable tooling; report only checks actually run.
6. Ask the owner to approve product scope and provisional visual tokens.

## Acceptance criteria

- Product scope and non-goals are explicit.
- Architecture is labeled proposed where decisions are unconfirmed.
- Agents know what to read, how to coordinate, how to test, and when to ask.
- Security, testing, and style rules do not contradict agent instructions.
- The design system defines tokens, components, states, responsive behavior, and accessibility rules.
- Open decisions are visible rather than silently guessed.
- Existing work is preserved and no commit/push occurs without explicit authorization.

## Out of scope

- Implementing application features.
- Choosing unapproved infrastructure or provider integrations.
- Claiming security or production readiness without evidence.
- Automatically changing the remote GitHub repository.

## Handoff

Before implementation, compare this task with the actual local tree and update the status based on verified work.
