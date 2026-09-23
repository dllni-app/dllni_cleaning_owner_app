# Component Specifications

## App shell
### WorkerBottomNavigation
Tabs: Home, Calendar, Orders, Profile.
Support selected/unselected states, safe area and badges only when backed by existing data.

### ScreenTopBar
Variants:
- root
- child/back
- notification action
- optional secondary action

## Status
### StatusChip
Semantic state + Arabic label + optional icon.

### LifecycleBanner
Title, explanation and optional progress for waiting/verification/dispute/final states.

### TeamProgress
Accepted / required / pending counts from authoritative data only.

## Orders
### OrderSummaryCard
Variants:
- available/new
- accepted/upcoming
- active
- completed
- cancelled

### OrderFilter
Presentation-only mapping to current filter/status behavior.

### OrderHeader
Booking reference, status, schedule, service summary.

## Mission
### StickyActionBar
One primary action + optional secondary action.
Visibility comes from existing lifecycle policy.

### MissionProgressCard
Travel → arrival → verification → start → execution → completion.

### MissionTimer
Existing/server-derived timing only.

### TaskCard / RoomAssignments / OperationalDetails
Map existing assigned data without introducing new workflow logic.

### WorkerEarningsSummary
Only values already provided/calculated by the current system.

### CustomerWaitingCard
Explicitly communicates that no worker action is currently required.

### ExtensionDecisionSheet
Request summary, duration/value if available, accept/reject, busy state.

### CompletionSheet
Keep existing completion confirmation semantics.

## Map/location
### MissionMapPanel
Map/route context, destination, travel status, arrival action when allowed.

### LocationErrorState
Presentation only; current location permission/reporting logic remains unchanged.

## Home
### TodayOverview
Current/next job + fast continuation.
### WorkerStats
Concise metrics.
### ReadinessWarning
Existing profile/availability blockers.

## Calendar
### WeekStrip
Selected/today states and work indicator where data exists.
### CalendarBookingCard
Compact order summary.

## Profile
### ProfileHeader
Identity, completeness, active/inactive context.
### SettingsRow
Reusable profile destination row.
### AccountActivationCard
Preserve existing activation prerequisite.
### CompletenessIndicator
Uses existing completeness rules only.

## Finance
- WalletSummary
- FinancialMetric
- TransactionRow
- TransactionFilter
- TransactionDetailSection

## Notifications
### NotificationItem
Read/unread when supported, time, category and existing navigation.

## Shared feedback
- Skeleton
- EmptyState
- ErrorState
- InlineError
- LoadingButton
- SuccessFeedback
