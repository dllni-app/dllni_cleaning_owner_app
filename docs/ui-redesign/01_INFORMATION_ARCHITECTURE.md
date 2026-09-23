# Information Architecture

## Primary shell
The authenticated worker experience has four persistent destinations:
1. Home
2. Calendar
3. Orders
4. Profile

The redesign must preserve equivalent tab navigation behavior and the existing support entry point.

## Authentication
### Login
Route: `/login`

Preserve authentication, validation, session/token persistence, FCM-related behavior and navigation to Main. Only the presentation changes.

## Home
Purpose: operational overview.

Prioritize:
- readiness/account state
- today's work
- current/next booking
- concise statistics
- profile/readiness warnings
- notifications
- continuation into relevant order details

## Calendar
Purpose: date-based scheduled work.

Preserve:
- date/week selection
- selected-day state
- booking cards
- empty state
- navigation to order details

## Orders
Purpose: operational booking inbox/history.

Presentation may visually group orders into:
- Needs action
- Upcoming / accepted
- Active
- Completed / closed

These are presentation groupings only and must map to existing filters/statuses.

## Order Details
This is the primary operational workspace. Preserve:
- new order review
- accept/reject
- accepted/waiting team
- start travel
- traveling
- arrival
- customer/start verification
- worker start confirmation
- waiting for remaining workers
- in-progress mission
- extension requests
- customer completion waiting
- disputes
- completed/cancelled states
- multi-day/session execution
- SOS/support
- payment/worker summary where currently exposed
- room assignments and operational details

Use one consistent visual shell with state-specific sections and sticky primary actions.

## Profile
Keep access to:
- edit profile
- work areas
- mission start location
- working time
- wallet/statistics
- reviews
- technical support
- account enable/disable
- logout
- profile completeness indicators

Existing activation prerequisite for mission start location remains authoritative.

## Secondary screens
The current codebase includes:
- Emergency SOS
- Mission Start Location
- Notifications
- Transaction Details
- Transaction History
- Update Profile
- Wallet
- Work Areas
- Worker Reviews
- Working Time

All must be represented in Pen even when reached through direct Material routes.

## Navigation rules
- Preserve destinations and action meaning.
- Do not introduce new business flows just for visual reasons.
- Notification/deep-link navigation must still resolve to the correct order/state.
- Persistent tabs should preserve state as current behavior expects.
- RTL is first-class and directional spacing must be used.
