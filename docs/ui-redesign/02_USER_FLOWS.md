# User Flows

## Authentication
`Login → validate → authenticate → persist session → Main`

Design idle, submitting, validation-error and server-error states.

## Main navigation
`Main → Home | Calendar | Orders | Profile`

## New order
`Orders/Home/notification → Order Details(newOrder) → review allowed data → Accept or Reject`

Customer-sensitive information must remain hidden until existing lifecycle rules allow it.

## Multi-worker acceptance
`Accept → acceptedWaitingTeam → team progress → workerAssigned`

Use existing accepted/required/pending worker values. Do not locally decide team completion.

## Travel and arrival
`workerAssigned → Start Travel → traveling → Arrived → awaiting verification`

Keep the existing travel-start timing restriction and existing error handling.

## Start verification
`awaitingStartVerification → customer/code verified → awaitingWorkerStartConfirmation → worker confirms start`

For multi-worker orders, the worker can then wait for remaining workers. The UI must distinguish "your action" from "waiting for others".

## Active mission
`inProgress → execute assigned work → Complete`

Prioritize:
- current mission status/time
- assigned rooms/tasks/services
- materials/operational details
- worker financial summary where currently available
- extension request
- support/SOS
- completion action

## Extension request
`timeExtensionRequested → worker decision → authoritative refresh`

Show additional duration/value only when available from current data. Disable duplicate submission.

## Completion
`worker completes → awaitingCustomerCompletion → customer decision`

Support existing outcomes including accepted completion, extension request, customer note/rejection and dispute/review states.

## Multi-day/session
Support:
- schedule loading/error
- session selection
- next session emphasis
- current/future/completed session states
- existing accept-all/accept-selected behavior where exposed
- session lifecycle using current APIs

## SOS
`relevant booking → Emergency SOS → existing SOS submission`

SOS remains easy to find in operational states, while retaining existing confirmation/safety behavior.

## Notifications
`Notification feed → item → current navigation resolver → target screen/order`

## Profile activation
If mission start location is missing:
`Activate → prompt → Mission Start Location → save → activate`

Cancelling location setup must prevent activation.

## Worker configuration
Profile continues to provide:
- Edit Profile
- Work Areas
- Mission Start Location
- Working Time
- Wallet
- Reviews
- Support
- Logout
