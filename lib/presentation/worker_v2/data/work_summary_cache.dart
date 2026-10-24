import 'dart:convert';

import '../contracts/common.dart';
import '../contracts/models.dart';
import 'wire_mappers.dart';

/// S00 may inject app-private storage. The in-memory implementation is useful
/// for isolated fixtures; it deliberately provides no implicit device storage.
abstract interface class WorkSummaryStorage {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
  Future<Iterable<String>> keys();
}

class MemoryWorkSummaryStorage implements WorkSummaryStorage {
  final _values = <String, String>{};
  @override
  Future<String?> read(String key) async => _values[key];
  @override
  Future<void> write(String key, String value) async {
    _values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    _values.remove(key);
  }

  @override
  Future<Iterable<String>> keys() async => List.of(_values.keys);
}

/// A deliberately narrow allowlist; cache has NO general DTO serialization.
/// All restored capabilities are disabled even if a previously approved
/// source row had execution/attendance authorization.
class ScopedWorkSummaryCache {
  ScopedWorkSummaryCache({
    required this.storage,
    required WorkerSessionContext? Function() currentIdentity,
    required bool Function() isAuthenticated,
    DateTime Function()? clock,
  }) : _identity = currentIdentity,
       _authenticated = isAuthenticated,
       _clock = clock ?? DateTime.now;

  final WorkSummaryStorage storage;
  final WorkerSessionContext? Function() _identity;
  final bool Function() _authenticated;
  final DateTime Function() _clock;
  static const contractVersion = 'V2';
  static const maxAge = Duration(hours: 24);
  int _revision = 0;
  bool _invalidated = false;
  final _writeTails = <String, Future<void>>{};
  final _entryVersions = <String, int>{};

  int get revision => _revision;

  /// Synchronously prevents stale offline reads while asynchronous storage
  /// deletion runs; only a fresh authoritative query can unblock the cache.
  void invalidateCachedReads() {
    _revision++;
    _invalidated = true;
  }

  String _key(WorkerSessionContext ctx, String query) => jsonEncode([
    'worker-work-summary',
    contractVersion,
    ctx.userId,
    ctx.workerId,
    ctx.generation,
    query,
  ]);

  bool _matches(WorkerSessionContext expected) {
    final now = _identity();
    return _authenticated() &&
        now != null &&
        now.userId == expected.userId &&
        now.workerId == expected.workerId &&
        now.generation == expected.generation;
  }

  Future<void> writeAgenda(
    WorkerSessionContext ctx,
    String query,
    AgendaView view, {
    int? expectedRevision,
  }) async {
    if (query.startsWith('current-week/')) return;
    if (!_matches(ctx)) return;
    if (expectedRevision == null || _revision != expectedRevision) return;
    final key = _key(ctx, query);
    // Never silently filter a mixed page and retain its original pagination
    // or full-result summary; decline to cache unless EVERY row proves its
    // own assignment. Discoverable offers cannot enter offline work state.
    final entries = view.items.items;
    if (entries.any(
      (item) => !const {
        'accepted',
        'assigned',
        'active',
        'in_progress',
        'completed',
      }.contains(item.ownAssignmentStatus),
    )) {
      invalidateCachedReads();
      await storage.delete(key);
      return;
    }
    final doc = <String, Object?>{
      'version': contractVersion,
      'revision': expectedRevision,
      'identity': [ctx.userId, ctx.workerId, ctx.generation],
      'query': query,
      'savedAt': _clock().toUtc().toIso8601String(),
      'page': view.items.page,
      'lastPage': view.items.lastPage,
      'total': view.items.total,
      'activeVisits': view.activeVisits,
      'rows': entries.map(_safeRow).toList(growable: false),
    };
    // Serialize writes for the same identity/query so a late old write cannot
    // overwrite (or delete) an authorized newer write to the same key.
    final prior = _writeTails[key]?.then<void>((_) {}, onError: (Object _) {}) ??
        Future<void>.value();
    final pending = prior.then((_) async {
      if (!_matches(ctx) || _revision != expectedRevision) return;
      await storage.write(key, jsonEncode(doc));
      // A session revocation or permission denial may have completed while
      // the physical write was suspended; remove that old record.
      if (!_matches(ctx) || _revision != expectedRevision) {
        await storage.delete(key);
        return;
      }
      _invalidated = false;
      _entryVersions[key] = (_entryVersions[key] ?? 0) + 1;
    });
    _writeTails[key] = pending;
    try {
      await pending;
    } finally {
      if (identical(_writeTails[key], pending)) _writeTails.remove(key);
    }
  }

  Map<String, Object?> _safeRow(AgendaItemView item) => {
    'key': item.key,
    'bookingId': item.scope.bookingId,
    'sessionId': item.scope.sessionId,
    'assignmentId': item.scope.assignmentId,
    'serviceLabel': item.work.label,
    'serviceType': item.work.type,
    'scheduledDate': item.scheduledDate,
    'status': item.status,
    'assignmentStatus': item.ownAssignmentStatus,
    'startsAt': item.startsAt?.toUtc().toIso8601String(),
    'endsAt': item.endsAt?.toUtc().toIso8601String(),
    'executionOwner': item.operational.executionOwner?.name,
  };

  Future<ReadSuccess<AgendaView>?> readAgenda(
    WorkerSessionContext ctx,
    String query, {
    required ReadFreshness freshness,
  }) async {
    if (query.startsWith('current-week/')) return null;
    if (!_matches(ctx) || _invalidated) return null;
    final readRevision = _revision;
    final key = _key(ctx, query);
    final entryVersion = _entryVersions[key];
    final raw = await storage.read(key);
    if (_revision != readRevision ||
        _entryVersions[key] != entryVersion ||
        !_matches(ctx) ||
        _invalidated) {
      return null;
    }
    if (raw == null) return null;
    try {
      final doc = WorkerWireMappers.object(jsonDecode(raw));
      if (doc['version'] != contractVersion ||
          doc['query'] != query ||
          jsonEncode(doc['identity']) !=
              jsonEncode([ctx.userId, ctx.workerId, ctx.generation])) {
        await storage.delete(key);
        return null;
      }
      // A fresh write from another query must never reauthorize a cached row
      // from before the latest cache invalidation. Do not delete this key here:
      // a same-key fresh write may have landed after the bytes were read.
      if (doc['revision'] != readRevision) return null;
      final savedAt = WorkerWireMappers.requiredInstant(doc['savedAt']);
      final age = _clock().toUtc().difference(savedAt);
      if (age.isNegative || age >= maxAge) {
        await storage.delete(key);
        return null;
      }
      final items = WorkerWireMappers.list(doc['rows'])
          .map((value) {
            final row = WorkerWireMappers.object(value);
            final scope = WorkScope(
              bookingId: WorkerWireMappers.string(row['bookingId']),
              sessionId: WorkerWireMappers.nullableString(row['sessionId']),
              assignmentId: WorkerWireMappers.nullableString(
                row['assignmentId'],
              ),
            );
            return AgendaItemView(
              key: WorkerWireMappers.string(row['key']),
              scope: scope,
              scheduledDate: WorkerWireMappers.businessDate(
                row['scheduledDate'],
              ),
              status: WorkerWireMappers.safeStatus(
                row['status'],
                WorkerWireMappers.assignmentStatuses,
              ),
              ownAssignmentStatus: WorkerWireMappers.safeStatus(
                row['assignmentStatus'],
                WorkerWireMappers.assignmentStatuses,
              ),
              work: WorkSummary(
                label: WorkerWireMappers.string(row['serviceLabel']),
                type: WorkerWireMappers.string(row['serviceType']),
              ),
              operational: OperationalContext(
                executionOwner: row['executionOwner'] == 'worker'
                    ? ExecutionOwner.worker
                    : row['executionOwner'] == 'supervisor'
                    ? ExecutionOwner.supervisor
                    : null,
                executionCapability: false,
                allowedActions: const {},
                canRecordAttendance: false,
                blockedReasons: const {'unavailable'},
              ),
              startsAt: WorkerWireMappers.instant(row['startsAt']),
              endsAt: WorkerWireMappers.instant(row['endsAt']),
            );
          })
          .toList(growable: false);
      if (!_matches(ctx) ||
          _invalidated ||
          _revision != readRevision ||
          _entryVersions[key] != entryVersion) {
        return null;
      }
      return ReadSuccess<AgendaView>(
        fetchedAt: savedAt,
        freshness: freshness,
        value: AgendaView(
          items: Page(
            items: items,
            page: WorkerWireMappers.integer(doc['page']),
            lastPage: WorkerWireMappers.integer(doc['lastPage']),
            total: WorkerWireMappers.integer(doc['total']),
          ),
          timezone: 'Asia/Damascus',
          activeVisits: WorkerWireMappers.integer(doc['activeVisits']),
        ),
      );
    } catch (_) {
      // Malformed or old serialized cache is untrusted and must not be reused.
      await storage.delete(key);
      return null;
    }
  }

  Future<void> purgeAll() async {
    invalidateCachedReads();
    for (final key in await storage.keys()) {
      if (key.startsWith('["worker-work-summary",')) await storage.delete(key);
    }
  }

  Future<void> purgeScope(WorkScope denied) async {
    invalidateCachedReads();
    for (final key in await storage.keys()) {
      if (!key.startsWith('["worker-work-summary",')) continue;
      final serialized = await storage.read(key);
      if (serialized == null) continue;
      try {
        final doc = WorkerWireMappers.object(jsonDecode(serialized));
        final rows = WorkerWireMappers.list(doc['rows']);
        // Without a specific assignment identity, remove the whole booking;
        // do not accidentally expose another selected visit.
        final remaining = rows.where((value) {
          final row = WorkerWireMappers.object(value);
          if (row['bookingId'] != denied.bookingId) return true;
          if (denied.sessionId == null) return false;
          if (row['sessionId'] != denied.sessionId) return true;
          return denied.assignmentId != null &&
              row['assignmentId'] != denied.assignmentId;
        }).toList();
        if (remaining.length != rows.length) {
          // Server summaries/page counts are now stale; avoid unsafe partial cache.
          await storage.delete(key);
        }
      } catch (_) {
        await storage.delete(key);
      }
    }
  }
}
