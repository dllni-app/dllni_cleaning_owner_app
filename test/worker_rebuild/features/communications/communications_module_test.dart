import 'dart:async';

import 'package:flutter/material.dart' hide ConnectionState, Page;
import 'package:flutter_test/flutter_test.dart';
import 'package:dllni_cleaninig_owner_app/presentation/worker_v2/contracts/common.dart';
import 'package:dllni_cleaninig_owner_app/presentation/worker_v2/contracts/models.dart';
import 'package:dllni_cleaninig_owner_app/presentation/worker_v2/contracts/navigation.dart';
import 'package:dllni_cleaninig_owner_app/presentation/worker_v2/contracts/ports.dart';
import 'package:dllni_cleaninig_owner_app/presentation/worker_v2/contracts/requests.dart';
import 'package:dllni_cleaninig_owner_app/presentation/worker_v2/features/communications/module.dart';

final _ctx = WorkerSessionContext(
  userId: 'user-a',
  workerId: 'worker-a',
  generation: 'g1',
);
final _scope = WorkScope(
  bookingId: 'b-1',
  sessionId: 'visit-7',
  assignmentId: 'a-9',
);

class _Runtime implements WorkerRuntimePort {
  @override
  WorkerSessionContext? context = _ctx;
  @override
  RuntimePhase phase = RuntimePhase.signedIn;
  @override
  ConnectionState connection = ConnectionState.online;
  @override
  Stream<DomainInvalidation> get invalidations =>
      const Stream<DomainInvalidation>.empty();
  @override
  Future<void> purgeSessionData() async {}
  @override
  void invalidate(
    InvalidationTopic topic, {
    WorkScope? scope,
    String? entityKey,
  }) {}
}

class _Communications implements CommunicationsPort {
  int readCalls = 0;
  int markCalls = 0;
  int deleteCalls = 0;
  int sosCalls = 0;
  CommandStatus nextSos = CommandStatus.outcomeUnknown;
  CommandStatus markStatus = CommandStatus.confirmed;
  Completer<CommandResult>? pendingMark;
  bool failNotificationRead = false;
  bool failSupportRead = false;
  ReadFreshness notificationFreshness = ReadFreshness.fresh;
  List<NotificationView>? notifications;
  List<SupportContactView> contacts = const [];
  WorkScope? sentScope;
  SosDraft? draft;
  ReadSuccess<T> ok<T>(T value) => ReadSuccess(
    value: value,
    freshness: ReadFreshness.fresh,
    fetchedAt: DateTime.utc(2026, 10, 23),
  );
  @override
  Future<ReadResult<Page<NotificationView>>> fetchNotifications(
    NotificationQuery query,
  ) async {
    readCalls++;
    if (failNotificationRead) {
      return ReadFailure<Page<NotificationView>>(
        PortFailure(kind: FailureKind.server, reasonCode: 'read_unavailable'),
      );
    }
    return ReadSuccess(
      value: Page(
        items:
            notifications ??
            [
              NotificationView(
                id: 'n1',
                title: 'Visit changed',
                body: 'Review the selected visit',
                sentAt: DateTime.utc(2026, 10, 23),
                isRead: false,
                target: RouteIntent(
                  destination: WorkerDestination.mission,
                  origin: RouteOrigin.notification,
                  scope: _scope,
                ),
              ),
            ],
        page: 1,
        lastPage: 1,
        total: notifications?.length ?? 1,
      ),
      freshness: notificationFreshness,
      fetchedAt: DateTime.utc(2026, 10, 23),
    );
  }

  @override
  Future<CommandResult> markNotificationRead(String id) async {
    markCalls++;
    if (pendingMark != null) return pendingMark!.future;
    return CommandResult(status: markStatus);
  }

  @override
  Future<CommandResult> deleteNotification(String id) async {
    deleteCalls++;
    return CommandResult(status: CommandStatus.confirmed);
  }

  @override
  Future<CommandResult> deleteAllNotifications() async =>
      CommandResult(status: CommandStatus.rejected);
  @override
  Future<ReadResult<List<SupportContactView>>> fetchSupportContacts() async =>
      failSupportRead
      ? ReadFailure<List<SupportContactView>>(
          PortFailure(
            kind: FailureKind.network,
            reasonCode: 'read_unavailable',
          ),
        )
      : ok(contacts);
  @override
  Future<CommandResult> sendSos(WorkScope scope, SosDraft value) async {
    sosCalls++;
    sentScope = scope;
    draft = value;
    return CommandResult(status: nextSos);
  }
}

void main() {
  testWidgets(
    'notification navigation preserves the selected visit and does not mutate it',
    (tester) async {
      final port = _Communications();
      final intents = <RouteIntent>[];
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          home: WorkerCommunicationsModule(
            communications: port,
            runtime: _Runtime(),
            session: _ctx,
            onNavigate: intents.add,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open related item'));
      expect(intents.single.destination, WorkerDestination.mission);
      expect(intents.single.scope!.sessionId, 'visit-7');
      expect(intents.single.scope!.assignmentId, 'a-9');
      expect(port.markCalls, 0);
      expect(port.deleteCalls, 0);
    },
  );

  testWidgets(
    'pending and unavailable destinations remain visible but never navigate',
    (tester) async {
      final port = _Communications()
        ..notifications = [
          NotificationView(
            id: 'n-pending',
            title: 'Work pending',
            body: 'Check later',
            sentAt: DateTime.utc(2026, 10, 23),
            isRead: true,
            targetState: NotificationTargetState.pending,
          ),
          NotificationView(
            id: 'n-gone',
            title: 'Work removed',
            body: 'No longer accessible',
            sentAt: DateTime.utc(2026, 10, 23),
            isRead: true,
            targetState: NotificationTargetState.unavailable,
          ),
        ];
      final intents = <RouteIntent>[];
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          home: WorkerCommunicationsModule(
            communications: port,
            runtime: _Runtime(),
            session: _ctx,
            onNavigate: intents.add,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Work pending'), findsOneWidget);
      expect(find.text('Work removed'), findsOneWidget);
      expect(find.text('Destination pending'), findsOneWidget);
      expect(find.text('Destination unavailable'), findsOneWidget);
      expect(find.text('Open related item'), findsNothing);
      expect(find.text('Review request'), findsNothing);
      expect(intents, isEmpty);
      expect(port.markCalls, 0);
      expect(port.deleteCalls, 0);
    },
  );

  testWidgets(
    'only server actionable mission prompt delegates exact scope to S06',
    (tester) async {
      final port = _Communications()
        ..notifications = [
          NotificationView(
            id: 'n-prompt',
            title: 'Extension decision',
            body: 'Review in mission',
            sentAt: DateTime.utc(2026, 10, 23),
            isRead: false,
            promptKind: 'extension_request',
            promptStatus: 'actionable',
            target: RouteIntent(
              destination: WorkerDestination.mission,
              origin: RouteOrigin.system,
              scope: _scope,
            ),
          ),
        ];
      final intents = <RouteIntent>[];
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          home: WorkerCommunicationsModule(
            communications: port,
            runtime: _Runtime(),
            session: _ctx,
            onNavigate: intents.add,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Time extension request'), findsOneWidget);
      expect(find.text('Needs your review'), findsOneWidget);
      expect(find.text('Review request'), findsOneWidget);
      await tester.tap(find.text('Review request'));
      await tester.pump();
      expect(intents, hasLength(1));
      expect(intents.single.destination, WorkerDestination.mission);
      expect(intents.single.origin, RouteOrigin.notification);
      expect(intents.single.scope!.bookingId, 'b-1');
      expect(intents.single.scope!.sessionId, 'visit-7');
      expect(intents.single.scope!.assignmentId, 'a-9');
      expect(port.markCalls, 0);
      expect(port.deleteCalls, 0);
      expect(port.sosCalls, 0);
    },
  );

  testWidgets(
    'handled, expired, pending and unknown prompts grant no decision route',
    (tester) async {
      final valid = RouteIntent(
        destination: WorkerDestination.mission,
        origin: RouteOrigin.notification,
        scope: _scope,
      );
      final port = _Communications()
        ..notifications = [
          for (final status in [
            'handled',
            'expired',
            'pending',
            'active',
            'needs_response',
            'unknown',
          ])
            NotificationView(
              id: 'n-$status',
              title: status,
              body: 'Status only',
              sentAt: DateTime.utc(2026, 10, 23),
              isRead: true,
              target: valid,
              promptKind: 'schedule_change',
              promptStatus: status,
            ),
          NotificationView(
            id: 'n-bad-destination',
            title: 'No mission scope',
            body: 'Review not possible',
            sentAt: DateTime.utc(2026, 10, 23),
            isRead: true,
            promptKind: 'extension_request',
            promptStatus: 'actionable',
            target: RouteIntent(
              destination: WorkerDestination.disputes,
              origin: RouteOrigin.notification,
            ),
          ),
          NotificationView(
            id: 'n-explicitly-unavailable',
            title: 'Denied request',
            body: 'No authorization',
            sentAt: DateTime.utc(2026, 10, 23),
            isRead: true,
            promptKind: 'extension_request',
            promptStatus: 'actionable',
            target: valid,
            targetState: NotificationTargetState.unavailable,
          ),
        ];
      final intents = <RouteIntent>[];
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          home: WorkerCommunicationsModule(
            communications: port,
            runtime: _Runtime(),
            session: _ctx,
            onNavigate: intents.add,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Already handled'), findsOneWidget);
      expect(find.text('Expired'), findsOneWidget);
      expect(find.text('Review request'), findsNothing);
      expect(find.text('Open related item'), findsNothing);
      expect(intents, isEmpty);
      expect(port.sosCalls, 0);
    },
  );

  testWidgets('stale and offline actionable prompts cannot route to mission', (
    tester,
  ) async {
    final port = _Communications()
      ..notificationFreshness = ReadFreshness.stale
      ..notifications = [
        NotificationView(
          id: 'n-prompt',
          title: 'Decision',
          body: 'Needs review',
          sentAt: DateTime.utc(2026, 10, 23),
          isRead: true,
          promptKind: 'extension_request',
          promptStatus: 'actionable',
          target: RouteIntent(
            destination: WorkerDestination.visitScope,
            origin: RouteOrigin.notification,
            scope: _scope,
          ),
        ),
      ];
    final runtime = _Runtime()..connection = ConnectionState.offline;
    final intents = <RouteIntent>[];
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        home: WorkerCommunicationsModule(
          communications: port,
          runtime: runtime,
          session: _ctx,
          onNavigate: intents.add,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Review request'), findsOneWidget);
    final button = find
        .ancestor(
          of: find.text('Review request'),
          matching: find.byType(InkWell),
        )
        .first;
    expect(tester.widget<InkWell>(button).onTap, isNull);
    expect(intents, isEmpty);
    expect(port.markCalls, 0);
  });

  testWidgets('delete notification requires an explicit confirmation', (
    tester,
  ) async {
    final port = _Communications();
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        home: WorkerCommunicationsModule(
          communications: port,
          runtime: _Runtime(),
          session: _ctx,
          onNavigate: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(port.deleteCalls, 0);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(port.deleteCalls, 0);
  });

  testWidgets('a pending notification write locks filters until it returns', (
    tester,
  ) async {
    final port = _Communications()..pendingMark = Completer<CommandResult>();
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        home: WorkerCommunicationsModule(
          communications: port,
          runtime: _Runtime(),
          session: _ctx,
          onNavigate: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mark read'));
    await tester.pump();
    expect(port.markCalls, 1);
    expect(tester.widget<Switch>(find.byType(Switch)).onChanged, isNull);
    port.pendingMark!.complete(CommandResult(status: CommandStatus.confirmed));
    await tester.pumpAndSettle();
    expect(port.readCalls, 2);
    expect(tester.widget<Switch>(find.byType(Switch)).onChanged, isNotNull);
  });

  testWidgets(
    'uncertain notification write needs successful server read before manual retry',
    (tester) async {
      final port = _Communications()..markStatus = CommandStatus.outcomeUnknown;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          home: WorkerCommunicationsModule(
            communications: port,
            runtime: _Runtime(),
            session: _ctx,
            onNavigate: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mark read'));
      await tester.pumpAndSettle();
      expect(port.markCalls, 1);
      port.failNotificationRead = true;
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pumpAndSettle();
      expect(find.text('Unable to load'), findsOneWidget);
      expect(find.text('Mark read'), findsNothing);
      expect(port.markCalls, 1);
      port.failNotificationRead = false;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(port.markCalls, 1);
      expect(find.text('Mark read'), findsOneWidget);
      await tester.tap(find.text('Mark read'));
      await tester.pumpAndSettle();
      expect(port.markCalls, 2);
    },
  );

  testWidgets('offline SOS cannot send and empty category list fails closed', (
    tester,
  ) async {
    final port = _Communications();
    final runtime = _Runtime()..connection = ConnectionState.offline;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        home: WorkerCommunicationsModule(
          communications: port,
          runtime: runtime,
          session: _ctx,
          onNavigate: (_) {},
          destination: WorkerDestination.sos,
          scope: _scope,
          sosAuthorized: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Alert categories unavailable'), findsOneWidget);
    expect(port.sosCalls, 0);
  });

  testWidgets(
    'unavailable SOS still offers verified phone fallback without submitting alert',
    (tester) async {
      final port = _Communications();
      final runtime = _Runtime()..connection = ConnectionState.offline;
      final intents = <RouteIntent>[];
      final launched = <SupportContactView>[];
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          home: WorkerCommunicationsModule(
            communications: port,
            runtime: runtime,
            session: _ctx,
            onNavigate: intents.add,
            destination: WorkerDestination.sos,
            verifiedEmergencyPhone: const SupportContactView(
              label: 'Configured emergency',
              channel: 'phone',
              value: '+10000000000',
            ),
            onOpenContact: (channel) async {
              launched.add(channel);
              return true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('SOS unavailable for this assignment'), findsOneWidget);
      expect(find.text('Send alert'), findsNothing);
      await tester.tap(find.text('Open emergency phone dialer'));
      await tester.pumpAndSettle();
      expect(launched.single.channel, 'phone');
      expect(
        find.textContaining('a connected call is not confirmed'),
        findsOneWidget,
      );
      expect(port.sosCalls, 0);
      await tester.tap(find.text('Support channels'));
      expect(intents.single.destination, WorkerDestination.support);
      expect(intents.single.scope, isNull);
    },
  );

  testWidgets(
    'unconfigured emergency phone does not invent a fallback number',
    (tester) async {
      final port = _Communications();
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          home: WorkerCommunicationsModule(
            communications: port,
            runtime: _Runtime(),
            session: _ctx,
            onNavigate: (_) {},
            destination: WorkerDestination.sos,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining('No emergency phone number is configured'),
        findsOneWidget,
      );
      expect(find.text('Open emergency phone dialer'), findsNothing);
      expect(port.sosCalls, 0);
    },
  );

  testWidgets(
    'support launcher rejects unsafe URLs and unsupported channel types',
    (tester) async {
      final port = _Communications()
        ..contacts = const [
          SupportContactView(
            label: 'Unsafe URL',
            channel: 'website',
            value: 'javascript:alert(1)',
          ),
          SupportContactView(
            label: 'Insecure HTTP',
            channel: 'web',
            value: 'http://example.org/support',
          ),
          SupportContactView(
            label: 'Loopback URL',
            channel: 'url',
            value: 'https://127.0.0.1/admin',
          ),
          SupportContactView(
            label: 'Local URL',
            channel: 'web',
            value: 'https://router.local/admin',
          ),
          SupportContactView(
            label: 'Malformed percent URL',
            channel: 'website',
            value: 'https://support.example.org/%ZZ',
          ),
          SupportContactView(
            label: 'Spoofed WhatsApp',
            channel: 'whatsapp',
            value: 'https://wa.me.attacker.example/message/123',
          ),
          SupportContactView(
            label: 'URL credentials',
            channel: 'website',
            value: 'https://support.example.org@evil.example/',
          ),
          SupportContactView(
            label: 'Unsafe email query',
            channel: 'mailto',
            value: 'mailto:help@example.org?subject=unexpected',
          ),
          SupportContactView(
            label: 'Unsafe number',
            channel: 'phone',
            value: '+1234\n567',
          ),
          SupportContactView(
            label: 'Unknown type',
            channel: 'custom',
            value: 'https://example.org/',
          ),
          SupportContactView(
            label: 'Verified website',
            channel: 'website',
            value: 'https://example.org/support',
          ),
        ];
      final launched = <SupportContactView>[];
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          home: WorkerCommunicationsModule(
            communications: port,
            runtime: _Runtime(),
            session: _ctx,
            onNavigate: (_) {},
            destination: WorkerDestination.support,
            onOpenContact: (contact) async {
              launched.add(contact);
              return true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Unsafe URL'), findsNothing);
      expect(find.text('Insecure HTTP'), findsNothing);
      expect(find.text('Loopback URL'), findsNothing);
      expect(find.text('Local URL'), findsNothing);
      expect(find.text('Malformed percent URL'), findsNothing);
      expect(find.text('Spoofed WhatsApp'), findsNothing);
      expect(find.text('URL credentials'), findsNothing);
      expect(find.text('Unsafe email query'), findsNothing);
      expect(find.text('Unsafe number'), findsNothing);
      expect(find.text('Unknown type'), findsNothing);
      expect(find.text('Verified website'), findsOneWidget);
      await tester.tap(find.text('Open channel'));
      await tester.pumpAndSettle();
      expect(launched.single.value, 'https://example.org/support');
    },
  );

  testWidgets(
    'configured tel, mailto and web aliases pass canonical safe values to host',
    (tester) async {
      final configured = <SupportContactView>[
        const SupportContactView(
          label: 'Phone help',
          channel: 'tel',
          value: 'tel:+963112345678',
        ),
        const SupportContactView(
          label: 'Email help',
          channel: 'mailto',
          value: 'mailto:help@example.org',
        ),
        const SupportContactView(
          label: 'Web help',
          channel: 'web',
          value: 'https://support.example.org/contact',
        ),
        const SupportContactView(
          label: 'WhatsApp help',
          channel: 'whatsapp',
          value: 'https://wa.me/message/VERIFIED',
        ),
      ];
      final launched = <SupportContactView>[];
      for (final channel in configured) {
        final port = _Communications()..contacts = [channel];
        await tester.pumpWidget(
          MaterialApp(
            key: ValueKey(channel.channel),
            home: WorkerCommunicationsModule(
              communications: port,
              runtime: _Runtime(),
              session: _ctx,
              onNavigate: (_) {},
              destination: WorkerDestination.support,
              onOpenContact: (contact) async {
                launched.add(contact);
                return true;
              },
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text(channel.label), findsOneWidget);
        await tester.tap(find.text('Open channel'));
        await tester.pumpAndSettle();
      }
      expect(launched.map((contact) => contact.channel).toList(), [
        'phone',
        'email',
        'website',
        'whatsapp',
      ]);
      expect(launched.map((contact) => contact.value).toList(), [
        '+963112345678',
        'help@example.org',
        'https://support.example.org/contact',
        'https://wa.me/message/VERIFIED',
      ]);
    },
  );

  testWidgets('verified tel alias stays available as independent SOS dialer', (
    tester,
  ) async {
    final launched = <SupportContactView>[];
    await tester.pumpWidget(
      MaterialApp(
        home: WorkerCommunicationsModule(
          communications: _Communications(),
          runtime: _Runtime(),
          session: _ctx,
          destination: WorkerDestination.sos,
          onNavigate: (_) {},
          verifiedEmergencyPhone: const SupportContactView(
            label: 'Hotline',
            channel: 'tel',
            value: 'tel:+963112345678',
          ),
          onOpenContact: (contact) async {
            launched.add(contact);
            return true;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open emergency phone dialer'));
    await tester.pumpAndSettle();
    expect(launched.single.channel, 'phone');
    expect(launched.single.value, '+963112345678');
  });

  testWidgets(
    'Arabic contact details remain LTR and notification date uses ASCII digits',
    (tester) async {
      final port = _Communications()
        ..contacts = const [
          SupportContactView(
            label: 'هاتف الدعم',
            channel: 'phone',
            value: '+963 11 2345678',
          ),
        ];
      final runtime = _Runtime();
      Future<void> render(WorkerDestination destination) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Localizations.override(
                context: context,
                locale: const Locale('ar'),
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: WorkerCommunicationsModule(
                    key: ValueKey(destination),
                    communications: port,
                    runtime: runtime,
                    session: _ctx,
                    destination: destination,
                    onNavigate: (_) {},
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      await render(WorkerDestination.support);
      final phone = tester.widget<SelectableText>(find.byType(SelectableText));
      expect(phone.textDirection, TextDirection.ltr);
      expect(find.text('هاتف الدعم'), findsOneWidget);
      await render(WorkerDestination.notifications);
      expect(find.text('الإشعارات'), findsOneWidget);
      final timestamp = tester
          .widgetList<Text>(find.byType(Text))
          .map((w) => w.data ?? '')
          .firstWhere((value) => value.contains('2026'));
      expect(timestamp, isNot(contains('00:00:00.000')));
      expect(timestamp, isNot(matches(RegExp(r'[٠-٩۰-۹]'))));
    },
  );

  testWidgets('support error still exposes verified offline emergency dialer', (
    tester,
  ) async {
    final port = _Communications()..failSupportRead = true;
    final runtime = _Runtime()..connection = ConnectionState.offline;
    final launched = <SupportContactView>[];
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        home: WorkerCommunicationsModule(
          communications: port,
          runtime: runtime,
          session: _ctx,
          destination: WorkerDestination.support,
          onNavigate: (_) {},
          verifiedEmergencyPhone: const SupportContactView(
            label: 'Verified dialer',
            channel: 'phone',
            value: '+12345678901',
          ),
          onOpenContact: (contact) async {
            launched.add(contact);
            return false;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Unable to load'), findsOneWidget);
    expect(find.text('Open emergency phone dialer'), findsOneWidget);
    await tester.tap(find.text('Open emergency phone dialer'));
    await tester.pumpAndSettle();
    expect(launched.single.value, '+12345678901');
    expect(find.text('Could not open the contact app'), findsOneWidget);
    expect(port.sosCalls, 0);
  });

  testWidgets('SOS uncertain delivery cannot send again', (tester) async {
    final port = _Communications();
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        home: WorkerCommunicationsModule(
          communications: port,
          runtime: _Runtime(),
          session: _ctx,
          onNavigate: (_) {},
          destination: WorkerDestination.sos,
          scope: _scope,
          sosAuthorized: true,
          allowedSosReasons: const ['urgent_help'],
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('urgent_help').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send alert'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send').last);
    await tester.pumpAndSettle();
    expect(port.sosCalls, 1);
    expect(port.sentScope!.sessionId, 'visit-7');
    expect(port.draft!.reason, 'urgent_help');
    expect(
      find.textContaining('Delivery could not be confirmed'),
      findsOneWidget,
    );
    expect(port.sosCalls, 1);
  });
}
