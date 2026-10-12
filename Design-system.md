# Design System

**Product:** DevFlow AI  
**Status:** Initial proposal — visual tokens and component rules are provisional until the UI direction is approved.  
**Purpose:** Keep the interface consistent across pages and implementation sessions.

## 1. Design principles

- **Clarity over decoration:** Make task state, risks, approvals, and verification evidence easy to scan.
- **Evidence visible:** Distinguish verified outcomes from pending, skipped, blocked, or failed work.
- **Calm technical interface:** Use restrained surfaces and color; reserve strong accents for actions and meaningful states.
- **Accessible by default:** Maintain readable contrast, keyboard navigation, visible focus, and semantic controls.
- **Consistent behavior:** Reuse components and tokens rather than styling each screen independently.

## 2. Color palette

The colors below adapt the starter palette shown in the supplied reference. They are a starting point, not yet accessibility-audited or brand-approved.

| Token | Hex | Intended use |
|---|---|---|
| `color-primary` | `#1A1A1A` | Primary text, dark surfaces, high-emphasis elements |
| `color-accent` | `#FF5C35` | Primary action emphasis and selected highlights |
| `color-background` | `#FAFAFA` | App/page background |
| `color-surface` | `#FFFFFF` | Cards, dialogs, panels |
| `color-border` | `#E5E5E5` | Dividers, input borders, subtle outlines |
| `color-muted` | `#6B7280` | Secondary text and supporting metadata |
| `color-success` | `#15803D` | Verified success states |
| `color-warning` | `#B45309` | Pending approvals and caution states |
| `color-danger` | `#B91C1C` | Errors, denied actions, failed checks |
| `color-info` | `#1D4ED8` | Informational states and links |

Rules:
- Do not communicate status through color alone; pair color with text or an icon.
- Use the accent for deliberate emphasis, not large blocks of dense text.
- Check text/background contrast before release; adjust tokens if needed.
- Avoid hardcoding raw colors inside individual components when a semantic token exists.

## 3. Typography

**Font family:** Inter, with a system sans-serif fallback. Confirm the chosen font-loading approach against the existing application stack before implementation.

| Style | Suggested size | Weight | Use |
|---|---:|---:|---|
| Page title | 28–32px | 600 | Main page heading |
| Section heading | 20–24px | 600 | Major content groups |
| Subsection heading | 16–18px | 600 | Cards and panels |
| Body | 16px | 400 | Main reading text |
| Supporting text | 14px | 400 | Metadata, descriptions |
| Caption | 12px | 400–500 | Timestamps and compact labels |
| Code/command | 13–14px | 400 | Logs, commands, identifiers |

Use a consistent heading hierarchy. Prefer readable line length and line height; do not use typography alone to communicate state.

## 4. Spacing scale

**Base unit:** 4px. Prefer multiples of the base unit.

| Token | Value |
|---|---:|
| `space-1` | 4px |
| `space-2` | 8px |
| `space-3` | 12px |
| `space-4` | 16px |
| `space-6` | 24px |
| `space-8` | 32px |
| `space-12` | 48px |
| `space-16` | 64px |

Use tighter spacing for related controls and larger spacing between distinct sections. Avoid arbitrary one-off values unless a documented layout constraint requires them.

## 5. Border radius and elevation

| Token | Suggested value | Use |
|---|---:|---|
| `radius-sm` | 4px | Small controls and compact tags |
| `radius-md` | 8px | Inputs, buttons, cards |
| `radius-lg` | 12px | Large cards and dialogs |
| `radius-pill` | 999px | Status chips where appropriate |
| `shadow-sm` | subtle | Raised cards or menus |
| `shadow-md` | moderate | Dialogs and popovers |

Prefer borders over heavy shadows for dense developer tooling. Shadows must not be the only indication of hierarchy.

## 6. Components and states

### Buttons
- **Primary:** Main action in a view; use the accent color with accessible foreground contrast.
- **Secondary:** Lower-emphasis action with neutral surface/border.
- **Destructive:** Explicitly identify destructive intent; require confirmation where policy calls for it.
- States: default, hover, focus-visible, active, disabled, loading.
- Disable duplicate submissions while an operation is in progress and expose progress/status text.

### Inputs and forms
- Provide persistent labels; do not rely on placeholder text as a label.
- Show validation errors next to the relevant field and associate them programmatically.
- Preserve user-entered values after recoverable errors.
- States: default, focus, invalid, disabled, read-only.

### Cards and panels
- Use cards to group a coherent task, agent, run, approval, or verification result.
- Avoid nesting cards without a clear information hierarchy.
- Keep actions and status labels consistently positioned.

### Status badges
Use explicit labels such as `Queued`, `Running`, `Needs approval`, `Passed`, `Failed`, `Skipped`, and `Blocked`. Do not mark a task as passed solely because an agent claims success.

### Logs and code
- Use a monospaced font for commands, tool arguments, identifiers, and logs.
- Make long output selectable and provide wrapping or horizontal scrolling intentionally.
- Distinguish untrusted tool/retrieval content from trusted system status.

### Dialogs and approval prompts
- State the action, scope, relevant risk, and consequences.
- Provide explicit approve and reject/cancel choices.
- Do not preselect approval for consequential actions.

## 7. Icons and imagery

Use one consistent icon library already adopted by the project. Icons should have accessible labels when they convey meaning; decorative icons should be hidden from assistive technology. Do not introduce a second icon library without a clear reason.

## 8. Responsive behavior

Breakpoints are provisional and should be aligned with the actual frontend framework:
- Small: below 640px
- Medium: 640–1023px
- Large: 1024px and above

On narrow screens, stack panels, keep primary actions reachable, avoid clipped dialogs, and preserve access to approval details and test evidence. Use content-driven layouts rather than relying only on device categories.

## 9. Interaction and accessibility rules

- All interactive controls must be keyboard accessible with a visible focus indicator.
- Respect reduced-motion preferences.
- Use semantic HTML and correct heading order.
- Provide accessible names, error messages, and status announcements.
- Confirm destructive or consequential actions.
- Do not use color as the only status signal.
- Test contrast, keyboard-only flows, and narrow viewport layouts before release.

## 10. Implementation rules

1. Inspect the existing UI framework and components before introducing dependencies.
2. Define reusable tokens in the project's established styling mechanism.
3. Prefer existing shared components; do not duplicate a component for a one-off visual variation.
4. Keep component styles scoped and consistent with the current code style.
5. Update this file when the approved palette, typography, component behavior, or responsive rules change.
6. Do not claim accessibility compliance without running the relevant checks.

## 11. Open decisions

- Confirm whether the palette above is accepted as the DevFlow AI brand palette.
- Confirm the actual frontend framework and token implementation format.
- Select and document the icon library.
- Audit color contrast and approve exact responsive breakpoints after the UI stack is confirmed.
