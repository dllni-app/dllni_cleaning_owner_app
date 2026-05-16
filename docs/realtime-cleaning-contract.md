# Cleaning realtime contract (owner app)

This contract captures the realtime names and payloads consumed by the owner app so it stays in sync with backend and user app.

## Transport and auth

- Transport: Pusher Channels.
- Private channel auth endpoint: `POST /broadcasting/auth`.
- Required headers: `Accept: application/json`, `Authorization: Bearer <token>`.

## Channels

- Booking channel: `private-cleaning-booking.{bookingId}`
- Worker channel: `private-cleaning-worker.{workerId}`

## Supported event names

- `ArrivalVerified`
- `CompletionDecisionMade`
- `CleaningBookingTrackingUpdated`
- `WorkerArrived`
- `SecurityCodeIssued`
- `cleaning_order.awaiting_start_verification`
- `cleaning_order.security_code_issued`
- `cleaning_order.awaiting_customer_completion`
- `ServiceExtensionRequested`
- `WorkerLocationUpdated`

## Payload requirements

- Booking id fallback chain:
  - `tracking.cleaningBookingId`
  - `tracking.bookingId`
  - `tracking.id`
  - `cleaningBookingId`
  - `bookingId`
  - `id`
- Service extension:
  - warning id: `warningId` or `warning_id`
  - booking id: `cleaningBookingId` or `bookingId`
  - requested minutes: `requestedMinutes` or `requested_minutes`
