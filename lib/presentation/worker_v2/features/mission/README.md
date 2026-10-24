# S06 Mission feature — V2 fixture implementation

Public integration entry: `module.dart` (`MissionModule`). Depends only on the
published `contracts/{common,models,requests,navigation,ports}.dart` and S01
`design_system/design_system.dart`. Root S00 supplies `WorkerSessionContext`,
canonical `WorkScope`, `MissionPort`, `WorkerRuntimePort`, `onRoute`, optional
authorized visit scopes from an authenticated server result, and language code.
No legacy widgets, global router, DI, backend calls, device APIs or native
subscriptions are used by this feature.

`MissionModule` reads the exact booking/visit using the applicable V2 port;
inventory and decisions are separately scope-checked. Scope switching discards
all content, revealable codes, draft and pending responses. Read errors and
command outcomes retain typed semantics. Current permission, execution owner,
execution capability, runtime identity, online state and freshness jointly
guard each operational command. A submitted command never optimistically
changes the mission lifecycle; the port is re-read, including after an uncertain
outcome. Validation rejects retain the in-memory reason/note draft. No offline
operational mutations are queued.

Fixture-tested UI coverage is specified under
`test/worker_rebuild/features/mission/mission_module_test.dart`: legacy and
session scopes, authenticated sibling selection, stale response isolation,
supervisor-disabled execution with attendance/SOS independence, explicit
customer code reveal, unsynced checklist, scoped special-service IDs, equipment
reservation IDs, extension family IDs and exact amounts (including zero),
duplicate submission, unknown outcome reconciliation, missing extension family,
revocation, stale/offline errors, and narrow RTL with enlarged text. Fixtures
are artificial and contain no genuine customer data or access codes.

## Frozen V2 projection gaps

The published `MissionView` has no booking label, visit sequence/list, room
identity or time intervals, peer readiness/roles, custody warnings, persisted
task status, authorized customer decision timeline, or signed original price.
Those details are not synthesized from room counts, times, booking kind or
assignment count. An optional list of already-authorized `WorkScope`s can render
visit choices, but every selected scope still requires a new authorized read.

The V2 `CompletionReportCommand` requires stable names for legacy checklist
snapshot items, while `MissionView.ownServices` and `.ownRooms` contain display
labels only. Therefore legacy completion remains disabled in S06 to prevent
false or lost checklist data; session completion sends the supported optional
message with no fake legacy arrays. The price-proposal composer also remains
read-only because the mission projection provides neither authoritative
currency nor the original/proposed pricing context. Without a reliable
decision actor, pending status and record family, extension decisions remain
read-only. The registered S08 module owns the actual SOS/support screens and
S00 owns route integration.

## Handoff / tool lease

Source implementation is fixture-driven and is not evidence of live server
availability. S00 currently reserves shared Dart/Flutter commands; run the
following only with an actual S00 Flutter lease:

```
flutter analyze lib/presentation/worker_v2/features/mission test/worker_rebuild/features/mission
flutter test test/worker_rebuild/features/mission/mission_module_test.dart
```

Then request independent R00 code and scenario review for WR-F06; S00 retains
ownership of routing, integration, and feature gate issuance. Live acceptance
also depends on WR-B, WR-D, WR-I and S09 evidence.
