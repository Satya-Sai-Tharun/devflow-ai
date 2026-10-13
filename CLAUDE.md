# Claude Code Instructions

Read and follow @AGENTS.md before working on this repository.
Follow its single-agent development default, engineering rules, and security
requirements. Inspect relevant project files before making changes.

## graphify

This project has a knowledge graph at graphify-out/ with god nodes, community structure, and cross-file relationships.

**Read this before relying on the graph.** As verified at commit `e8a4d71`, `graphify-out/` is **stale and misleading for this repository**:

- It was built from commit `92b26715`, which is far behind `HEAD`.
- Its ~3,369 nodes are dominated by the third-party skill libraries under `.agents/`, `.claude/`, `.codex/`, and `.opencode/` (which are gitignored and are not project sources).
- At that verification point there was no first-party application code to graph. The initial API foundation now exists under `services/api/`, but the graph has not been refreshed to include it and remains incomplete for current codebase questions.
- `graphify-out/wiki/index.md` **does not exist**, despite being referenced below.

So: for DevFlow AI architecture or requirements questions, **read the Markdown source-of-truth documents** ([`PROJECT_CONTEXT.md`](PROJECT_CONTEXT.md) and [`docs/DOCUMENTATION_INDEX.md`](docs/DOCUMENTATION_INDEX.md)) rather than querying the graph. Re-run `graphify update .` (or a full rebuild excluding the gitignored skill directories) before trusting graph results again.

Rules, once the graph is current:
- For codebase questions, first run `graphify query "<question>"` when graphify-out/graph.json exists. Use `graphify path "<A>" "<B>"` for relationships and `graphify explain "<concept>"` for focused concepts. These return a scoped subgraph, usually much smaller than GRAPH_REPORT.md or raw grep output.
- If graphify-out/wiki/index.md exists, use it for broad navigation instead of raw source browsing.
- Read graphify-out/GRAPH_REPORT.md only for broad architecture review or when query/path/explain do not surface enough context.
- After modifying code, run `graphify update .` to keep the graph current (AST-only, no API cost).
