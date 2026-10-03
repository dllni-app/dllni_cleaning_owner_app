# Screen State Matrix

## Shared remote-data states
- initial loading
- loaded
- empty
- recoverable error + retry
- submitting/disabled primary action
- non-blocking refresh where current behavior supports it
- session-expired behavior

## Login
- idle
- submitting
- validation errors
- authentication error
- success transition

## Home
- loading
- today/current booking
- no current booking
- incomplete-profile/readiness warning
- unread notifications
- realtime refresh

## Calendar
- date with bookings
- empty date
- loading
- error
- dense day

## Orders
- loading
- populated
- empty per filter
- loading more where applicable
- realtime update
- new dedicated-order prompt

## Order Details — authoritative UI states
The existing `OrderLifecyclePolicy` defines:
1. `newOrder`
2. `acceptedWaitingTeam`
3. `readyToStartTravel`
4. `traveling`
5. `awaitingCustomerCode`
6. `awaitingWorkerStartConfirmation`
7. `startApprovedWaitingTeam`
8. `inProgress`
9. `extensionPendingWorkerDecision`
10. `awaitingCustomerCompletion`
11. `underDispute`
12. `completed`
13. `cancelled`
14. `unknown`

### newOrder
Show only data allowed before acceptance. Accept/Reject only when current policy permits.

### acceptedWaitingTeam
Show successful acceptance and team progress. Never show an early start action.

### readyToStartTravel
Primary action: Start Travel, only when current policy permits.

### traveling
Map/location-first layout. Arrival action only when permitted.

### awaitingCustomerCode
Verification-focused waiting presentation.

### awaitingWorkerStartConfirmation
Clearly show that the worker must confirm start.

### startApprovedWaitingTeam
Do not show duplicate start. Show that this worker is done and other workers are pending.

### inProgress
Mission workspace: tasks/services/rooms/operational details, support/SOS and valid completion action.

### extensionPendingWorkerDecision
Extension request is the dominant pending decision.

### awaitingCustomerCompletion
Waiting state. Do not re-show worker completion action.

### underDispute
Clearly distinct review/dispute state with only currently allowed actions.

### completed / cancelled
Read-only final summary.

### unknown
Safe fallback with refresh/back; never invent lifecycle actions.

## Multi-day/session variants
Also design:
- schedule loading
- schedule error + retry
- selected session
- next session
- active session
- completed session
- future session
- session updated by realtime

## Profile
- loading
- complete/incomplete profile
- active/inactive account
- activation requiring mission start location
- update success/failure

## Wallet / transactions / reviews / notifications
- loading
- populated
- empty
- error/retry
- loading more if existing implementation paginates
