# Flutter Refactor Plan - Cleaning Owner App

## 1. Purpose

This document is a planning-only refactor report for `dllni_cleaning_owner_app`.

The goal is to improve maintainability, readability, BLoC usage, widget structure, and separation of responsibilities without changing business logic, API contracts, routes, models, translations, realtime behavior, or user flows.

No production code should be refactored until this plan is reviewed and accepted.

## 2. Refactor Safety Rules

- Preserve all current cleaning owner / worker flows.
- Do not rename public routes, generated route names, API models, request fields, response fields, enum values, or translation keys.
- Do not change lifecycle status behavior unless a confirmed bug is found.
- Do not change Pusher channel names or event names.
- Refactor in small PRs grouped by feature.
- Run `dart format .`, `flutter analyze`, and `flutter test` after each implementation PR.
- Prefer extraction and local cleanup before architecture changes.
- Keep backend as the source of truth for booking lifecycle state.

## 3. Current Project Structure Overview

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

## 4. State Management Structure Overview

The app uses BLoC classes per feature:

- `AuthBloc` under auth.
- `HomeBloc` under home.
- `OrdersBloc` under orders.
- `ProfileBloc` under profile.

The `OrdersBloc` is currently the most complex state manager. It coordinates list loading, details loading, accepting orders, rejecting orders, travel, arrival, security code, start work, completion, cancellation, extension requests, availability, location reporting, and realtime hydration.

The current state object for orders has many nullable fields and many separate `BlocStatus` fields. This makes it easy to accidentally trigger unrelated rebuilds or listeners.

## 5. BLoC / Cubit Files Found

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

## 6. Screens and Widgets With High Refactor Value

### 6.1 `OrderDetailsScreen`

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

Target extracted files:

```text
lib/features/orders/view/controllers/order_details_realtime_controller.dart
lib/features/orders/view/controllers/order_details_lifecycle_poller.dart
lib/features/orders/view/controllers/order_details_state_synchronizer.dart
lib/features/orders/view/presenters/order_details_extension_decision_presenter.dart
```

### 6.2 `OrderDetailsMissionBody`

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
lib/features/orders/view/helpers/order_work_timer_mapper.dart
```

The first implementation PR should only extract widgets and keep all logic outputs identical.

### 6.3 `HomeScreen`

File:

```text
lib/features/home/view/screens/home_screen.dart
```

Why it is risky:

- Owns `HomeBloc`, `OrdersBloc`, and `ProfileBloc` lifecycle.
- Owns worker realtime subscription.
- Owns FCM foreground subscription.
- Performs refresh decisions from realtime and push messages.
- Shows incomplete profile prompt.
- Contains tab UI, list pagination trigger, statistics navigation, and refresh logic.

Recommended refactor direction:

- Keep `HomeScreen` as screen root.
- Extract worker realtime/push handling into a controller.
- Extract tab header and orders list into widgets.
- Extract incomplete-profile prompt logic into a presenter/gate.

Target extracted files:

```text
lib/features/home/view/controllers/home_realtime_refresh_controller.dart
lib/features/home/view/widgets/home_orders_tab_selector.dart
lib/features/home/view/widgets/home_orders_list.dart
lib/features/home/view/presenters/incomplete_profile_prompt_presenter.dart
```

### 6.4 `OrdersBloc` and `OrdersState`

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
4. Add tests around current behavior before splitting.
5. Later split into smaller BLoCs only if screens can be safely migrated.

Possible future split:

```text
OrdersListBloc
OrderDetailsBloc
OrderLifecycleBloc
ExtensionRequestsBloc
WorkerAvailabilityBloc
```

Do not perform this split in the first refactor PR.

## 7. BLoC Listener / Consumer Findings

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

## 8. `listenWhen` and `buildWhen` Plan

### 8.1 Existing good patterns to keep

- `OrderDetailsScreen` already has a `listenWhen` filtering BLoC detail/lifecycle fields.
- `OrderDetailsMissionBody` uses `listenWhen` for completion/waiting-customer state.
- `HomeScreen` uses `listenWhen` on profile prompt and `buildWhen` on orders list.

### 8.2 Areas to audit and improve

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

## 9. Code Smells Found

### 9.1 Large stateful widgets

- `OrderDetailsScreen`
- `OrderDetailsMissionBody`
- `HomeScreen`

These mix UI, lifecycle, realtime, timers, dialogs, and navigation.

### 9.2 Large multi-purpose BLoC

- `OrdersBloc` owns too many use cases and status fields.

### 9.3 Mutable nullable state object

- `OrdersState` uses mutable nullable fields rather than immutable final fields.
- This makes equality and rebuild filtering harder.

### 9.4 Side effects inside BLoC

- `OrdersBloc` calls global toast methods directly.
- Cleaner architecture would emit state and let the UI layer decide how to show feedback.
- Do not remove this immediately because current screens may rely on the existing behavior.

### 9.5 UI widgets with domain mapping logic

- Mission task building and work timer calculation currently live in `OrderDetailsMissionBody`.
- Move mapping/calculation into helpers with focused tests.

### 9.6 Realtime subscription duplication risk

- Realtime handling exists in app-level coordinator, home screen, and order details screen.
- This is valid because scopes differ, but duplicated binding/refresh patterns should be normalized behind small controller classes.

### 9.7 Pagination trigger inside item builder

- `HomeScreen` triggers fetching more orders when the item builder sees the loading sentinel index.
- This works but couples data loading to UI building. Prefer a scroll listener or a paginated list component later.

## 10. SOLID Violations and Refactor Direction

### Single Responsibility Principle

Current violations:

- `OrderDetailsScreen`: UI + realtime + polling + dialog + state merge.
- `OrderDetailsMissionBody`: UI + timer + task mapping + completion sheets.
- `HomeScreen`: UI + BLoC creation + realtime + FCM + profile prompt.
- `OrdersBloc`: many feature responsibilities.

Fix direction:

- Extract controllers, presenters, mappers, and small widgets.
- Keep screens responsible for composition.

### Open / Closed Principle

Current risks:

- Status checks are repeated in screens and helpers.
- UI text/status mapping is hardcoded in widgets.

Fix direction:

- Consolidate lifecycle status display into mappers/extensions.
- Use `OrderLifecyclePolicy` and extend it instead of duplicating conditions.

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

## 11. Recommended Refactor Phases

### Phase 0 - Baseline verification

Goal: capture current behavior before refactoring.

Tasks:

1. Run `dart format --set-exit-if-changed .` to identify existing format drift without changing files.
2. Run `flutter analyze`.
3. Run `flutter test`.
4. Save current analyzer/test failures in the PR description before code changes.

Acceptance criteria:

- Current warnings/failures are documented.
- Refactor PRs do not add new failures.

### Phase 1 - Low-risk formatting and dead-code cleanup

Goal: clean obvious issues without behavior changes.

Tasks:

1. Remove unused imports.
2. Remove unused private methods if analyzer confirms they are unused.
3. Replace obvious repeated literals with local constants only where safe.
4. Normalize long lines with `dart format`.

Do not:

- Change route names.
- Change event names.
- Change status strings.
- Change API payloads.

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
9. Move timer calculation/label mapping into `OrderWorkTimerMapper`.

Acceptance criteria:

- UI screenshots before/after are identical.
- Timer remains UI-only and does not auto-complete orders.
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

Acceptance criteria:

- Booking and worker channel listeners still bind/unbind correctly.
- 403 realtime fallback still refetches details.
- Extension rejected dialog still appears once.
- Details refetch still follows lifecycle realtime events.

### Phase 4 - Home screen extraction

Goal: make `HomeScreen` a composition widget.

Tasks:

1. Extract realtime/FCM refresh handling into `HomeRealtimeRefreshController`.
2. Extract `HomeOrdersTabSelector`.
3. Extract `HomeOrdersList`.
4. Extract profile completeness prompt presenter.
5. Move pagination trigger out of item builder if safe.

Acceptance criteria:

- New orders/today orders tabs still work.
- Pull-to-refresh refreshes home/profile/orders.
- FCM foreground messages still refresh data.
- Worker channel realtime still refreshes home data.
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

Acceptance criteria:

- Public events and state fields stay compatible.
- Existing screens do not need large rewrites.
- Tests cover key current behaviors before any future split.

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

## 12. Testing and Verification Checklist

Run after every implementation PR:

```bash
dart format .
flutter analyze
flutter test
```

Manual QA checklist:

- App launches successfully.
- Login still works.
- Home dashboard loads.
- New orders tab loads and paginates.
- Today orders tab loads and paginates.
- Profile incomplete prompt behavior still works.
- Worker realtime events refresh home data.
- Foreground push messages refresh home data.
- Order details opens from all entry points.
- Realtime lifecycle events refetch details.
- Worker-channel events without booking ID are ignored.
- Mission/timer screen renders only for valid work statuses.
- Timer never auto-completes work.
- Manual finish opens confirmation message sheet.
- Finish request moves to waiting customer state.
- Extension prompt appears once.
- Extension accept/reject still refreshes details.
- Start travel, arrive, security code, start work, complete work flows still work.
- SOS / urgent support opens with the correct booking ID.
- Back navigation still works.
- No duplicate snackbars, dialogs, sheets, or navigation actions.

## 13. Suggested PR Breakdown

1. `refactor(owner): extract mission widgets`
2. `refactor(owner): extract mission timer and task mappers`
3. `refactor(owner): extract order details realtime controller`
4. `refactor(owner): extract order details lifecycle poller`
5. `refactor(owner): extract home realtime refresh controller`
6. `refactor(owner): extract home orders tab and list widgets`
7. `refactor(owner): harden bloc listeners and consumers`
8. `refactor(owner): organize orders bloc internals`
9. `test(owner): add lifecycle and mission mapper tests`

## 14. Files to Refactor Carefully

High risk:

```text
lib/features/orders/view/screens/order_details_screen.dart
lib/features/orders/view/widgets/order_details/order_details_mission_body.dart
lib/features/orders/view/manager/bloc/orders_bloc.dart
lib/features/orders/view/manager/bloc/orders_state.dart
lib/features/home/view/screens/home_screen.dart
lib/core/realtime/cleaning_worker_global_prompt_coordinator.dart
lib/app.dart
```

Medium risk:

```text
lib/features/orders/view/widgets/accept_order_bottom_sheet.dart
lib/features/orders/view/widgets/extension_request_action_sheet.dart
lib/features/orders/view/widgets/extension_requests_sheet.dart
lib/features/orders/view/widgets/order_details/order_details_map_body.dart
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

## 15. Non-goals

- No API contract changes.
- No UI redesign.
- No backend changes.
- No route changes.
- No generated route edits by hand.
- No translation key changes.
- No status enum/string changes.
- No large BLoC split in the first refactor PR.

## 16. Final Recommendation

Start with `OrderDetailsMissionBody` extraction because it is large, high-value, and can be refactored with the lowest business risk if behavior is preserved. Then refactor `OrderDetailsScreen` realtime/polling controllers. After that, refactor `HomeScreen`. Leave `OrdersBloc` splitting for later, after tests and smaller extractions reduce risk.
