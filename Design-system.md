# DevFlow AI Design System

**Status:** Initial direction for the MVP. **No design assets, token files, or theme configuration currently exist in this repository** — this document is the only source, and its values are provisional until applied and reviewed in a running app. Do not refer to "existing" design assets or an "existing" theme: there are none. Use shadcn/ui as the component foundation; do not introduce a second component system without a clear reason.

## Product experience
DevFlow AI is a developer-focused workflow console. The UI should feel precise, fast, calm, information-dense without clutter, and trustworthy during long-running operations. Status and control should be more prominent than decoration.

## Visual tokens
Starter tokens. Treat as provisional until applied and reviewed in the app. **Several semantic tokens have no value yet** — see the note below the table.

| Token | Value | Usage |
|---|---|---|
| Primary | `#1A1A1A` | Main text, primary controls |
| Accent | `#FF5C35` | Primary emphasis, active indicators, selected actions |
| Background | `#FAFAFA` | Main light surface |
| Surface | `#FFFFFF` | Cards, panels, menus |
| Border | `#E5E7EB` | Dividers and component boundaries |
| Muted text | `#6B7280` | Secondary labels and metadata |
| Success | Semantic token | Completed/verified states; pair with text/icon |
| Warning | Semantic token | Approval required or degraded states |
| Danger | Semantic token | Failed/destructive actions |
| Info | Semantic token | Neutral progress and informational notices |

Define light/dark tokens through CSS variables compatible with shadcn/ui. Do not hardcode status colors throughout components. Check text/background contrast; color alone must not communicate task state.

> **Incomplete — do not treat this table as a finished palette.** Only Primary, Accent, Background, Surface, Border, and Muted text have values. Undefined and required before a coherent theme can be built: **Success, Warning, Danger, and Info values** (currently the placeholder text "Semantic token"); **every dark-mode value**, even though dark tokens are mandated above; the remaining shadcn slots (`secondary`, `muted` background, `destructive`, `ring`, `input`, `popover`, and all `*-foreground` variants); status colors for each of the seven lifecycle states; and the concrete decision of whether variables are stored as hex, as `H S L` triplets, or as `oklch`, and whether this targets Tailwind v3 config or v4 `@theme`. Also note that `Primary` here is a near-black **text** color while `Accent` carries the "primary emphasis" role — that inverts common shadcn naming, so the mapping must be written down deliberately rather than assumed. Record these as a design-token ADR before implementing the theme. The generic third-party design-system skills under the gitignored `.agents`/`.claude`/`.opencode` trees supply their own palettes and radius scales that **contradict** this brand; they may supply mechanics, never design authority.

## Typography
- Typeface: Inter or a system-compatible sans-serif fallback.
- Headings: weight 600.
- Body: weight 400, default 16px where density permits.
- Use a clear hierarchy for page title, section title, body, labels, helper text, and code/log output.
- Use tabular numerals for durations, counts, and metrics where supported.
- Code and agent logs should use a legible monospace font and preserve whitespace.

## Spacing and shape
- Base spacing unit: 4px.
- Use a consistent 4px-based spacing scale (4, 8, 12, 16, 24, 32, 48, 64px).
- Prefer clear alignment and restrained card nesting.
- Use consistent radius tokens; reserve larger radii for major containers and dialogs.
- Use subtle shadows only to communicate elevation, not as decoration.
- Keep dense task tables readable and allow horizontal overflow only where unavoidable.

## Components and states
Use shadcn/ui primitives where applicable: Button, Input, Textarea, Select, Dropdown Menu, Dialog, Alert Dialog, Tooltip, Tabs, Badge, Card, Table, Skeleton, Toast/Sonner, Progress, Separator, and accessible navigation components.

Every async workflow surface should account for:
- idle/empty
- loading/skeleton
- running/progress
- needs approval
- success/completed
- blocked
- failed (terminal — see note)
- cancelled
- disconnected/reconnecting

**Two corrections to this list, both resolved against the authoritative documents:**

1. **"permission denied" is deliberately not a distinct state.** `docs/API_CONTRACTS.md` §4.6 makes a resource outside the caller's authorization boundary indistinguishable from a nonexistent one (a uniform `not_found`), on purpose, to prevent enumeration. A distinct "permission denied" surface is therefore **unreachable** and, if built, would leak the very distinction the API refuses to reveal. Render the `not_found` response as an ordinary not-found state. Do not attempt to infer authorization failures from response shape.
2. **`failed` is terminal, not retryable.** `SPEC.md` makes `failed` a terminal state, and no retry endpoint exists — re-running work means a **new task or a new explicit attempt**, never reopening a terminal task. So do not render a bare "Retry" control on a `failed` task that would call a nonexistent endpoint. If a retry affordance is wanted, it must be specified as a new-task/new-attempt flow first; that is recorded as an open decision in `docs/API_CONTRACTS.md` §10 row 15.

Define semantic variants for buttons (default, secondary, outline, ghost, destructive) and statuses (queued, running, needs approval, completed, failed, cancelled, blocked). Avoid relying on color alone; include text and/or icon.

## Motion and perceived performance
- Keep common interaction feedback immediate.
- Prefer CSS transforms and opacity for transitions.
- Use short, purposeful transitions; avoid animating layout-heavy properties in high-frequency views.
- Respect `prefers-reduced-motion`.
- Do not animate every progress event or rerender the full page for every streamed token/log line.
- Batch/throttle visual updates when streams are noisy.
- Avoid excessive blur, oversized animated gradients, and continuously moving backgrounds that compete with task information.
- Use skeletons for expected loading and explicit retry/reconnect affordances for failures.

## Layout and responsive behavior
- Desktop: persistent navigation, clear task list/detail hierarchy, readable event/log panel.
- Tablet: collapsible navigation and adaptive panels.
- Mobile: prioritize task state, approvals, and core task actions; move secondary metadata into expandable sections.
- Avoid fixed widths that cause viewport overflow.
- Keep focus visible and keyboard navigation predictable.

## Accessibility
- Target WCAG 2.2 AA where practical.
- Use semantic HTML, labels, accessible names, logical heading order, visible focus, keyboard-operable controls, and sufficient contrast.
- Announce meaningful asynchronous state changes without flooding screen readers with every progress token.
- Support reduced motion and zoom.
- Confirm dialogs identify the action and consequence; destructive actions require clear confirmation where appropriate.

## Performance constraints
- Prefer Server Components for static/initial content; use Client Components where interactivity requires them.
- Lazy-load expensive editors/graph visualizations.
- Avoid unnecessary client dependencies and duplicated state.
- Use stable keys and targeted state updates.
- Measure bundle size, Core Web Vitals, and interaction responsiveness before and after major UI changes.

## Implementation rules
- Define tokens as CSS variables and map them into Tailwind/shadcn theme conventions. **There is no existing theme or Tailwind configuration to reuse** — it does not exist yet and must be created.
- Do not create a second, competing token system, and do not let a third-party skill's palette override this document's brand values.
- Avoid arbitrary one-off colors, spacing, radii, and motion values.
