/// UI-side identities are opaque strings. Transport adapters convert wire IDs.
/// This library never contains auth tokens or transport implementations.
library;

import 'dart:convert';

String requireId(String value, String name) {
  final id = value.trim();
  if (id.isEmpty) throw ArgumentError.value(value, name, 'Must be nonempty');
  return id;
}

class WorkerSessionContext {
  WorkerSessionContext({
    required String userId,
    required String workerId,
    required String generation,
  }) : userId = requireId(userId, 'userId'),
       workerId = requireId(workerId, 'workerId'),
       generation = requireId(generation, 'generation');

  final String userId;
  final String workerId;
  final String generation;
}

class WorkScope {
  WorkScope({
    required String bookingId,
    String? sessionId,
    String? assignmentId,
  }) : bookingId = requireId(bookingId, 'bookingId'),
       sessionId = sessionId == null ? null : requireId(sessionId, 'sessionId'),
       assignmentId = assignmentId == null
           ? null
           : requireId(assignmentId, 'assignmentId');

  final String bookingId;

  /// A selected visit is never replaced by another visit on lookup failure.
  final String? sessionId;
  final String? assignmentId;

  /// Length-safe encoding of all three opaque identities, including nulls.
  String get cacheKey => jsonEncode([bookingId, sessionId, assignmentId]);
}

class Page<T> {
  Page({
    required List<T> items,
    required this.page,
    required this.lastPage,
    required this.total,
  }) : items = List.unmodifiable(items) {
    if (page < 1 || lastPage < 1 || page > lastPage || total < 0) {
      throw ArgumentError('Invalid server pagination metadata');
    }
  }

  final List<T> items;
  final int page;
  final int lastPage;

  /// Server-side result cardinality, never the number of locally loaded rows.
  final int total;
}

enum ReadFreshness { fresh, stale, offline }

enum LoadFreshness { fresh, refreshing, stale, offline }

enum LoadPhase { initial, loading, content, error }

enum FailureKind {
  unauthenticated,
  forbidden,
  notFound,
  validation,
  conflict,
  network,
  server,
}

class PortFailure {
  PortFailure({
    required this.kind,
    required this.reasonCode,
    this.safeMessage,
    Map<String, List<String>> fieldErrors = const {},
  }) : fieldErrors = Map.unmodifiable(
         fieldErrors.map(
           (key, value) => MapEntry(key, List<String>.unmodifiable(value)),
         ),
       );

  final FailureKind kind;
  final String reasonCode;
  final String? safeMessage;
  final Map<String, List<String>> fieldErrors;
}

sealed class ReadResult<T> {
  const ReadResult();
}

final class ReadSuccess<T> extends ReadResult<T> {
  const ReadSuccess({
    required this.value,
    required this.fetchedAt,
    required this.freshness,
  });
  final T value;
  final DateTime fetchedAt;
  final ReadFreshness freshness;
}

final class ReadFailure<T> extends ReadResult<T> {
  const ReadFailure(this.failure);
  final PortFailure failure;
}

class LoadState<T> {
  const LoadState({
    required this.phase,
    this.content,
    this.freshness,
    this.fetchedAt,
    this.failure,
  });

  final LoadPhase phase;

  /// Retained content is permitted for refresh failures, never fabricated.
  final T? content;
  final LoadFreshness? freshness;
  final DateTime? fetchedAt;
  final PortFailure? failure;
}

enum CommandStatus { confirmed, rejected, outcomeUnknown }

class CommandResult {
  CommandResult({
    required this.status,
    this.reasonCode,
    Map<String, List<String>> fieldErrors = const {},
    this.scope,
    this.entityKey,
  }) : fieldErrors = Map.unmodifiable(
         fieldErrors.map(
           (key, value) => MapEntry(key, List<String>.unmodifiable(value)),
         ),
       );

  final CommandStatus status;
  final String? reasonCode;
  final Map<String, List<String>> fieldErrors;
  final WorkScope? scope;
  final String? entityKey;
}

/// Exact decimal string (no exponent, grouping separators, or binary doubles).
class MoneyValue {
  MoneyValue({required String decimal, required String currency})
    : decimal = _validateDecimal(decimal),
      currency = _validateCurrency(currency);

  final String decimal;
  final String currency;

  static String _validateDecimal(String decimal) {
    if (!RegExp(r'^-?(?:0|[1-9][0-9]*)(?:\.[0-9]+)?$').hasMatch(decimal)) {
      throw ArgumentError.value(decimal, 'decimal', 'Exact decimal required');
    }
    return decimal;
  }

  static String _validateCurrency(String currency) {
    if (!RegExp(r'^[A-Z]{3}$').hasMatch(currency)) {
      throw ArgumentError.value(
        currency,
        'currency',
        'ISO alphabetic code required',
      );
    }
    return currency;
  }
}

enum ExecutionOwner { worker, supervisor }

/// Unknown action identifiers never become enabled controls.
enum WorkerAction {
  view('view'),
  acceptOffer('accept_offer'),
  rejectOffer('reject_offer'),
  startTravel('start_travel'),
  arrive('arrive'),
  viewVerificationCode('view_verification_code'),
  confirmWorkStart('confirm_work_start'),
  submitCompletion('submit_completion'),
  cancelAssignment('cancel_assignment'),
  acceptExtension('accept_extension'),
  rejectExtension('reject_extension'),
  decideOpenTimeEnd('decide_open_time_end'),
  decideScheduleChange('decide_schedule_change'),
  requestPriceAdjustment('request_price_adjustment'),
  receiveMaterials('receive_materials'),
  acknowledgeEquipment('acknowledge_equipment'),
  returnEquipment('return_equipment'),
  startSpecialService('start_special_service'),
  finishSpecialService('finish_special_service'),
  sendSos('send_sos');

  const WorkerAction(this.wireName);
  final String wireName;

  static WorkerAction? fromWire(String raw) {
    for (final action in values) {
      if (action.wireName == raw) return action;
    }
    return null;
  }
}

const blockedReasonCodes = {
  'execution_unavailable',
  'supervisor_managed',
  'not_assigned',
  'state_changed',
  'waiting_customer',
  'waiting_team',
  'not_yet_available',
  'financial_restriction',
  'location_required',
  'schedule_unconfirmed',
  'unavailable',
};

class OperationalContext {
  OperationalContext({
    required this.executionOwner,
    required this.executionCapability,
    required Set<WorkerAction> allowedActions,
    Set<String> blockedReasons = const {},
    required this.canRecordAttendance,
  }) : allowedActions = Set.unmodifiable(allowedActions),
       blockedReasons = Set.unmodifiable(blockedReasons) {
    if (!blockedReasonCodes.containsAll(blockedReasons)) {
      throw ArgumentError('Unexpected private or unsupported blocked reason');
    }
  }

  final ExecutionOwner? executionOwner;
  final bool executionCapability;
  final Set<WorkerAction> allowedActions;
  final Set<String> blockedReasons;

  /// Independent of executionCapability for supervisor-managed visits.
  final bool canRecordAttendance;

  static const executionActions = {
    WorkerAction.confirmWorkStart,
    WorkerAction.submitCompletion,
    WorkerAction.acceptExtension,
    WorkerAction.rejectExtension,
    WorkerAction.decideOpenTimeEnd,
    WorkerAction.decideScheduleChange,
    WorkerAction.requestPriceAdjustment,
    WorkerAction.startSpecialService,
    WorkerAction.finishSpecialService,
  };

  bool permits(WorkerAction action) {
    if (!allowedActions.contains(action)) return false;
    if (!executionCapability && executionActions.contains(action)) return false;
    if (!canRecordAttendance &&
        (action == WorkerAction.startTravel || action == WorkerAction.arrive)) {
      return false;
    }
    return true;
  }
}

enum InvalidationTopic {
  agenda,
  booking,
  earnings,
  deposit,
  dispute,
  profile,
  notifications,
}

class DomainInvalidation {
  DomainInvalidation({
    required this.topic,
    required String generation,
    this.scope,
    this.entityKey,
  }) : generation = requireId(generation, 'generation');
  final InvalidationTopic topic;
  final String generation;
  final WorkScope? scope;
  final String? entityKey;
}
