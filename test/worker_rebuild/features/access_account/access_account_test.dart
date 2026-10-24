import 'dart:async';

import 'package:flutter/material.dart' hide Page;
import 'package:flutter_test/flutter_test.dart';
import 'package:dllni_cleaninig_owner_app/presentation/worker_v2/contracts/common.dart';
import 'package:dllni_cleaninig_owner_app/presentation/worker_v2/contracts/models.dart';
import 'package:dllni_cleaninig_owner_app/presentation/worker_v2/contracts/navigation.dart';
import 'package:dllni_cleaninig_owner_app/presentation/worker_v2/contracts/requests.dart';
import 'package:dllni_cleaninig_owner_app/presentation/worker_v2/contracts/ports.dart'
    as wr;
import 'package:dllni_cleaninig_owner_app/presentation/worker_v2/design_system/design_system.dart';
import 'package:dllni_cleaninig_owner_app/presentation/worker_v2/features/access_account/module.dart';

class FixtureRuntime implements wr.WorkerRuntimePort {
  FixtureRuntime({this.authenticated = true, this.online = true});
  bool authenticated;
  bool online;
  int purges = 0;
  WorkerSessionContext session = WorkerSessionContext(
    userId: 'user-10',
    workerId: 'worker-20',
    generation: 'gen-30',
  );
  final events = StreamController<DomainInvalidation>.broadcast();

  @override
  WorkerSessionContext? get context => authenticated ? session : null;
  @override
  wr.RuntimePhase get phase =>
      authenticated ? wr.RuntimePhase.signedIn : wr.RuntimePhase.signedOut;
  @override
  wr.ConnectionState get connection =>
      online ? wr.ConnectionState.online : wr.ConnectionState.offline;
  @override
  Stream<DomainInvalidation> get invalidations => events.stream;
  @override
  void invalidate(
    InvalidationTopic topic, {
    WorkScope? scope,
    String? entityKey,
  }) {}
  @override
  Future<void> purgeSessionData() async {
    purges++;
    authenticated = false;
  }
}

class FixtureAccess implements wr.AccessAccountPort {
  FixtureAccess(this.runtime);
  final FixtureRuntime runtime;
  final profile = WorkerProfileView(
    workerId: 'worker-20',
    displayName: 'Test Worker',
    accountState: 'active',
    editableValues: {'displayName': 'Test Worker', 'bio': 'Ready'},
    workPreferences: {},
    phone: '+963912345678',
    reviewAverage: '4.7',
  );
  ProfileDraft? savedProfile;
  WorkAreaDraft? savedAreas;
  WorkingHoursDraft? savedHours;
  StartLocationDraft? savedLocation;
  int signOutCalls = 0;
  int signInCalls = 0;
  List<WorkingHoursSlot>? hoursOverride;
  bool rejectProfile = false;
  bool rejectSignOut = false;
  CommandResult? nextProfileResult;
  Completer<ReadResult<WorkerProfileView>>? pendingProfile;
  Completer<CommandResult>? pendingProfileSave;
  Completer<CommandResult>? pendingSignOut;
  ReadResult<WorkerProfileView>? nextProfileRead;
  int profileSaveCalls = 0;
  static ReadSuccess<T> ok<T>(T value) => ReadSuccess<T>(
    value: value,
    fetchedAt: DateTime.utc(2026, 10, 23),
    freshness: ReadFreshness.fresh,
  );

  @override
  Future<ReadResult<WorkerSessionContext?>> restoreSession() async =>
      ok(runtime.context);
  @override
  Future<ReadResult<WorkerSessionContext>> signIn({
    required String phone,
    required String password,
  }) async {
    signInCalls++;
    if (password != 'valid') {
      return ReadFailure(
        PortFailure(
          kind: FailureKind.validation,
          reasonCode: 'invalid_credentials',
        ),
      );
    }
    runtime.authenticated = true;
    return ok(runtime.session);
  }

  @override
  Future<ReadResult<ReadinessView>> fetchReadiness() async => ok(
    ReadinessView(
      accountState: 'active',
      completenessItems: ['location'],
      canReceiveRequests: false,
      financialRestrictionCodes: const [],
      remedyDestinations: const {},
    ),
  );
  @override
  Future<ReadResult<WorkerProfileView>> fetchProfile() async {
    if (pendingProfile != null) return await pendingProfile!.future;
    if (nextProfileRead != null) return nextProfileRead!;
    return ok(profile);
  }

  @override
  Future<CommandResult> saveProfile(ProfileDraft draft) async {
    profileSaveCalls++;
    savedProfile = draft;
    if (pendingProfileSave != null) return pendingProfileSave!.future;
    if (nextProfileResult != null) return nextProfileResult!;
    return rejectProfile
        ? CommandResult(
            status: CommandStatus.rejected,
            reasonCode: 'invalid_profile',
            fieldErrors: {
              'bio': ['too long'],
            },
          )
        : CommandResult(status: CommandStatus.confirmed);
  }

  @override
  Future<CommandResult> setAccountActive(bool active) async =>
      CommandResult(status: CommandStatus.rejected, reasonCode: 'unsupported');
  @override
  Future<ReadResult<List<String>>> fetchWorkAreas() async => ok(['zone-1']);
  @override
  Future<CommandResult> saveWorkAreas(WorkAreaDraft draft) async {
    savedAreas = draft;
    return CommandResult(status: CommandStatus.confirmed);
  }

  @override
  Future<ReadResult<List<WorkingHoursSlot>>> fetchWorkingHours() async => ok(
    hoursOverride ??
        [
          const WorkingHoursSlot(
            day: 1,
            startLocalTime: '09:00',
            endLocalTime: '17:00',
          ),
        ],
  );
  @override
  Future<CommandResult> saveWorkingHours(WorkingHoursDraft draft) async {
    savedHours = draft;
    return CommandResult(status: CommandStatus.confirmed);
  }

  @override
  Future<ReadResult<StartLocationDraft?>> fetchStartLocation() async =>
      ok(const StartLocationDraft(source: 'saved', savedLocationId: 'point-1'));
  @override
  Future<CommandResult> saveStartLocation(StartLocationDraft draft) async {
    savedLocation = draft;
    return CommandResult(status: CommandStatus.confirmed);
  }

  @override
  Future<ReadResult<Page<String>>> fetchReviews(PageQuery query) async => ok(
    Page(items: const ['Good work'], page: query.page, lastPage: 1, total: 1),
  );
  @override
  Future<CommandResult> signOut() async {
    signOutCalls++;
    if (pendingSignOut != null) return pendingSignOut!.future;
    return CommandResult(
      status: rejectSignOut ? CommandStatus.rejected : CommandStatus.confirmed,
    );
  }
}

Future<void> showAccount(
  WidgetTester tester,
  FixtureAccess port,
  FixtureRuntime runtime,
  WorkerDestination page, {
  ValueChanged<RouteIntent>? onNavigate,
  List<String>? authorizedAreaIds,
  StartLocationSelector? selectLocation,
  Locale locale = const Locale('en'),
  ValueChanged<Locale>? onLanguageChanged,
  bool settle = true,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: WorkerV2Theme.light(),
      home: AccessAccountModule(
        port: port,
        runtime: runtime,
        initialPage: page,
        initialLocale: locale,
        authorizedAreaIds: authorizedAreaIds,
        selectStartLocation: selectLocation,
        onLanguageChanged: onLanguageChanged,
        onNavigate: onNavigate ?? (_) {},
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

void main() {
  testWidgets('language radio group preserves single selection and callback', (
    tester,
  ) async {
    final runtime = FixtureRuntime();
    final changed = <Locale>[];
    await showAccount(
      tester,
      FixtureAccess(runtime),
      runtime,
      WorkerDestination.language,
      locale: const Locale('ar'),
      onLanguageChanged: changed.add,
    );
    expect(
      tester
          .widget<RadioGroup<String>>(find.byType(RadioGroup<String>))
          .groupValue,
      'ar',
    );

    await tester.tap(
      find.byWidgetPredicate(
        (widget) => widget is RadioListTile<String> && widget.value == 'en',
      ),
    );
    await tester.pumpAndSettle();

    expect(changed, [const Locale('en')]);
    expect(
      tester
          .widget<RadioGroup<String>>(find.byType(RadioGroup<String>))
          .groupValue,
      'en',
    );
  });

  testWidgets(
    'sign-in uses verified port identity and never invents a session',
    (tester) async {
      final runtime = FixtureRuntime(authenticated: false);
      final port = FixtureAccess(runtime);
      await showAccount(tester, port, runtime, WorkerDestination.login);
      expect(find.text('Sign in'), findsWidgets);
      expect(runtime.context, isNull);
      await tester.enterText(find.byType(TextField).first, '+963912345678');
      await tester.enterText(find.byType(TextField).at(1), 'wrong');
      await tester.tap(find.text('Sign in').last);
      await tester.pumpAndSettle();
      expect(port.signInCalls, 1);
      expect(runtime.context, isNull);
      expect(find.text('Account readiness'), findsNothing);
      await tester.enterText(find.byType(TextField).at(1), 'valid');
      await tester.tap(find.text('Sign in').last);
      await tester.pumpAndSettle();
      expect(find.text('Account readiness'), findsOneWidget);
      expect(runtime.context!.workerId, 'worker-20');
    },
  );

  testWidgets(
    'account masks phone, routes support and earnings without work scope',
    (tester) async {
      final runtime = FixtureRuntime();
      final intents = <RouteIntent>[];
      await showAccount(
        tester,
        FixtureAccess(runtime),
        runtime,
        WorkerDestination.account,
        onNavigate: intents.add,
      );
      expect(find.text('•••• 5678'), findsOneWidget);
      expect(find.text('+963912345678'), findsNothing);
      await tester.ensureVisible(find.text('Support'));
      await tester.tap(find.text('Support'));
      expect(intents.single.destination, WorkerDestination.support);
      expect(intents.single.origin, RouteOrigin.profile);
      expect(intents.single.scope, isNull);
      await tester.ensureVisible(find.text('Earnings'));
      await tester.tap(find.text('Earnings'));
      expect(intents.last.destination, WorkerDestination.earnings);
      expect(intents.last.entityId, isNull);
    },
  );

  testWidgets('profile only submits changed server editable fields', (
    tester,
  ) async {
    final runtime = FixtureRuntime();
    final port = FixtureAccess(runtime);
    await showAccount(tester, port, runtime, WorkerDestination.profileEdit);
    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('profile_bio')),
        matching: find.byType(EditableText),
      ),
      'New profile',
    );
    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(port.savedProfile!.supportedFields, {'bio': 'New profile'});
    expect(port.savedProfile!.supportedFields.containsKey('phone'), false);
  });

  testWidgets('area edit is unavailable without authorized catalogue', (
    tester,
  ) async {
    final runtime = FixtureRuntime();
    final port = FixtureAccess(runtime);
    await showAccount(tester, port, runtime, WorkerDestination.workAreas);
    expect(find.text('zone-1'), findsOneWidget);
    expect(find.textContaining('authorized catalogue'), findsOneWidget);
    expect(port.savedAreas, isNull);
  });

  testWidgets('area IDs come only from injected authorized catalogue', (
    tester,
  ) async {
    final runtime = FixtureRuntime();
    final port = FixtureAccess(runtime);
    await showAccount(
      tester,
      port,
      runtime,
      WorkerDestination.workAreas,
      authorizedAreaIds: ['zone-1', 'zone-2'],
    );
    await tester.tap(find.text('zone-2'));
    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(port.savedAreas!.selectedAreaIds, ['zone-1', 'zone-2']);
  });

  testWidgets('explicit picked location only is sent to save', (tester) async {
    final runtime = FixtureRuntime();
    final port = FixtureAccess(runtime);
    await showAccount(
      tester,
      port,
      runtime,
      WorkerDestination.startLocation,
      selectLocation: () async => null,
    );
    await tester.tap(find.text('Choose location'));
    await tester.pumpAndSettle();
    expect(port.savedLocation, isNull);
  });

  testWidgets('explicit coordinates are submitted after confirmation', (
    tester,
  ) async {
    final runtime = FixtureRuntime();
    final port = FixtureAccess(runtime);
    await showAccount(
      tester,
      port,
      runtime,
      WorkerDestination.startLocation,
      selectLocation: () async => const StartLocationDraft(
        source: 'manual',
        latitude: 36.2,
        longitude: 37.1,
      ),
    );
    await tester.tap(find.text('Choose location'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Request location update'));
    await tester.tap(find.text('Request location update'));
    await tester.pumpAndSettle();
    expect(port.savedLocation!.source, 'manual');
    expect(port.savedLocation!.latitude, 36.2);
    expect(port.savedLocation!.longitude, 37.1);
  });

  testWidgets('working hours preserve exact server day and interval fields', (
    tester,
  ) async {
    final runtime = FixtureRuntime();
    final port = FixtureAccess(runtime);
    await showAccount(tester, port, runtime, WorkerDestination.workingHours);
    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(port.savedHours!.slots, hasLength(1));
    expect(port.savedHours!.slots.single.day, 1);
    expect(port.savedHours!.slots.single.startLocalTime, '09:00');
    expect(port.savedHours!.slots.single.endLocalTime, '17:00');
  });

  testWidgets(
    'overlapping hours show advisory but remain submitted as entered',
    (tester) async {
      final runtime = FixtureRuntime();
      final port = FixtureAccess(runtime)
        ..hoursOverride = [
          const WorkingHoursSlot(
            day: 1,
            startLocalTime: '09:00',
            endLocalTime: '14:00',
          ),
          const WorkingHoursSlot(
            day: 1,
            startLocalTime: '12:00',
            endLocalTime: '18:00',
          ),
        ];
      await showAccount(tester, port, runtime, WorkerDestination.workingHours);
      expect(find.textContaining('Ranges overlap'), findsWidgets);
      await tester.ensureVisible(find.text('Save'));
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(port.savedHours!.slots, hasLength(2));
      expect(port.savedHours!.slots.last.startLocalTime, '12:00');
    },
  );

  testWidgets('failed sign out preserves verified session', (tester) async {
    final runtime = FixtureRuntime();
    final port = FixtureAccess(runtime)..rejectSignOut = true;
    await showAccount(tester, port, runtime, WorkerDestination.account);
    await tester.ensureVisible(find.text('Sign out').last);
    await tester.tap(find.text('Sign out').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign out').last);
    await tester.pumpAndSettle();
    expect(port.signOutCalls, 1);
    expect(runtime.purges, 0);
    expect(runtime.authenticated, true);
    expect(find.text('Test Worker'), findsOneWidget);
  });

  testWidgets('offline blocks profile mutation and sign-out', (tester) async {
    final runtime = FixtureRuntime(online: false);
    final port = FixtureAccess(runtime);
    await showAccount(tester, port, runtime, WorkerDestination.profileEdit);
    expect(find.textContaining('offline'), findsWidgets);
    expect(port.savedProfile, isNull);
    await showAccount(tester, port, runtime, WorkerDestination.account);
    expect(port.signOutCalls, 0);
  });

  testWidgets('signed-out same widget never displays prior profile', (
    tester,
  ) async {
    final runtime = FixtureRuntime();
    final port = FixtureAccess(runtime);
    await showAccount(tester, port, runtime, WorkerDestination.account);
    expect(find.text('Test Worker'), findsOneWidget);

    runtime.authenticated = false;
    // Reuse the same keyed widget and port, as the tab host does.
    await showAccount(tester, port, runtime, WorkerDestination.account);
    expect(find.text('Test Worker'), findsNothing);
    expect(find.text('•••• 5678'), findsNothing);
    expect(runtime.purges, 0);
  });

  testWidgets('late profile read is ignored after worker identity changes', (
    tester,
  ) async {
    final runtime = FixtureRuntime();
    final port = FixtureAccess(runtime);
    final delayed = Completer<ReadResult<WorkerProfileView>>();
    port.pendingProfile = delayed;
    await showAccount(
      tester,
      port,
      runtime,
      WorkerDestination.account,
      settle: false,
    );

    runtime.session = WorkerSessionContext(
      userId: 'user-next',
      workerId: 'worker-next',
      generation: 'gen-next',
    );
    await showAccount(
      tester,
      port,
      runtime,
      WorkerDestination.account,
      settle: false,
    );
    delayed.complete(FixtureAccess.ok(port.profile));
    await tester.pumpAndSettle();
    expect(find.text('Test Worker'), findsNothing);
    expect(runtime.purges, 0);
    expect(runtime.context!.workerId, 'worker-next');
  });

  testWidgets('old sign-out completion cannot purge successor worker', (
    tester,
  ) async {
    final runtime = FixtureRuntime();
    final port = FixtureAccess(runtime);
    final delayed = Completer<CommandResult>();
    port.pendingSignOut = delayed;
    await showAccount(tester, port, runtime, WorkerDestination.account);
    await tester.ensureVisible(find.text('Sign out').last);
    await tester.tap(find.text('Sign out').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign out').last);
    await tester.pump();
    expect(port.signOutCalls, 1);

    runtime.session = WorkerSessionContext(
      userId: 'user-next',
      workerId: 'worker-next',
      generation: 'gen-next',
    );
    await showAccount(tester, port, runtime, WorkerDestination.account);
    delayed.complete(CommandResult(status: CommandStatus.confirmed));
    await tester.pumpAndSettle();
    expect(runtime.purges, 0);
    expect(runtime.context!.workerId, 'worker-next');
    expect(find.text('Test Worker'), findsNothing);
  });

  testWidgets('sign-out can revoke A before its confirmed reply', (
    tester,
  ) async {
    final runtime = FixtureRuntime();
    final port = FixtureAccess(runtime);
    final delayed = Completer<CommandResult>();
    port.pendingSignOut = delayed;
    await showAccount(tester, port, runtime, WorkerDestination.account);
    await tester.ensureVisible(find.text('Sign out').last);
    await tester.tap(find.text('Sign out').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign out').last);
    await tester.pump();
    runtime.authenticated = false;
    delayed.complete(CommandResult(status: CommandStatus.confirmed));
    await tester.pumpAndSettle();
    expect(runtime.context, isNull);
    expect(runtime.purges, 0);
    expect(find.text('Test Worker'), findsNothing);
    expect(find.text('Sign in'), findsWidgets);
  });

  testWidgets('old profile save cannot update a newly signed-in worker', (
    tester,
  ) async {
    final runtime = FixtureRuntime();
    final port = FixtureAccess(runtime);
    final pending = Completer<CommandResult>();
    port.pendingProfileSave = pending;
    await showAccount(tester, port, runtime, WorkerDestination.profileEdit);
    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('profile_bio')),
        matching: find.byType(EditableText),
      ),
      'Old account change',
    );
    await tester.tap(find.text('Save'));
    await tester.pump();
    expect(port.profileSaveCalls, 1);
    runtime.session = WorkerSessionContext(
      userId: 'user-next',
      workerId: 'worker-next',
      generation: 'gen-next',
    );
    await showAccount(tester, port, runtime, WorkerDestination.profileEdit);
    pending.complete(CommandResult(status: CommandStatus.confirmed));
    await tester.pumpAndSettle();
    expect(runtime.context!.workerId, 'worker-next');
    expect(find.text('Old account change'), findsNothing);
    expect(find.text('Test Worker'), findsNothing);
    expect(runtime.purges, 0);
  });

  testWidgets('uncertain save cannot repeat until a fresh profile read', (
    tester,
  ) async {
    final runtime = FixtureRuntime();
    final port = FixtureAccess(runtime)
      ..nextProfileResult = CommandResult(status: CommandStatus.outcomeUnknown);
    await showAccount(tester, port, runtime, WorkerDestination.profileEdit);
    final bio = find.descendant(
      of: find.byKey(const ValueKey('profile_bio')),
      matching: find.byType(EditableText),
    );
    await tester.enterText(bio, 'First request');
    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(port.profileSaveCalls, 1);

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(port.profileSaveCalls, 1);

    port.nextProfileResult = CommandResult(status: CommandStatus.confirmed);
    await tester.tap(find.text('Retry').first);
    await tester.pumpAndSettle();
    await tester.enterText(bio, 'After verified refresh');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(port.profileSaveCalls, 2);
  });

  for (final kind in [
    FailureKind.unauthenticated,
    FailureKind.forbidden,
    FailureKind.notFound,
  ]) {
    testWidgets('profile $kind denial clears prior editable draft and save', (
      tester,
    ) async {
      final runtime = FixtureRuntime();
      final port = FixtureAccess(runtime);
      await showAccount(tester, port, runtime, WorkerDestination.profileEdit);
      await tester.enterText(
        find.descendant(
          of: find.byKey(const ValueKey('profile_bio')),
          matching: find.byType(EditableText),
        ),
        'Secret draft A',
      );
      port.nextProfileRead = ReadFailure(
        PortFailure(kind: kind, reasonCode: 'revoked'),
      );
      runtime.events.add(
        DomainInvalidation(
          topic: InvalidationTopic.profile,
          generation: runtime.session.generation,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Secret draft A'), findsNothing);
      expect(find.byKey(const ValueKey('profile_bio')), findsNothing);
      expect(find.text('Save'), findsNothing);
      expect(port.profileSaveCalls, 0);
    });
  }

  testWidgets(
    'network profile refresh retains draft but makes save read-only',
    (tester) async {
      final runtime = FixtureRuntime();
      final port = FixtureAccess(runtime);
      await showAccount(tester, port, runtime, WorkerDestination.profileEdit);
      port.nextProfileRead = ReadFailure(
        PortFailure(kind: FailureKind.network, reasonCode: 'network'),
      );
      runtime.events.add(
        DomainInvalidation(
          topic: InvalidationTopic.profile,
          generation: runtime.session.generation,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('profile_bio')), findsOneWidget);
      expect(
        tester
            .widget<WrActionButton>(find.widgetWithText(WrActionButton, 'Save'))
            .onPressed,
        isNull,
      );
      expect(port.profileSaveCalls, 0);
    },
  );

  testWidgets('picker result from A never becomes worker B location draft', (
    tester,
  ) async {
    final runtime = FixtureRuntime();
    final port = FixtureAccess(runtime);
    final pending = Completer<StartLocationDraft?>();
    Future<StartLocationDraft?> selectLocation() => pending.future;
    await showAccount(
      tester,
      port,
      runtime,
      WorkerDestination.startLocation,
      selectLocation: selectLocation,
    );
    await tester.tap(find.text('Choose location'));
    await tester.pump();
    runtime.session = WorkerSessionContext(
      userId: 'user-B',
      workerId: 'worker-B',
      generation: 'generation-B',
    );
    await showAccount(
      tester,
      port,
      runtime,
      WorkerDestination.startLocation,
      selectLocation: selectLocation,
    );
    pending.complete(
      const StartLocationDraft(
        source: 'saved',
        savedLocationId: 'A-private-pin',
      ),
    );
    await tester.pumpAndSettle();
    expect(runtime.context!.workerId, 'worker-B');
    expect(find.text('A-private-pin'), findsNothing);
    expect(find.text('Request location update'), findsNothing);
    expect(port.savedLocation, isNull);
  });
}
