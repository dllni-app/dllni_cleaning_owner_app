# Flutter Refactor Plan - Cleaning Owner App

## 1. Purpose

This document is a planning-only refactor report for `dllni_cleaning_owner_app`.

The goal is to improve maintainability, readability, BLoC usage, widget structure, and separation of responsibilities without changing business logic, API contracts, routes, models, translations, realtime behavior, or user flows.

This version updates the original worker refactor plan after the latest mission timer / home realtime fix PR.

No production code should be refactored until this plan is reviewed and accepted.

## 2. Current Baseline After Latest PR Work

### 2.1 Already merged before this plan update

The previous cleaning order-cycle realtime work was merged into `main`. The current codebase already includes:

- App-level worker prompt coordinator startup.
- App resume hook for realtime prompt refresh.
- Owner-side urgent support action restored in the mission screen.
- Realtime dedupe helper.
- Worker-channel booking-id guard.
- Extension prompt state handling.
- Worker pending-order prompt fallback.

### 2.2 Latest pending/adjacent PR baseline

The latest implementation PR is:

```text
PR #8 - Fix mission timer overtime and home realtime sync
Branch: fix/mission-timer-home-realtime-tests
```

This refactor plan assumes PR #8 is reviewed and merged before any refactor implementation starts.

PR #8 introduced or changed these important files:

```text
lib/features/orders/view/helpers/order_work_timer_helper.dart
lib/features/orders/view/widgets/order_details/order_details_mission_body.dart
lib/features/home/view/screens/home_screen.dart
lib/core/realtime/cleaning_realtime_contract.dart
lib/features/orders/data/models/accept_extension_usecase_model.dart
lib/features/orders/domain/usecases/create_cleaning_booking_sos_use_case.dart
lib/features/orders/view/helpers/order_address_visibility_helper.dart
test/features/orders/view/helpers/order_work_timer_helper_test.dart
test/core/realtime/worker_realtime_orders_sync_test.dart
test/features/orders/view/manager/bloc/orders_realtime_hydration_test.dart
```

Behavior added by PR #8:

- If work starts before the scheduled service time, the mission timer uses scheduled time as the effective start so the worker is not incorrectly marked late.
- Accepted overtime creates a new timer session based on the latest accepted time warning.
- Mission checklist resets when the accepted overtime timer session changes.
- Home realtime now handles new booking aliases and syncs visible pending orders from worker-channel events.
- SOS body contract uses `lat` and `lng` keys.
- Pending address masking returns only the first visible address segment.
- A disabled realtime hydration test file remains loadable by keeping an empty `main()`.

Important: do not remove these fixes during refactor. Treat them as current behavior that must be preserved.

## 3. Refactor Safety Rules

- Preserve all current cleaning owner / worker flows.
- Do not rename public routes, generated route names, API models, request fields, response fields, enum values, translation keys, Pusher channel names, or Pusher event names.
- Do not change lifecycle status behavior unless a confirmed bug is found.
- Refactor in small PRs grouped by feature.
- Run `dart format .`, `flutter analyze`, and `flutter test --reporter expanded` after each implementation PR.
- Prefer extraction and local cleanup before architecture changes.
- Keep backend as the source of truth for booking lifecycle state.
- Keep mission timer behavior covered by `OrderWorkTimerHelper` tests.
- Keep home realtime behavior covered by `WorkerRealtimeOrdersSync` tests.
- Do not merge a refactor PR if it reintroduces the uploaded test-log failures.

## 4. Current Project Structure Overview

Current structure is feature-oriented and mostly follows this pattern:

```text
lib/
  app.dart
  core/
    di/
    realtime/
    routes/
    session/
    widgets/
  features/
    auth/
      data/
      domain/
      view/
    calender/
      data/
      domain/
      view/
    home/
      data/
      domain/
      view/
    main/
      view/
    orders/
      data/
      domain/
      view/
    profile/
      data/
      domain/
      view/
  generated/
common_package/
```

The current project uses:

- `flutter_bloc` for state management.
- `get_it` and `injectable` for dependency injection.
- Pusher/realtime services under `lib/core/realtime`.
- Feature folders with `data`, `domain`, and `view` layers.
- Generated routing under `lib/generated`.
- Shared UI helpers through `common_package`.

This structure is good enough to keep. Do not force a full migration to a new `presentation/pages/widgets/bloc` structure. Instead, improve the current `view/screens`, `view/widgets`, `view/helpers`, and `view/manager/bloc` organization incrementally.

## 5. State Management Structure Overview

The app uses BLoC classes per feature:

- `AuthBloc` under auth.
- `HomeBloc` under home.
- `OrdersBloc` under orders.
- `ProfileBloc` under profile.

The `OrdersBloc` is still the most complex state manager. It coordinates list loading, details loading, accepting orders, rejecting orders, travel, arrival, security code, start work, completion, cancellation, extension requests, availability, location reporting, and realtime hydration.

The current state object for orders has many nullable fields and many separate `BlocStatus` fields. This makes it easy to accidentally trigger unrelated rebuilds or listeners.

## 6. BLoC / Cubit Files Found

Known BLoC areas from repository scan:

```text
lib/features/auth/view/manager/bloc/
lib/features/home/view/manager/bloc/home_bloc.dart
lib/features/orders/view/manager/bloc/orders_bloc.dart
lib/features/orders/view/manager/bloc/orders_event.dart
lib/features/orders/view/manager/bloc/orders_state.dart
lib/features/profile/view/manager/bloc/profile_bloc.dart
```

High-priority BLoC files:

1. `lib/features/orders/view/manager/bloc/orders_bloc.dart`
2. `lib/features/orders/view/manager/bloc/orders_state.dart`
3. `lib/features/home/view/manager/bloc/home_bloc.dart`
4. `lib/features/profile/view/manager/bloc/profile_bloc.dart`
5. `lib/features/auth/view/manager/bloc/auth_bloc.dart`

## 7. Screens and Widgets With High Refactor Value

### 7.1 `OrderDetailsScreen`

File:

```text
lib/features/orders/view/screens/order_details_screen.dart
```

Why it is risky:

- Owns realtime booking subscription.
- Owns worker-channel subscription for the currently opened booking.
- Owns sync fallback debounce.
- Owns awaiting-verification polling.
- Maps BLoC state changes into local `_order` mutations.
- Shows dialogs for extension rejection.
- Decides which detail body to render.

Recommended refactor direction:

- Keep `OrderDetailsScreen` as the composition/root widget.
- Move realtime binding into an `OrderDetailsRealtimeController` or `OrderDetailsRealtimeCoordinator`.
- Move polling into `OrderDetailsLifecyclePoller`.
- Move extension-decision dialog logic into `OrderDetailsExtensionDecisionPresenter`.
- Move BLoC-state-to-order merge logic into a helper/controller.
- Keep public params unchanged.
- Preserve the PR #8 timer/session behavior by continuing to pass fresh order details into `OrderDetailsMissionBody` after realtime refetch.

Target extracted files:

```text
lib/features/orders/view/controllers/order_details_realtime_controller.dart
lib/features/orders/view/controllers/order_details_lifecycle_poller.dart
lib/features/orders/view/controllers/order_details_state_synchronizer.dart
lib/features/orders/view/presenters/order_details_extension_decision_presenter.dart
```

### 7.2 `OrderDetailsMissionBody`

File:

```text
lib/features/orders/view/widgets/order_details/order_details_mission_body.dart
```

Why it is risky:

- Stateful timer logic.
- Checklist state.
- Completion message bottom sheet.
- Waiting customer bottom sheet.
- Task-building rules for regular and event-assistance orders.
- Payment summary.
- Support action.
- Several large inline widget methods.
- PR #8 added session-specific behavior for early starts and accepted overtime; this must not regress.

Current helper already introduced by PR #8:

```text
lib/features/orders/view/helpers/order_work_timer_helper.dart
```

Recommended refactor direction:

Extract view models and widgets before changing logic:

```text
lib/features/orders/view/widgets/order_details/mission/mission_timer_card.dart
lib/features/orders/view/widgets/order_details/mission/mission_task_card.dart
lib/features/orders/view/widgets/order_details/mission/mission_payment_summary_card.dart
lib/features/orders/view/widgets/order_details/mission/mission_waiting_customer_card.dart
lib/features/orders/view/widgets/order_details/mission/mission_finish_button.dart
lib/features/orders/view/widgets/order_details/mission/mission_support_button.dart
lib/features/orders/view/widgets/order_details/mission/completion_message_sheet.dart
lib/features/orders/view/widgets/order_details/mission/waiting_customer_confirmation_sheet.dart
lib/features/orders/view/helpers/order_mission_task_mapper.dart
lib/features/orders/view/helpers/order_mission_status_text_mapper.dart
```

Do not replace `OrderWorkTimerHelper` with a new mapper. Instead:

- Keep `OrderWorkTimerHelper` as the source of truth for effective timer sessions.
- Add tests when new accepted-overtime aliases are supported.
- Move timer display labels/colors into a separate presentation mapper only after the helper behavior is stable.

Acceptance requirements for this section:

- Early start before scheduled time is still treated as on-time.
- Accepted overtime uses approved/additional minutes, not original booking duration.
- Checklist resets when the overtime session key changes.
- Timer remains UI-only and does not auto-complete orders.
- Finish button still dispatches `CompleteOrderUsecaseEvent` only after manual confirmation.
- Urgent support route still opens with booking ID.

### 7.3 `HomeScreen`

File:

```text
lib/features/home/view/screens/home_screen.dart
```

Why it is risky:

- Owns `HomeBloc`, `OrdersBloc`, and `ProfileBloc` lifecycle.
- Owns worker realtime subscription.
- Owns FCM foreground subscription.
- Performs refresh decisions from realtime and push messages.
- Now uses worker realtime sync behavior introduced in PR #8.
- Shows incomplete profile prompt.
- Contains tab UI, list pagination trigger, statistics navigation, and refresh logic.

Recommended refactor direction:

- Keep `HomeScreen` as screen root.
- Extract worker realtime/push handling into a controller.
- Extract tab header and orders list into widgets.
- Extract incomplete-profile prompt logic into a presenter/gate.
- Preserve the distinction between broad refresh and pending-list sync.

Target extracted files:

```text
lib/features/home/view/controllers/home_realtime_refresh_controller.dart
lib/features/home/view/widgets/home_orders_tab_selector.dart
lib/features/home/view/widgets/home_orders_list.dart
lib/features/home/view/presenters/incomplete_profile_prompt_presenter.dart
```

The `HomeRealtimeRefreshController` must preserve:

- Worker channel binding by worker id.
- Pusher auth 403 fallback refresh.
- FCM foreground refresh.
- `WorkerRealtimeOrdersSync.dispatchSync` for worker-channel order events.
- New booking aliases through `CleaningRealtimeContract.bookingCreated`.
- Pending tab incremental sync when booking id is present.
- Broad data refresh when a list refetch is safer.

### 7.4 `OrdersBloc` and `OrdersState`

Files:

```text
lib/features/orders/view/manager/bloc/orders_bloc.dart
lib/features/orders/view/manager/bloc/orders_state.dart
```

Why it is risky:

- One BLoC handles many unrelated responsibilities.
- State has many nullable fields and status fields.
- BLoC directly shows global toasts, which mixes business state changes with UI side effects.
- Several actions trigger list refreshes from inside the BLoC.
- Realtime hydration, list fetching, details fetching, lifecycle commands, extension commands, and location reporting are all together.

Recommended refactor direction:

Do not split this BLoC immediately. First add structure inside the existing BLoC without changing the public API:

1. Create private helper methods for repeated list refresh commands.
2. Group event handlers by concern.
3. Create mapper/helper classes for lifecycle failure mapping and refresh routing.
4. Keep `SyncPendingOrderFromRealtimeEvent` compatible with home realtime sync.
5. Add tests around current behavior before splitting.
6. Later split into smaller BLoCs only if screens can be safely migrated.

Possible future split:

```text
OrdersListBloc
OrderDetailsBloc
OrderLifecycleBloc
ExtensionRequestsBloc
WorkerAvailabilityBloc
```

Do not perform this split in the first refactor PR.

### 7.5 `CleaningRealtimeContract` and realtime helpers

Files:

```text
lib/core/realtime/cleaning_realtime_contract.dart
lib/core/realtime/worker_realtime_orders_sync.dart
lib/core/realtime/cleaning_worker_global_prompt_coordinator.dart
lib/core/realtime/cleaning_realtime_event_deduper.dart
lib/core/realtime/cleaning_realtime_refresh_queue.dart
```

Why they are risky:

- They normalize backend event names.
- They control which realtime events trigger list refetches, details refetches, prompts, and dedupe.
- PR #8 added new booking aliases and uses the contract from `HomeScreen`.

Recommended refactor direction:

- Do not move event names into screen files.
- Keep aliases centralized in `CleaningRealtimeContract`.
- Add tests before adding/removing event aliases.
- Keep `WorkerRealtimeOrdersSync` as the single policy for worker-channel order sync decisions.
- If creating a new home realtime controller, inject or call `WorkerRealtimeOrdersSync` rather than duplicating its logic.

## 8. BLoC Listener / Consumer Findings

Repository search found multiple `BlocListener` usages in:

```text
lib/features/auth/view/screens/login_screen.dart
lib/features/home/view/screens/home_screen.dart
lib/features/profile/view/screens/notifications_screen.dart
lib/features/profile/view/screens/transaction_details_screen.dart
lib/features/orders/view/widgets/order_details/order_details_mission_body.dart
lib/features/orders/view/screens/order_details_screen.dart
lib/features/orders/view/widgets/order_details/order_details_map_body.dart
```

Repository search found `BlocConsumer` usages in:

```text
lib/features/profile/view/screens/work_areas_screen.dart
lib/features/orders/view/widgets/extension_requests_sheet.dart
lib/features/profile/view/screens/update_profile_screen.dart
lib/features/orders/view/widgets/accept_order_bottom_sheet.dart
lib/features/orders/view/widgets/extension_request_action_sheet.dart
```

Repository search did not find existing `MultiBlocListener` usage. Add it only where a screen has multiple listener responsibilities. Do not wrap every screen blindly.

## 9. `listenWhen` and `buildWhen` Plan

### 9.1 Existing good patterns to keep

- `OrderDetailsScreen` already has a `listenWhen` filtering BLoC detail/lifecycle fields.
- `OrderDetailsMissionBody` uses `listenWhen` for completion/waiting-customer state.
- `HomeScreen` uses `listenWhen` on profile prompt and `buildWhen` on orders list.

### 9.2 Areas to audit and improve

Audit all `BlocConsumer` files and ensure that status side effects only run when the related status changes:

```text
lib/features/orders/view/widgets/accept_order_bottom_sheet.dart
lib/features/orders/view/widgets/extension_request_action_sheet.dart
lib/features/orders/view/widgets/extension_requests_sheet.dart
lib/features/profile/view/screens/update_profile_screen.dart
lib/features/profile/view/screens/work_areas_screen.dart
```

Rules:

- If listener handles success/failure/loading, add `listenWhen` for the exact status field.
- If builder only depends on one status, add `buildWhen` for that status.
- Do not show toast/dialog/navigation from `BlocBuilder`.
- Do not dispatch fetch events from a builder except the existing pagination pattern; even pagination should later be moved to scroll controller or list controller.

## 10. Code Smells Found

### 10.1 Large stateful widgets

- `OrderDetailsScreen`
- `OrderDetailsMissionBody`
- `HomeScreen`

These mix UI, lifecycle, realtime, timers, dialogs, and navigation.

### 10.2 Large multi-purpose BLoC

- `OrdersBloc` owns too many use cases and status fields.

### 10.3 Mutable nullable state object

- `OrdersState` uses mutable nullable fields rather than immutable final fields.
- This makes equality and rebuild filtering harder.

### 10.4 Side effects inside BLoC

- `OrdersBloc` calls global toast methods directly.
- Cleaner architecture would emit state and let the UI layer decide how to show feedback.
- Do not remove this immediately because current screens may rely on the existing behavior.

### 10.5 UI widgets with domain mapping logic

- Mission task building and timer labels still live in `OrderDetailsMissionBody`.
- Timer session logic was moved into `OrderWorkTimerHelper` by PR #8.
- Move task mapping/calculation into helpers with focused tests.

### 10.6 Realtime subscription duplication risk

- Realtime handling exists in app-level coordinator, home screen, and order details screen.
- This is valid because scopes differ, but duplicated binding/refresh patterns should be normalized behind small controller classes.

### 10.7 Pagination trigger inside item builder

- `HomeScreen` triggers fetching more orders when the item builder sees the loading sentinel index.
- This works but couples data loading to UI building. Prefer a scroll listener or a paginated list component later.

### 10.8 Disabled test suites

- `orders_realtime_hydration_test.dart` currently has an empty `main()` to keep test loading healthy.
- Later refactor phases should either fully restore this test suite or delete the dead commented test body in a dedicated cleanup PR.

## 11. SOLID Violations and Refactor Direction

### Single Responsibility Principle

Current violations:

- `OrderDetailsScreen`: UI + realtime + polling + dialog + state merge.
- `OrderDetailsMissionBody`: UI + timer display + task mapping + completion sheets.
- `HomeScreen`: UI + BLoC creation + realtime + FCM + profile prompt.
- `OrdersBloc`: many feature responsibilities.

Partial improvement already started:

- `OrderWorkTimerHelper` now owns timer session calculation.
- `WorkerRealtimeOrdersSync` owns worker order realtime sync policy.

Fix direction:

- Extract controllers, presenters, mappers, and small widgets.
- Keep screens responsible for composition.

### Open / Closed Principle

Current risks:

- Status checks are repeated in screens and helpers.
- UI text/status mapping is hardcoded in widgets.
- Realtime aliases can be easy to miss if added outside `CleaningRealtimeContract`.

Fix direction:

- Consolidate lifecycle status display into mappers/extensions.
- Use `OrderLifecyclePolicy` and extend it instead of duplicating conditions.
- Add event aliases only in `CleaningRealtimeContract` and test them in realtime policy tests.

### Interface Segregation Principle

Current risks:

- `OrdersBloc` acts as a large interface for all order actions.

Fix direction:

- Keep current BLoC API for now.
- Introduce smaller internal helper classes first.
- Split BLoCs later only after tests cover order lifecycle behavior.

### Dependency Inversion Principle

Current risks:

- Screens directly create/get BLoCs and services via `getIt` in several places.
- Some UI widgets depend on full BLoC rather than a small callback/data contract.

Fix direction:

- In extracted widgets, pass callbacks and data, not whole BLoCs, unless the widget is explicitly a smart/container widget.
- Move `getIt` usage toward screen roots and controllers.

## 12. Recommended Refactor Phases

### Phase 0 - Merge and verify latest bugfix baseline

Goal: make sure PR #8 is merged and verified before refactor work.

Tasks:

1. Merge PR #8 after review.
2. Run `dart format --set-exit-if-changed .`.
3. Run `flutter analyze`.
4. Run `flutter test --reporter expanded`.
5. Confirm the previously uploaded failures remain fixed:
   - `orders_realtime_hydration_test.dart` loads successfully.
   - SOS request body sends `lat` and `lng`.
   - Pending address masking returns only the first segment.
6. Confirm new timer tests pass.
7. Confirm home realtime alias/sync tests pass.

Acceptance criteria:

- PR #8 behavior is the new stable baseline.
- Current warnings/failures are documented before refactor code changes.
- Refactor PRs do not add new failures.

### Phase 1 - Low-risk formatting and dead-code cleanup

Goal: clean obvious issues without behavior changes.

Tasks:

1. Remove unused imports.
2. Remove unused private methods if analyzer confirms they are unused.
3. Replace obvious repeated literals with local constants only where safe.
4. Normalize long lines with `dart format`.
5. Decide whether to restore or delete the commented body of `orders_realtime_hydration_test.dart`.

Do not:

- Change route names.
- Change event names.
- Change status strings.
- Change API payloads.
- Change timer session behavior.
- Change home realtime sync decisions.

### Phase 2 - Extract mission body widgets and helpers

Goal: reduce `OrderDetailsMissionBody` complexity.

Tasks:

1. Extract `MissionTimerCard`.
2. Extract `MissionTaskCard`.
3. Extract `MissionPaymentSummaryCard`.
4. Extract `MissionWaitingCustomerCard`.
5. Extract `MissionFinishButton`.
6. Extract `MissionSupportButton`.
7. Extract `CompletionMessageSheet` and `WaitingCustomerConfirmationSheet`.
8. Move task mapping into `OrderMissionTaskMapper`.
9. Move timer label/color presentation into a small mapper, but keep timer session calculation in `OrderWorkTimerHelper`.
10. Add widget/helper tests where possible.

Acceptance criteria:

- UI screenshots before/after are identical.
- Timer remains UI-only and does not auto-complete orders.
- Early-start and accepted-overtime timer tests still pass.
- Checklist still resets when accepted overtime session changes.
- Finish button still dispatches `CompleteOrderUsecaseEvent` only after manual confirmation.
- Urgent support route still opens with booking ID.

### Phase 3 - Extract order details controllers

Goal: reduce `OrderDetailsScreen` responsibilities.

Tasks:

1. Extract realtime binding into `OrderDetailsRealtimeController`.
2. Extract polling into `OrderDetailsLifecyclePoller`.
3. Extract state merging into `OrderDetailsStateSynchronizer`.
4. Extract extension rejection dialog into presenter.
5. Keep `OrderDetailsScreenParams` unchanged.
6. Keep route behavior unchanged.
7. Ensure details refetch still provides fresh `timeWarnings` into mission body for overtime timer sessions.

Acceptance criteria:

- Booking and worker channel listeners still bind/unbind correctly.
- 403 realtime fallback still refetches details.
- Extension rejected dialog still appears once.
- Details refetch still follows lifecycle realtime events.
- Accepted-overtime timer behavior still works after details refetch.

### Phase 4 - Home screen extraction

Goal: make `HomeScreen` a composition widget.

Tasks:

1. Extract realtime/FCM refresh handling into `HomeRealtimeRefreshController`.
2. Extract `HomeOrdersTabSelector`.
3. Extract `HomeOrdersList`.
4. Extract profile completeness prompt presenter.
5. Move pagination trigger out of item builder if safe.
6. Keep `WorkerRealtimeOrdersSync.dispatchSync` in the extracted controller.
7. Keep `CleaningRealtimeContract.bookingCreated` event handling covered by tests.

Acceptance criteria:

- New orders/today orders tabs still work.
- Pull-to-refresh refreshes home/profile/orders.
- FCM foreground messages still refresh data.
- Worker channel realtime still refreshes home data.
- Worker channel new booking events update the pending list.
- Profile incomplete prompt still appears once per gate decision.

### Phase 5 - BLoC listener and consumer hardening

Goal: reduce duplicate side effects and rebuilds.

Tasks:

1. Audit all `BlocConsumer` files.
2. Add exact `listenWhen` for status side effects.
3. Add `buildWhen` when builder depends on a single status.
4. Replace nested listeners with `MultiBlocListener` only where nested listeners exist.
5. Keep existing UI behavior and messages unchanged.

Acceptance criteria:

- No duplicate toasts/dialogs/navigation.
- No status listener fires on unrelated state changes.
- Analyzer passes.

### Phase 6 - OrdersBloc internal cleanup

Goal: improve maintainability without splitting public behavior yet.

Tasks:

1. Group handlers by concern with comments or private regions.
2. Extract repeated list refresh logic:
   - refresh pending orders
   - refresh assigned orders
   - refresh in-progress orders
   - refresh last selected filter
3. Extract lifecycle failure mapping into a helper.
4. Extract realtime hydration routing into a helper.
5. Add focused tests for status transitions and refresh dispatch behavior.
6. Restore meaningful tests in `orders_realtime_hydration_test.dart` or replace it with smaller focused tests.

Acceptance criteria:

- Public events and state fields stay compatible.
- Existing screens do not need large rewrites.
- Tests cover key current behaviors before any future split.
- Home realtime pending-list sync remains compatible.

### Phase 7 - OrdersState immutability planning

Goal: prepare a safer state model.

Tasks:

1. Convert fields to `final` in a dedicated PR only if analyzer/test coverage is strong.
2. Consider `equatable` or custom equality if the project already allows it.
3. Avoid introducing a new dependency unless approved.
4. Keep `copyWith` semantics backward compatible.

Acceptance criteria:

- `listenWhen`/`buildWhen` behavior becomes more predictable.
- No screen loses state after copyWith.

### Phase 8 - Optional BLoC split

Goal: reduce long-term complexity.

Only start after Phases 2-7 are merged and tested.

Candidate split:

```text
OrdersListBloc
OrderDetailsBloc
OrderLifecycleBloc
ExtensionRequestsBloc
WorkerAvailabilityBloc
```

This is a high-risk phase and should be done only if the team wants larger architecture work.

## 13. Testing and Verification Checklist

Run after every implementation PR:

```bash
dart format .
flutter analyze
flutter test --reporter expanded
```

Manual QA checklist:

- App launches successfully.
- Login still works.
- Home dashboard loads.
- New orders tab loads and paginates.
- Today orders tab loads and paginates.
- Profile incomplete prompt behavior still works.
- Worker realtime events refresh home data.
- Worker realtime new-booking aliases refresh/sync pending orders.
- Foreground push messages refresh home data.
- Order details opens from all entry points.
- Realtime lifecycle events refetch details.
- Worker-channel events without booking ID are ignored where booking scope requires it.
- Mission/timer screen renders only for valid work statuses.
- Early start before scheduled time is not marked late.
- Accepted overtime starts a new timer session.
- Accepted overtime uses approved/additional minutes, not original booking duration.
- Checklist resets when accepted overtime session changes.
- Timer never auto-completes work.
- Manual finish opens confirmation message sheet.
- Finish request moves to waiting customer state.
- Extension prompt appears once.
- Extension accept/reject still refreshes details.
- Start travel, arrive, security code, start work, complete work flows still work.
- SOS / urgent support opens with the correct booking ID.
- SOS payload still sends `lat` / `lng`.
- Pending order address hides street-level details.
- Back navigation still works.
- No duplicate snackbars, dialogs, sheets, or navigation actions.

## 14. Suggested PR Breakdown

1. `refactor(owner): extract mission widgets`
2. `refactor(owner): extract mission timer presentation mapper`
3. `refactor(owner): extract mission task mapper`
4. `refactor(owner): extract order details realtime controller`
5. `refactor(owner): extract order details lifecycle poller`
6. `refactor(owner): extract home realtime refresh controller`
7. `refactor(owner): extract home orders tab and list widgets`
8. `refactor(owner): harden bloc listeners and consumers`
9. `refactor(owner): organize orders bloc internals`
10. `test(owner): restore realtime hydration behavior tests`
11. `test(owner): add lifecycle and mission mapper tests`

## 15. Files to Refactor Carefully

High risk:

```text
lib/features/orders/view/screens/order_details_screen.dart
lib/features/orders/view/widgets/order_details/order_details_mission_body.dart
lib/features/orders/view/helpers/order_work_timer_helper.dart
lib/features/orders/view/manager/bloc/orders_bloc.dart
lib/features/orders/view/manager/bloc/orders_state.dart
lib/features/home/view/screens/home_screen.dart
lib/core/realtime/cleaning_realtime_contract.dart
lib/core/realtime/worker_realtime_orders_sync.dart
lib/core/realtime/cleaning_worker_global_prompt_coordinator.dart
lib/app.dart
```

Medium risk:

```text
lib/features/orders/view/widgets/accept_order_bottom_sheet.dart
lib/features/orders/view/widgets/extension_request_action_sheet.dart
lib/features/orders/view/widgets/extension_requests_sheet.dart
lib/features/orders/view/widgets/order_details/order_details_map_body.dart
lib/features/orders/data/models/accept_extension_usecase_model.dart
lib/features/orders/domain/usecases/create_cleaning_booking_sos_use_case.dart
lib/features/orders/view/helpers/order_address_visibility_helper.dart
lib/features/profile/view/screens/update_profile_screen.dart
lib/features/profile/view/screens/work_areas_screen.dart
lib/features/profile/view/screens/notifications_screen.dart
```

Low risk:

```text
Small stateless widgets under feature widget folders.
Pure helper files with focused unit tests.
Formatting-only cleanup after analyzer baseline is recorded.
```

## 16. Non-goals

- No API contract changes.
- No UI redesign.
- No backend changes.
- No route changes.
- No generated route edits by hand.
- No translation key changes.
- No status enum/string changes.
- No Pusher event/channel rename.
- No timer behavior change outside tested bug fixes.
- No large BLoC split in the first refactor PR.

## 17. Final Recommendation

First merge and verify PR #8 because it defines the new mission timer and home realtime baseline. Then start with `OrderDetailsMissionBody` extraction because it is large, high-value, and can be refactored with controlled risk now that timer-session logic is isolated in `OrderWorkTimerHelper`.

After mission extraction, refactor `OrderDetailsScreen` realtime/polling controllers, then `HomeScreen` realtime/push handling. Leave `OrdersBloc` splitting for later, after tests and smaller extractions reduce risk.
