# Current Project State

**Last reviewed:** 2026-10-12  
**Status:** Documentation draft for review; this file is not a live inspection of the user's local working tree.

## Known project direction

DevFlow AI is intended to coordinate AI coding agents through LangGraph workflows, MCP integrations, retrieval-augmented context, controlled tool execution, human approval, and automated evaluation.

## Source-of-truth draft set

- `PRD.md` — product statement, users, requirements, non-goals, MVP acceptance criteria.
- `ARCHITECTURE.md` — proposed component boundaries, data flow, trust boundaries, and open decisions.
- `AGENTS.md` — coding-agent operating rules.
- `Design-system.md` — provisional UI tokens and component/accessibility rules.
- `CODE_STYLE.md` — engineering conventions.
- `docs/SECURITY.md` — security baseline.
- `docs/TESTING.md` — test strategy.
- `PLAN.md` — milestone sequence.
- `README.md` — repository entry point (review/update to link the approved docs).

## Verification limitations

Earlier remote inspection showed a documentation-focused repository snapshot, but that does not prove the current local working tree has the same contents. Inspect `git status --short`, the actual tree, and recent commits before applying these files. Preserve local edits and reconcile existing files rather than blindly overwriting them.

No implementation status, test status, integration availability, or command validity is asserted by this draft.

## Active focus

Review and reconcile documentation, then confirm MVP decisions before broad implementation.

## Next actions

1. Compare this draft set with current tracked and untracked files.
2. Merge useful existing content; preserve repository-specific rules and skills.
3. Resolve conflicting names/casing such as `Design-system.md` versus `DESIGN_SYSTEM.md` only after checking current consumers and conventions.
4. Obtain owner approval for PRD scope and provisional design tokens.
5. Update this file with verified local state and the next active task.
