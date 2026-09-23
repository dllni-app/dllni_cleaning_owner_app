# Flutter Implementation Mapping

Apply this only after Pen approval.

## Rule
Refactor/replace presentation required to match Pen while preserving behavior.

## Auth
Preserve Auth BLoC/use case/repository/data source, token/session handling and notification registration behavior.
Replace only Login presentation.

## Main
Preserve `MainTabNavigation`, tab state, Orders initial-status routing and support action.
Replace visual shell/navigation only if required.

## Home
Preserve fetching, realtime listeners, notification refresh, profile/readiness logic and order navigation.
Replace visual composition.

## Calendar
Preserve selected-date behavior and navigation.
Replace week selector and booking cards visually.

## Orders
Preserve:
- OrdersBloc
- fetching/pagination
- realtime synchronization
- dedicated-order prompt behavior
- OrderLifecyclePolicy
- accept/reject/start-travel behavior

Replace:
- tabs/filter presentation
- cards
- sheets/dialog visuals
- loading/empty/error presentation

## Order Details
Preserve:
- OrderLifecyclePolicy
- OrderDetailsUiState
- server-authoritative refresh
- realtime booking/worker channels
- multi-day schedule loading
- travel/arrival/verification/start/work/completion flow
- extension decisions
- SOS/support
- permission/visibility checks

Recommended:
1. Keep OrderDetailsScreen as orchestration owner initially.
2. Add a new presentation shell matching Pen.
3. Map every OrderDetailsUiState to an approved Pen state.
4. Reuse existing callbacks.
5. Extract visual-only widgets.
6. Keep business decisions out of visual widgets.

## Profile
Preserve:
- ProfileBloc
- completeness helper
- account activation/deactivation logic
- mission start location prerequisite
- session/location cleanup during logout

Replace visual profile/child-screen composition only.

## Presentation adapter
A view model/adapter may format existing data for display but must not:
- call APIs
- mutate business state
- determine lifecycle eligibility
- calculate authoritative pricing
- replace server values

## Lifecycle mapping
Use `OrderLifecyclePolicy.detailsUiStateFor(order)`.
Do not rebuild lifecycle mapping from raw status strings in redesigned widgets.

## RTL
Prefer Directional APIs and start/end terminology. Test mixed Arabic, references, phone numbers and currency.

## Verification
- existing tests stay green
- add widget/golden tests for new reusable presentation components where useful
- regression-test lifecycle action visibility
- test loading/empty/error
- test supported text scale
- test RTL and small-screen overflow
- test multi-worker/multi-day variants
- test notification navigation
- test realtime updates against duplicate dialogs/actions
