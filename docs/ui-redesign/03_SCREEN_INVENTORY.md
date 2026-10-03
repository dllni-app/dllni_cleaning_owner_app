# Screen Inventory

The current `main` branch contains 17 worker-facing screen files.

| Screen | Feature | Purpose |
|---|---|---|
| LoginScreen | Auth | Sign in |
| MainScreen | Main | Persistent four-tab shell |
| HomeScreen | Home | Operational overview |
| CalenderScreen | Calendar | Date-based schedule |
| OrdersScreen | Orders | Booking inbox/history |
| OrderDetailsScreen | Orders | Booking lifecycle workspace |
| EmergencySosScreen | Orders | Emergency escalation |
| ProfileScreen | Profile | Account/configuration hub |
| MissionStartLocationScreen | Profile | Worker start point |
| NotificationsScreen | Profile | Notification feed |
| TransactionDetailsScreen | Profile | Transaction details |
| TransactionHistoryScreen | Profile | Transaction history |
| UpdateProfileScreen | Profile | Edit worker data |
| WalletScreen | Profile | Worker stats/finance |
| WorkAreasScreen | Profile | Work zones |
| WorkerReviewsScreen | Profile | Ratings/comments |
| WorkingTimeScreen | Profile | Availability schedule |

## Existing reusable UI families

### Home
- Home app bar
- Statistics row
- Today overview
- Warning container

### Calendar
- Calendar app bar
- Week calendar
- Calendar order card

### Orders
- Order cards
- Accept-order bottom sheet
- Estate/order/payment information cards
- Worker payment summary
- Room assignments
- Warning cards
- Order status/type tabs
- Extension sheets
- Map/verification/mission bodies
- Mission timer/task/services/operational/payment/waiting components
- Mission support and finish controls

### Profile
- Profile app bar
- Section cards
- Reviews/ratings
- Notifications
- Transaction components
- Working-time cards
- Statistics chart

### Core
- Phone inputs
- Pickers
- Cancel-order dialog
- Provisional pricing notice
- Technical support action

## Pen coverage rule
Every screen requires:
- loaded/default state
- loading if remote
- empty when applicable
- error/retry when applicable
- submitting/disabled state for primary actions
- RTL layout

Lifecycle-driven screens require all variants defined in the state matrix.
