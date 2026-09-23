# Dllni Cleaning Worker App — UI Redesign Contract

This directory is the source of truth for the UI-only redesign of the Flutter worker application.

## Objective
Redesign the UI/UX without changing backend integration or business behavior.

## Preserve
- API endpoints, request/response contracts and parsing.
- BLoCs, repositories, use cases, services and server-authoritative state.
- Authentication/session behavior.
- Booking lifecycle and worker assignment rules.
- Multi-worker and multi-day/session behavior.
- Realtime/Pusher/FCM behavior.
- Location tracking and mission start location rules.
- SOS, extension, completion and dispute workflows.
- Financial calculations and worker values.

## May change
- Layout and information hierarchy.
- Typography, spacing, cards, controls and navigation presentation.
- Loading/empty/error/submitting states.
- Presentation-only widget composition.
- Accessibility, RTL behavior and responsive behavior.
- Motion/micro-interactions that do not alter business state.

## Sources of truth
1. Existing Flutter code on `main`: behavioral source of truth.
2. Existing backend contracts: data source of truth.
3. Approved Pen design: visual source of truth.
4. Flutter presentation implementation after approval.

## Documents
- [Information Architecture](01_INFORMATION_ARCHITECTURE.md)
- [User Flows](02_USER_FLOWS.md)
- [Screen Inventory](03_SCREEN_INVENTORY.md)
- [Screen State Matrix](04_SCREEN_STATE_MATRIX.md)
- [Design System](05_DESIGN_SYSTEM.md)
- [Component Specifications](06_COMPONENT_SPECIFICATIONS.md)
- [Pen Redesign Brief](07_PEN_REDESIGN_BRIEF.md)
- [Flutter Implementation Mapping](08_FLUTTER_IMPLEMENTATION_MAPPING.md)
- [Acceptance Checklist](09_ACCEPTANCE_CHECKLIST.md)

## Recommended sequence
`code audit → UX map → design system → 3 representative screens → approval → all Pen screens/states → Flutter UI implementation → regression verification`

Representative Pen screens:
1. Home
2. Orders
3. Order Details — in progress
