# Performance Budgets and Measurement

## Objective
Make DevFlow AI responsive without conflating web/API latency with model or tool execution time.

## Initial targets
| Metric | Target |
|---|---:|
| Lightweight/cached API read p95 | < 100 ms |
| Database-backed API read p95 | < 200 ms |
| Task submission p95 | < 200 ms |
| INP | ≤ 200 ms |
| LCP | ≤ 2.5 s |
| UI animation | Aim for 60 FPS |

These are engineering budgets, not claims of current performance.

## Required timing breakdown
Capture:
- API server processing time.
- Database query and pool wait time.
- Queue dispatch and queue wait.
- Worker startup and graph stage durations.
- LLM provider latency.
- Tool/MCP latency.
- Verification duration.
- Total end-to-end task duration.

## Backend tactics
- Return promptly after durable task acceptance and dispatch intent.
- Execute long-running graphs in a worker.
- Use async I/O correctly; isolate CPU-heavy work.
- Bound worker concurrency, timeouts, retries, and output sizes.
- Use connection pools and query indexes based on evidence.
- Cache only when invalidation is explicit.
- Trace slow paths and monitor queue depth, failures, and pool saturation.

## Frontend tactics
- Prefer Server Components for static content.
- Lazy-load expensive editors and visualizations.
- Keep client bundles small and avoid duplicate state.
- Batch noisy SSE events and update only affected components.
- Use skeletons and immediate action feedback.
- Prefer transform/opacity animations and respect reduced motion.
- Avoid expensive effects on frequently updated panels.

## Benchmark protocol
Record runtime, OS, hardware, dependency versions, workload, concurrency, warm/cold status, duration, percentiles, and command. Compare results before and after a change. Report p50/p95/p99 and error rates. Test a representative workload; do not use a single local request as proof of production performance.
