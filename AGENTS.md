# DevFlow AI — Agent Instructions

## Project Goal
Build DevFlow AI, an agentic software engineering platform using LangGraph,
MCP, RAG, secure tool execution, human-in-the-loop workflows, and automated
evaluation.

## Before Starting Work
1. Read this file and the root README.md.
2. Inspect the current Git branch, working tree, and recent commits.
3. Read PLAN.md and relevant files under .agent-state/ if they exist.
4. Identify assumptions, dependencies, risks, and acceptance criteria.
5. Prefer a small, verifiable implementation over unnecessary abstractions.

## Engineering Rules
- Make focused changes; do not rewrite unrelated files.
- Follow existing project conventions and established architecture.
- Never hardcode credentials, API keys, or private tokens.
- Keep secrets in environment variables; commit .env.example, never .env.
- Validate external inputs and enforce least-privilege tool access.
- Require human approval for consequential or destructive operations.
- Add or update tests for behavior changes.
- Run applicable tests, linting, and type checks before declaring completion.
- Never claim a check passed unless it was actually run successfully.

## Multi-Agent Coordination
- Inspect the working tree before modifying files.
- Avoid overlapping edits with other agents.
- Use .agent-state/ for shared task and handoff records when established.
- Record changed files, commands executed, test results, and known limitations.
- Do not overwrite another agent's work or discard uncommitted changes.

## Definition of Done
- Acceptance criteria are satisfied.
- Relevant tests and quality checks have been run.
- Changes and remaining limitations are summarized.
- Git changes are reviewed before committing.
