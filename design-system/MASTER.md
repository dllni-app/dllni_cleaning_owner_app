# Dllni Cleaning Worker App Design System

Status: authoritative for new `v2` cleaning operations. Generated from the existing UI as a documented `ui-ux-pro-max` fallback because the optional Python search runner is unavailable.

## Foundations

- Arabic-first RTL with directional spacing/alignment and localized date, time, currency, and semantic order.
- Cairo type; layouts must survive 200% text scale even while the legacy app-wide 1.2 clamp is removed separately.
- Primary `#1E2A7B`, secondary `#6C63FF`, operational accent `#2EC4B6`, page `#F3F4F6`, surface `#FFFFFF`, text `#1F2937`, muted `#6B7280`, border `#E5E7EB`, danger `#D92341`, success `#15803D`, warning text `#8A5A12` on `#FFF7E8`.
- Normal text contrast at least 4.5:1. Always pair status color with an icon and explicit label.
- Minimum target 48x48dp; one primary action; destructive decisions require explicit copy and confirmation.
- Use 8/12/16/20/24dp spacing, 12-16dp card radius, safe areas, wrapping action rows, and reduced-motion-safe transitions.

## Operational components

- `MissionOperationalActionsCard`: a single state-aware surface for open-time decisions, material receipt, special-service execution, equipment handover/return, and recurring-change approval.
- Decision bar: accept/reject with busy lock, localized result, and a reason field when rejection affects the customer.
- Live meter: server-anchored, one-second value-only refresh, stable/tabular digits.
- Status card: icon + text + timestamp + recovery action; no color-only meaning.
- Equipment/material acknowledgements are explicit and idempotent.

## Responsive and accessibility contract

- Validate 375px, large phone, tablet and landscape, safe areas, keyboard, light/dark schemes, and 200% text scale.
- All operational actions have localized semantic labels, 48dp targets, predictable RTL traversal, and visible focus.
- Preserve mission detail/scroll state after external notification links and returning from dialogs.
- Disable duplicate network actions; keep rejection/unable reasons after failures; announce success or actionable recovery.

## Page overrides

- [Open-time decisions](pages/open-time.md)
- [Recurring approvals](pages/recurring.md)
- [Special services, materials, and equipment](pages/operations.md)

