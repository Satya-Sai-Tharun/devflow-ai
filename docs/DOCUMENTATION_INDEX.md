# Documentation Index and Source-of-Truth Map

**Purpose:** Answer three questions for any human or coding agent, in order, without reading every file:

1. **Which document is authoritative for the thing I am about to change?**
2. **Is that document current, or does it make claims that have not been verified?**
3. **What else must change in the same commit set so the documents stay consistent?**

**Baseline verified against:** commit `e82ba8f` on `dev`; the Milestone 1 API foundation is uncommitted on its feature branch. Consult Git status and diff for current changes.

---

## 1. The one rule that matters most

> **Change the authoritative document, then update every document that restates it — in the same change set.**
> Never restate a contract in a second document. Summarize and link instead.

Most documentation drift in this repository comes from the same contract being written down in several
places. The lifecycle transition table was previously restated in four files, which is exactly how the
approval-outcome gap in `SPEC.md` stayed invisible (see [`decisions/0010`](decisions/0010-approval-outcome-transitions.md)).

---

## 2. Authoritative document per subject

| Subject | Authoritative document | Status | Notes |
|---|---|---|---|
| Navigation, orientation, verified repo state, conflict rules | [`../PROJECT_CONTEXT.md`](../PROJECT_CONTEXT.md) | Current | Summarizes and links only; owns nothing else |
| Product scope, users, goals, non-goals, requirements `PR-001`…`PR-015`, acceptance criteria, success metrics | [`../PRD.md`](../PRD.md) | Current | Requirements unchanged by this audit |
| Task states, allowed transitions, externally observable behavior, error-semantics baseline | [`../SPEC.md`](../SPEC.md) | Current — **one open gap** | § Known gap: rejected/expired approval has no transition |
| System components, boundaries, data flow, performance/reliability/security architecture, delivery sequence | [`../ARCHITECTURE.md`](../ARCHITECTURE.md) | Current | Target layout; the API foundation now exists under `services/api/` |
| HTTP conventions, error envelope, endpoint shapes, SSE protocol, versioning, caching | [`API_CONTRACTS.md`](API_CONTRACTS.md) | Current | Extends `SPEC.md`; extensions are flagged |
| Agent adapters, workflow stages, execution bounds, failure handling, idempotency | [`AGENT_RUNTIME.md`](AGENT_RUNTIME.md) | Current | § 9.4 cross-references the open approval decision |
| Data model, migrations, indexing, retention, data ownership | [`DATABASE.md`](DATABASE.md) | Current | No product-domain schema exists; the empty baseline migration is implemented, and DDL sketches remain illustrative |
| Security baseline and review checklist | [`SECURITY.md`](SECURITY.md) | Current | Concise checklist; links to the threat model |
| Threat analysis: assets, trust boundaries, STRIDE, AI-specific threats, `SR-01`…`SR-25`, test plan | [`THREAT_MODEL.md`](THREAT_MODEL.md) | Current | Authoritative for security *analysis* |
| Test levels, quality gates, performance measurement protocol | [`TESTING.md`](TESTING.md) | Current | |
| Performance budgets and benchmark protocol | [`PERFORMANCE.md`](PERFORMANCE.md) | Current | **Authoritative for budgets**; other docs must link here |
| Visual tokens, components, states, accessibility, motion | [`../Design-system.md`](../Design-system.md) | Current | Tokens are provisional until reviewed in the app |
| Engineering conventions (Python, TypeScript, API, Git) | [`../CODE_STYLE.md`](../CODE_STYLE.md) | Current | |
| Universal agent rules and single-agent development workflow | [`../AGENTS.md`](../AGENTS.md) | Current | Read-first list is authoritative for agents |
| Milestone sequence and exit criteria | [`../PLAN.md`](../PLAN.md) | Current | Milestone 0 reconciled by this audit |
| Requirement to component to test to evidence mapping | [`REQUIREMENTS_TRACEABILITY.md`](REQUIREMENTS_TRACEABILITY.md) | Current | Product requirements remain not started; foundation requirements have partial evidence |
| Durable decision records | [`decisions/`](decisions/README.md) | **8 Accepted, 3 Proposed** | Proposed records are non-binding |
| Verified current milestone and status | [`../.agent-state/CURRENT.md`](../.agent-state/CURRENT.md) | Current | Verified against the real tree |
| Active bounded task and handoff | [`../.agent-state/ACTIVE-TASK.md`](../.agent-state/ACTIVE-TASK.md) | Current | |
| Automated documentation validation | [`../tools/validate-docs.ps1`](../tools/validate-docs.ps1) | Current | Passes; see § 7 for its limits |
| Universal agent rules and single-agent development workflow | [`../AGENTS.md`](../AGENTS.md) | Current | Single universal entry point; includes the cross-agent support matrix |
| Agent adapter files (tool-specific) | [`../CLAUDE.md`](../CLAUDE.md), [`../GEMINI.md`](../GEMINI.md), [`../.github/copilot-instructions.md`](../.github/copilot-instructions.md) | Current | Thin pointers to `AGENTS.md`; must never restate or contradict it |
| Machine-local agent environment (gitignored) | `.agents/`, `.claude/`, `.codex/`, `.opencode/` | Mixed | Installed skills, plugins, hooks; **not** project policy and **not** portable |

### Overlaps that are intentional, and how they are resolved

| Overlap | Resolution |
|---|---|
| `SECURITY.md` vs `THREAT_MODEL.md` | `SECURITY.md` = baseline checklist. `THREAT_MODEL.md` = full analysis, requirements, and tests. Neither may weaken the other. |
| `SPEC.md` vs `API_CONTRACTS.md` | `SPEC.md` owns task semantics. `API_CONTRACTS.md` owns transport conventions. If they disagree on lifecycle, **`SPEC.md` wins**. |
| `PLAN.md` vs `ARCHITECTURE.md` § 11 | `PLAN.md` owns the milestone sequence and exit criteria; `ARCHITECTURE.md` § 11 is a summary that must track it. |
| `PRD.md`, `ARCHITECTURE.md`, `TESTING.md`, `PERFORMANCE.md` all list budgets | **`PERFORMANCE.md` is authoritative.** The others may summarize but must link, not restate. |
| `PROJECT_CONTEXT.md` vs everything | `PROJECT_CONTEXT.md` is a hub. It may be edited freely to point elsewhere, but never to introduce a new rule. |
| Multiple agent instruction files | `AGENTS.md` is the universal entry point and wins. `CLAUDE.md`, `GEMINI.md`, `.github/copilot-instructions.md` are thin adapters that must point at it and must never restate or contradict a rule. The gitignored `.agents`/`.claude`/`.codex`/`.opencode` trees are machine-local environment, not policy — never rely on them being present. See `AGENTS.md` § Cross-agent support. |

---

## 3. Verification status

Two very different kinds of claim live in these files, and confusing them is the main documentation risk.

| Claim type | Where | Status |
|---|---|---|
| **Owner-approved direction** | `PRD.md`, `SPEC.md`, `ARCHITECTURE.md`, `PROJECT_CONTEXT.md` § 3, `decisions/0001` | Approved — may be built against |
| **Design specification** | `API_CONTRACTS.md`, `AGENT_RUNTIME.md`, `DATABASE.md`, `THREAT_MODEL.md`, `SECURITY.md`, `TESTING.md`, `Design-system.md` | Product contracts remain planned; the API foundation is partially implemented as summarized under test results and in the state handoff |
| **Proposal** | `decisions/0002`–`0010` (except `0001`), and anything marked **Proposed** or **Unresolved decision** | **Not binding.** Do not cite as settled |
| **Measured performance** | — | **None. Zero measurements exist** |
| **Test results** | Local handoff reports 15 unit tests and one PostgreSQL migration integration test passing; Pyright, Ruff lint/format, documentation validation, and diff checks passed. Live PostgreSQL acceptance checks were also reported passing. These are local results, not CI results; see [`../.agent-state/ACTIVE-TASK.md`](../.agent-state/ACTIVE-TASK.md) for scope. |
| **Implemented feature** | Initial API foundation exists uncommitted; product workflows remain unimplemented |

**Rule:** before repeating any claim in a new document or a commit message, check which row it belongs to.
Never promote a proposal to a decision, or a specification to an implementation, without evidence.

---

## 4. Ownership and concurrency rules

For work by agents and humans:

1. **One writer per file per change set.** Two agents must not edit the same document concurrently.
2. **Claim the subject, not just the file.** If you are changing the task lifecycle, you own
   `SPEC.md` **and** every restatement — coordinate before you start, not after.
3. **One coding agent at a time is the default.** If the user explicitly authorizes parallel agents, they work on disjoint subjects or review only. Safe parallel sets are, for example:
   `Design-system.md` + dashboard docs, versus `DATABASE.md` + `decisions/0008`.
4. **Never silently change an owner-approved decision.** Record a new ADR or a **Proposal** and ask.
5. **Never weaken a security constraint** to make an implementation easier. Security changes require
   explicit owner approval and a corresponding `THREAT_MODEL.md` update.
6. **`PROJECT_CONTEXT.md` and this index need careful edits.** Re-read immediately before writing,
   then re-verify links.
7. **Working-tree isolation.** For genuinely parallel work, use separate Git branches or worktrees
   rather than shared-tree editing. Do not change the repository's existing Git workflow without review.

---

## 5. Staleness rules

A document is **stale** if any of the following is true. Fix or flag it rather than citing it.

| Trigger | Affected documents | Required action |
|---|---|---|
| `git rev-parse HEAD` differs from the commit named in `.agent-state/CURRENT.md` | `CURRENT.md`, `PROJECT_CONTEXT.md` § 2 | Re-verify the facts and update |
| The first application code lands | `README.md`, `PROJECT_CONTEXT.md` § 2, `CURRENT.md`, `REQUIREMENTS_TRACEABILITY.md`, `PLAN.md` | Remove "documentation only" framing; begin marking requirements `Met` **only** with evidence |
| An ADR status changes `Proposed` → `Accepted` | Every doc citing it, plus `decisions/README.md` index | Update the citing text and the index |
| A lifecycle transition changes | `SPEC.md` + **all** restatements (see § 2) | Update everywhere in one change set |
| A performance benchmark is run | `PERFORMANCE.md`, `PRD.md`, `ARCHITECTURE.md`, `TESTING.md`, `PROJECT_CONTEXT.md` § 7 | Record protocol fields; relabel from *target* to *measured* for that metric only |
| A new directory appears in the tree | `ARCHITECTURE.md` § 3, `PROJECT_CONTEXT.md` § 2 | Reconcile the proposed layout with reality |
| Tool instruction files change | `AGENTS.md` read-first list, this index | Verify no tool file contradicts `AGENTS.md` |

**Reserved for owner authorization:** do not delete or archive any document. Recommend archival in an
audit report and wait, per `PROJECT_CONTEXT.md` § 10.

---

## 6. Change-management protocol

Any agent proposing an improvement must, in order:

1. State the problem **with evidence** (a file, a line, a command result) — not an impression.
2. Describe the proposed change, the alternatives, and the trade-offs (security, performance,
   reliability, cost, maintenance).
3. Identify affected source, configuration, tests, and **every affected document** using § 2.
4. Classify it: **low-risk** (proceed) or **material** (owner approval required first). Material means
   product scope, core architecture, security boundaries, data retention, deployment strategy, or a
   major dependency.
5. For material changes: record an ADR with status **Proposed** and ask. Do not implement the
   dependent code while the decision is open.
6. On approval: set the ADR to **Accepted**, then update every affected authoritative document and
   every restatement **in the same change set**.
7. Update `.agent-state/CURRENT.md` if the milestone or verified state changed.
8. Run the documentation checks in § 7 and record the actual results.
9. Review `git diff` and produce a handoff per `AGENTS.md` § Required handoff.
10. **Do not commit or push** unless the owner explicitly asks.

---

## 7. Documentation validation

There is **no CI**, so nothing runs automatically. There **is** an automated documentation validator — [`../tools/validate-docs.ps1`](../tools/validate-docs.ps1) — which must be run manually. It is not a CI job and it does not test application behaviour.

The checks it automates:

| Check | How | When |
|---|---|---|
| Internal link integrity | Resolve every relative Markdown link against the filesystem; report broken targets | After any doc change |
| Repo-fact freshness | `git rev-parse HEAD` vs the commit in `CURRENT.md` | After any doc change |
| Lifecycle consistency | Confirm the transition set is identical in `SPEC.md`, `ARCHITECTURE.md` § 5, `PROJECT_CONTEXT.md` § 5, and `API_CONTRACTS.md` | After any lifecycle change |
| Terminology consistency | Confirm task states, endpoint paths, and header names match across documents | After any contract change |
| Diagram validity | Mermaid blocks must parse; text and diagrams must agree | After editing any `mermaid` block |
| Absence of unsupported claims | Grep for "implemented", "passing", "measured", "verified", "complete" and confirm each is evidenced or qualified | Every audit |
| Decision-status honesty | Confirm no **Proposed** ADR is cited as settled | Every audit |

**Automation:** the checks below are implemented by [`tools/validate-docs.ps1`](../tools/validate-docs.ps1). Run it before handing off any documentation change:

```powershell
powershell -File tools/validate-docs.ps1            # summary: pass/fail only
powershell -File tools/validate-docs.ps1 -Verbose   # list every passing check
```

Exit codes: `0` pass, `1` at least one defect, `2` the validator could not run. It checks relative-link integrity, code-fence balance, Mermaid block syntax, unqualified implementation/performance claims, ADR status validity and index completeness, canonical task-state coverage across restating documents, staleness of the commit recorded in `.agent-state/CURRENT.md`, accidental acquisition of application manifests while documents still claim documentation-only status, and machine-specific absolute paths.

Limits worth knowing, so it is not over-trusted:

- It validates **prose consistency, not correctness of engineering judgement**. Passing means the documents do not contradict themselves; it says nothing about whether the architecture is right.
- The lifecycle check confirms every restating document mentions the canonical state set. It does **not** prove the transition *edges* are identical — that still needs § 7's manual review.
- The claim checker is heuristic. It catches affirmative present/past-tense assertions and is deliberately tuned to avoid flagging the prohibitions this documentation set uses heavily ("exactly-once must not be promised"). A cleverly worded unsupported claim can still slip through; a reviewer must still read the diff.
- It does **not** run Mermaid's own parser. Diagram checks are structural (recognised diagram type, balanced quotes, well-formed `erDiagram` relationships). Tool-verified rendering remains a recommendation for once CI exists.
- It cannot run in CI because **no CI exists**. Wiring it into a pipeline is Milestone 1 work, per `PLAN.md`.

### Known documentation-quality caveats

- **Length varies deliberately.** `API_CONTRACTS.md`, `AGENT_RUNTIME.md`, `DATABASE.md`, and
  `THREAT_MODEL.md` are long because they specify contracts; they are not padded. Do not "balance"
  them by deleting specifics.
- **`graphify-out/` is stale and must not be used as a source of truth** (see § 8).
- **Encoding:** documents use UTF-8 with non-ASCII characters (em dashes, arrows, section signs).
  Some Windows tooling displays these as mojibake; the files themselves are correct. Do not
  "fix" them by replacing characters wholesale.
- **`tools/validate-docs.ps1` is deliberately ASCII-only.** Windows PowerShell 5.1 reads BOM-less
  files as ANSI, which corrupts non-ASCII characters and breaks the parse. Do not "prettify" it with
  arrows or curly quotes, and do not add non-ASCII characters to it.

---

## 8. Known traps

1. **`graphify-out/` is stale.** Built from commit `92b26715`, far behind `HEAD` (`e8a4d71`). Its ~3,369 nodes are
   dominated by third-party skill libraries under `.agents/`, `.claude/`, `.codex/`, `.opencode/`, and
   there is **no first-party source code** to graph. `graphify-out/wiki/index.md`, referenced by
   `CLAUDE.md`, **does not exist**. Do not answer DevFlow AI architecture questions from the graph
   until it is regenerated against first-party sources.
2. **The original v1.0 master briefing was inaccurate.** It listed files
   (`docs/OPERATIONS.md`, `docs/DEPLOYMENT.md`, `.agent-state/` variants, and others) that do not
   exist and never did. `PROJECT_CONTEXT.md` v1.1 replaces it and records the verified tree. Do not
   re-introduce those references.
3. **A prior `.agent-state` snapshot described itself as unverified.** That self-doubt was correct at
   the time but is now resolved; the files are reconciled against a direct inspection.
4. **`.agents/`, `.claude/`, `.codex/`, `.opencode/` are gitignored third-party skill libraries.**
   They are not part of this project's documentation and must not be edited or cited as
   project-owned sources.

---

## 9. Fast lookup

| I need to… | Read |
|---|---|
| Orient myself | [`../PROJECT_CONTEXT.md`](../PROJECT_CONTEXT.md) |
| Know if the repo is real yet | `../PROJECT_CONTEXT.md` § 2, [`../.agent-state/CURRENT.md`](../.agent-state/CURRENT.md) |
| Start work as an agent | [`../AGENTS.md`](../AGENTS.md), then the relevant subject doc |
| Change the task lifecycle | [`../SPEC.md`](../SPEC.md), then § 5 above |
| Add or change an endpoint | [`API_CONTRACTS.md`](API_CONTRACTS.md), [`../SPEC.md`](../SPEC.md) |
| Touch the worker or a model adapter | [`AGENT_RUNTIME.md`](AGENT_RUNTIME.md), [`decisions/0002`](decisions/0002-durable-job-dispatch.md) |
| Add a table or migration | [`DATABASE.md`](DATABASE.md), [`decisions/0008`](decisions/0008-database-identity-and-migrations.md) |
| Add a tool or MCP server | [`THREAT_MODEL.md`](THREAT_MODEL.md), [`decisions/0009`](decisions/0009-tool-execution-sandbox.md) |
| Assess security | [`THREAT_MODEL.md`](THREAT_MODEL.md), then [`SECURITY.md`](SECURITY.md) |
| Write tests | [`TESTING.md`](TESTING.md), [`REQUIREMENTS_TRACEABILITY.md`](REQUIREMENTS_TRACEABILITY.md) |
| Measure performance | [`PERFORMANCE.md`](PERFORMANCE.md) |
| Build UI | [`../Design-system.md`](../Design-system.md) |
| Find an undecided question | [`decisions/README.md`](decisions/README.md) — every **Proposed** row |
| Propose a change | § 6 above |
| Validate my documentation change | Run `powershell -File tools/validate-docs.ps1`, then read § 7 |

## Related documents

- [`../PROJECT_CONTEXT.md`](../PROJECT_CONTEXT.md) — master briefing and navigation
- [`../AGENTS.md`](../AGENTS.md) — universal agent rules and the cross-agent support matrix
- [`../GEMINI.md`](../GEMINI.md) — Gemini CLI adapter
- [`decisions/README.md`](decisions/README.md) — decision records and status vocabulary
- [`REQUIREMENTS_TRACEABILITY.md`](REQUIREMENTS_TRACEABILITY.md) — requirement coverage and evidence obligations
- [`../tools/validate-docs.ps1`](../tools/validate-docs.ps1) — the documentation validator described in § 7
