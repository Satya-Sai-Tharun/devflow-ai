# DevFlow AI Design System

**Status:** Initial direction for the MVP. Reconcile tokens with existing design assets before changing code. Use shadcn/ui as the component foundation; do not introduce a second component system without a clear reason.

## Product experience
DevFlow AI is a developer-focused workflow console. The UI should feel precise, fast, calm, information-dense without clutter, and trustworthy during long-running operations. Status and control should be more prominent than decoration.

## Visual tokens
Starter tokens from the project reference; treat as provisional until applied and reviewed in the app.

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
- failed/retryable
- cancelled
- disconnected/reconnecting
- permission denied

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
- Define tokens as CSS variables and map them into Tailwind/shadcn theme conventions.
- Reuse existing theme/configuration before generating new configuration.
- Do not replace the existing design system or UI/UX skill files wholesale.
- Avoid arbitrary one-off colors, spacing, radii, and motion values.
