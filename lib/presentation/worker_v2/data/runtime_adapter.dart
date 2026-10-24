import 'dart:async';
import 'dart:convert';

import '../contracts/common.dart';
import '../contracts/ports.dart';
import 'work_summary_cache.dart';

/// Sanitized event forwarded by S00's existing Pusher/notification coordinator.
/// Only identity and scope identifiers cross this bridge; payloads are never
/// copied into the cache, surfaced in an error, or used to mutate work state.
class WorkerRealtimeNotice {
  const WorkerRealtimeNotice({
    required this.name,
    required this.userId,
    required this.workerId,
    required this.generation,
    this.eventId,
    this.scope,
    this.entityKey,
  });
  final String name;
  final String userId;
  final String workerId;
  final String generation;
  final String? eventId;
  final WorkScope? scope;
  final String? entityKey;
}

class WorkerRuntimeAdapter implements WorkerRuntimePort {
  WorkerRuntimeAdapter({ScopedWorkSummaryCache? cache}) : _cache = cache;

  final ScopedWorkSummaryCache? _cache;
  final _controller = StreamController<DomainInvalidation>.broadcast(
    sync: true,
  );
  StreamSubscription<WorkerRealtimeNotice>? _subscription;
  WorkerSessionContext? _context;
  RuntimePhase _phase = RuntimePhase.restoring;
  ConnectionState _connection = ConnectionState.offline;
  final Set<String> _seenEvents = {};
  int _identityEpoch = 0;
  Future<void> _purgeTail = Future<void>.value();

  /// Even A -> B -> A with identical IDs must not admit an older response.
  int get identityEpoch => _identityEpoch;

  Future<void> _queuePurge() {
    final pending = _purgeTail.then((_) async {
      await _cache?.purgeAll();
    });
    _purgeTail = pending.then<void>((_) {}, onError: (Object _) {});
    return pending;
  }

  @override
  WorkerSessionContext? get context =>
      _phase == RuntimePhase.signedIn ? _context : null;
  @override
  RuntimePhase get phase => _phase;
  @override
  ConnectionState get connection => _connection;
  @override
  Stream<DomainInvalidation> get invalidations => _controller.stream;

  static const _eventTopics = <String, InvalidationTopic>{
    'CleaningBookingCreated': InvalidationTopic.agenda,
    'cleaning_booking.team_updated': InvalidationTopic.agenda,
    'CleaningBookingTrackingUpdated': InvalidationTopic.booking,
    'WorkerArrived': InvalidationTopic.booking,
    'ArrivalVerified': InvalidationTopic.booking,
    'cleaning_order.awaiting_start_verification': InvalidationTopic.booking,
    'cleaning_order.awaiting_worker_start_confirmation':
        InvalidationTopic.booking,
    'cleaning_order.awaiting_customer_completion': InvalidationTopic.booking,
    'CompletionDecisionMade': InvalidationTopic.booking,
    'ServiceExtensionRequested': InvalidationTopic.booking,
  };

  /// One subscription supplied by S00. Reattaching does not create a second
  /// listener. Reconnect is handled by S00 on the existing source.
  void bindEvents(Stream<WorkerRealtimeNotice> events) {
    if (_subscription != null) {
      throw StateError('Realtime bridge already bound');
    }
    _subscription = events.listen(_onNotice);
  }

  void _onNotice(WorkerRealtimeNotice notice) {
    final ctx = context;
    if (ctx == null ||
        notice.userId != ctx.userId ||
        notice.workerId != ctx.workerId ||
        notice.generation != ctx.generation) {
      return;
    }
    final topic = _eventTopics[notice.name];
    if (topic == null) return;
    if (topic == InvalidationTopic.booking && notice.scope == null) return;
    final eventId = notice.eventId;
    if (eventId == null || eventId.trim().isEmpty) return;
    final key = jsonEncode([
      ctx.generation,
      notice.name,
      eventId,
      notice.scope?.cacheKey,
      notice.entityKey,
    ]);
    if (!_seenEvents.add(key)) return;
    if (_seenEvents.length > 256) _seenEvents.remove(_seenEvents.first);
    invalidate(topic, scope: notice.scope, entityKey: notice.entityKey);
  }

  Future<void> replaceIdentity(
    WorkerSessionContext? next, {
    required RuntimePhase phase,
    required ConnectionState connection,
  }) async {
    final transition = ++_identityEpoch;
    // Block reads immediately, including while an earlier purge is suspended.
    _phase = RuntimePhase.revoked;
    _context = null;
    _connection = ConnectionState.offline;
    _seenEvents.clear();
    await _queuePurge();
    if (transition != _identityEpoch) return;
    _context = phase == RuntimePhase.signedIn ? next : null;
    _phase = _context == null && phase == RuntimePhase.signedIn
        ? RuntimePhase.restoring
        : phase;
    _connection = connection;
  }

  void updateConnection(ConnectionState next) {
    _connection = next;
  }

  @override
  void invalidate(
    InvalidationTopic topic, {
    WorkScope? scope,
    String? entityKey,
  }) {
    final ctx = context;
    if (ctx == null || _controller.isClosed) return;
    if (topic == InvalidationTopic.booking ||
        topic == InvalidationTopic.agenda) {
      // Cache freshness is not permission; drop potentially obsolete offline
      // summaries on lifecycle/team changes before the next authoritative GET.
      _cache?.invalidateCachedReads();
      _cache?.purgeAll();
    }
    _controller.add(
      DomainInvalidation(
        topic: topic,
        generation: ctx.generation,
        scope: scope,
        entityKey: entityKey,
      ),
    );
  }

  Future<void> assignmentRemoved(WorkScope scope) async {
    await _cache?.purgeScope(scope);
    invalidate(InvalidationTopic.agenda, scope: scope);
  }

  @override
  Future<void> purgeSessionData() async {
    ++_identityEpoch;
    _context = null;
    _phase = RuntimePhase.revoked;
    _connection = ConnectionState.offline;
    _seenEvents.clear();
    final purge = _queuePurge();
    await _subscription?.cancel();
    _subscription = null;
    await purge;
  }

  Future<void> dispose() async {
    await purgeSessionData();
    await _controller.close();
  }
}
