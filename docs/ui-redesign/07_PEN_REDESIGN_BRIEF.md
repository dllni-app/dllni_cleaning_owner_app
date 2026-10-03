# Pen Redesign Brief

## Objective
Create a complete editable Pen design for the Dllni Cleaning Worker Flutter application.

The code on `main` is the behavioral source of truth. The approved Pen file becomes the visual source of truth.

## Non-negotiable
Do not change:
- API behavior
- booking lifecycle/business rules
- authentication/session behavior
- worker acceptance rules
- multi-worker synchronization
- realtime behavior
- location logic
- multi-day/session semantics
- SOS behavior
- financial calculations

## Pen document structure
```
00 Cover / Notes
01 Foundations
02 Components
03 Auth
04 Home
05 Calendar
06 Orders
07 Order Details — Lifecycle
08 Order Details — Multi-day
09 SOS
10 Notifications
11 Profile
12 Wallet & Transactions
13 Work Areas
14 Mission Start Location
15 Working Time
16 Reviews
17 Update Profile
18 States & Edge Cases
```

## First checkpoint
Design and approve these first:
1. Home — loaded/current work
2. Orders — mixed actionable/upcoming list
3. Order Details — inProgress

They must establish:
- final visual identity
- Arabic RTL
- typography
- navigation
- cards
- status language
- sticky actions
- dense operational information

Then extend the same system to every screen/state.

## Developer annotations
Every interactive Pen element should document:
- action name
- existing Flutter event/use case/destination
- visibility condition
- loading/disabled behavior
- resulting navigation/state

Example:
```
Component: StartTravelButton
Visibility: OrderLifecyclePolicy.canStartTravel(order)
Behavior: existing start-travel flow
Do not change: time-window validation
```

## Code areas to inspect
- lib/features/main
- lib/features/home
- lib/features/calender
- lib/features/orders
- lib/features/profile
- lib/core/realtime
- lib/core/location
- lib/core/notifications
- lib/generated/app_routes.g.dart

## Quality bar
- production-ready visual design, not wireframes
- understandable to client and developers
- Arabic UI copy where possible
- no backend jargon exposed to end users
- consistent reusable components
- edge states designed explicitly
- editable Pen layers/components, not screenshots as final output
