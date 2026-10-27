import 'common.dart';
import 'navigation.dart';

/// Each view exposes authorized, semantic data only. Adapter wire parsing and
/// sensitive-field disclosure checks live outside this library.
class ReadinessView {
  ReadinessView({
    required this.accountState,
    required List<String> completenessItems,
    required this.canReceiveRequests,
    required List<String> financialRestrictionCodes,
    required Map<String, String> remedyDestinations,
  }) : completenessItems = List.unmodifiable(completenessItems),
       financialRestrictionCodes = List.unmodifiable(financialRestrictionCodes),
       remedyDestinations = Map.unmodifiable(remedyDestinations);
  final String accountState;
  final List<String> completenessItems;
  final bool canReceiveRequests;
  final List<String> financialRestrictionCodes;
  final Map<String, String> remedyDestinations;
}

class WorkerProfileView {
  WorkerProfileView({
    required String workerId,
    required this.displayName,
    required this.accountState,
    required Map<String, String?> editableValues,
    required Map<String, String> workPreferences,
    this.phone,
    this.reviewAverage,
    this.trustScore,
  }) : workerId = requireId(workerId, 'workerId'),
       editableValues = Map.unmodifiable(editableValues),
       workPreferences = Map.unmodifiable(workPreferences);
  final String workerId;
  final String displayName;
  final String accountState;
  final Map<String, String?> editableValues;
  final Map<String, String> workPreferences;
  final String? phone;
  final String? reviewAverage;
  final int? trustScore;
}

class WorkSummary {
  const WorkSummary({
    required this.label,
    required this.type,
    this.area,
    this.locationSummary,
  });
  final String label;
  final String type;
  final String? area;
  final String? locationSummary;
}

class OfferView {
  OfferView({
    required String bookingId,
    required this.bookingType,
    required this.discoverable,
    required this.eligible,
    required this.work,
    required List<String> acceptanceModes,
    required List<WorkScope> visitChoices,
    required this.pricingIsFinal,
    this.workerAmount,
  }) : bookingId = requireId(bookingId, 'bookingId'),
       acceptanceModes = List.unmodifiable(acceptanceModes),
       visitChoices = List.unmodifiable(visitChoices);
  final String bookingId;
  final String bookingType;
  final bool discoverable;
  final bool eligible;
  final WorkSummary work;
  final List<String> acceptanceModes;
  final List<WorkScope> visitChoices;
  final bool pricingIsFinal;
  final MoneyValue? workerAmount;
}

class JobSummaryView {
  JobSummaryView({
    required String bookingId,
    required this.reference,
    required this.bookingStatus,
    required this.ownAssignmentStatus,
    required this.work,
    this.visitCount,
  }) : bookingId = requireId(bookingId, 'bookingId');
  final String bookingId;
  final String reference;
  final String bookingStatus;
  final String ownAssignmentStatus;
  final WorkSummary work;

  /// Visit count is supplied by the server, never derived from room quantity.
  final int? visitCount;
}

class AgendaItemView {
  AgendaItemView({
    required String key,
    required this.scope,
    required this.scheduledDate,
    required this.status,
    required this.ownAssignmentStatus,
    required this.work,
    required this.operational,
    this.startsAt,
    this.endsAt,
    this.taskIntervalLabel,
  }) : key = requireId(key, 'key');
  final String key;
  final WorkScope scope;

  /// Inclusive business date in Asia/Damascus: YYYY-MM-DD.
  final String scheduledDate;
  final String status;
  final String ownAssignmentStatus;
  final WorkSummary work;
  final OperationalContext operational;

  /// Canonical UTC instants from backend; null if bounds are ambiguous.
  final DateTime? startsAt;
  final DateTime? endsAt;
  final String? taskIntervalLabel;
}

class AgendaView {
  AgendaView({
    required this.items,
    required this.timezone,
    required this.activeVisits,
    this.nextVisit,
  }) {
    if (timezone != 'Asia/Damascus') {
      throw ArgumentError('Unexpected business timezone');
    }
  }
  final Page<AgendaItemView> items;
  final String timezone;

  /// Full authorized matching result, not a count of loaded rows.
  final int activeVisits;
  final AgendaItemView? nextVisit;
}

class MissionView {
  MissionView({
    required this.scope,
    required this.status,
    required this.stage,
    required this.ownAssignmentStatus,
    required this.operational,
    required List<String> ownServices,
    List<MissionServiceLineView> serviceLines = const [],
    required List<String> ownRooms,
    required List<String> waitingReasons,
    this.customerPhone,
    this.customerLocation,
    this.verificationCode,
    this.scheduledStartsAt,
    this.startedAt,
    this.expiresAt,
    this.billableStartAt,
  }) : ownServices = List.unmodifiable(ownServices),
       serviceLines = List.unmodifiable(serviceLines),
       ownRooms = List.unmodifiable(ownRooms),
       waitingReasons = List.unmodifiable(waitingReasons);
  final WorkScope scope;
  final String status;
  final String stage;
  final String ownAssignmentStatus;
  final OperationalContext operational;
  final List<String> ownServices;
  final List<MissionServiceLineView> serviceLines;
  final List<String> ownRooms;
  final List<String> waitingReasons;

  /// Optional, disclosure-gated server fields; do not persist in offline cache.
  final String? customerPhone;
  final String? customerLocation;
  final String? verificationCode;

  /// Canonical UTC appointment instant. Null when the server has not
  /// supplied a verifiable visit time; it is not inferred from device date.
  final DateTime? scheduledStartsAt;
  final DateTime? startedAt;
  final DateTime? expiresAt;
  final DateTime? billableStartAt;
}

class MissionServiceLineView {
  MissionServiceLineView({
    required this.scope,
    required String lineId,
    required this.label,
    required this.status,
    required Set<WorkerAction> allowedActions,
  }) : lineId = requireId(lineId, 'lineId'),
       allowedActions = Set.unmodifiable(allowedActions);

  final WorkScope scope;
  final String lineId;
  final String label;
  final String status;
  final Set<WorkerAction> allowedActions;
}

class InventoryItemView {
  InventoryItemView({
    required String itemId,
    String? reservationId,
    required this.name,
    required this.quantity,
    required this.custodyState,
    required Set<WorkerAction> allowedActions,
  }) : itemId = requireId(itemId, 'itemId'),
       reservationId = reservationId == null
           ? null
           : requireId(reservationId, 'reservationId'),
       allowedActions = Set.unmodifiable(
         reservationId == null
             ? allowedActions.where(
                 (action) =>
                     action != WorkerAction.acknowledgeEquipment &&
                     action != WorkerAction.returnEquipment,
               )
             : allowedActions,
       );
  final String itemId;
  final String? reservationId;
  final String name;
  final String quantity;
  final String custodyState;
  final Set<WorkerAction> allowedActions;
}

class InventoryView {
  InventoryView({required this.scope, required List<InventoryItemView> items})
    : items = List.unmodifiable(items);
  final WorkScope scope;
  final List<InventoryItemView> items;
}

enum ExtensionRecordFamily { fixedTimeWarning, openTimeExtension }

class DecisionView {
  DecisionView({
    required String requestId,
    required this.scope,
    required this.kind,
    required this.status,
    required this.decisionActor,
    this.extensionFamily,
    required Map<String, String?> currentValues,
    required Map<String, String?> proposedValues,
    this.pricedAmount,
  }) : requestId = requireId(requestId, 'requestId'),
       currentValues = Map.unmodifiable(currentValues),
       proposedValues = Map.unmodifiable(proposedValues);
  final String requestId;
  final WorkScope scope;
  final String kind;
  final String status;
  final String decisionActor;
  final ExtensionRecordFamily? extensionFamily;
  final Map<String, String?> currentValues;
  final Map<String, String?> proposedValues;
  final MoneyValue? pricedAmount;
}

class EarningEntryView {
  EarningEntryView({
    required String key,
    required this.scope,
    required this.completedDate,
    required this.currency,
    required this.authoritativeAmount,
    required this.reconciliationState,
    Map<String, MoneyValue?> frozenBreakdown = const {},
    this.financialState,
  }) : key = requireId(key, 'key'),
       frozenBreakdown = Map.unmodifiable(frozenBreakdown) {
    if (!RegExp(
      r'^(session_assignment|booking_assignment|legacy_booking):[^:]+$',
    ).hasMatch(key)) {
      throw ArgumentError.value(
        key,
        'key',
        'Source-qualified earning key required',
      );
    }
    if (authoritativeAmount != null &&
        authoritativeAmount!.currency != currency) {
      throw ArgumentError('Earning currency mismatch');
    }
  }
  final String key;
  final WorkScope scope;
  final String completedDate;
  final String currency;

  /// Null means unavailable allocation, not zero.
  final MoneyValue? authoritativeAmount;
  final String reconciliationState;
  final Map<String, MoneyValue?> frozenBreakdown;
  final String? financialState;
}

class EarningsView {
  EarningsView({
    required this.entries,
    required Map<String, MoneyValue> completedTotals,
    required this.incompleteEntries,
    required this.periodLabel,
  }) : completedTotals = Map.unmodifiable(completedTotals) {
    if (incompleteEntries < 0 ||
        completedTotals.entries.any(
          (entry) => entry.key != entry.value.currency,
        )) {
      throw ArgumentError('Invalid currency totals or incomplete count');
    }
  }
  final Page<EarningEntryView> entries;
  final Map<String, MoneyValue> completedTotals;
  final int incompleteEntries;
  final String periodLabel;
}

class DepositView {
  DepositView({
    required this.accountStatus,
    required this.financiallyEligible,
    required List<String> restrictionCodes,
    required Map<String, String> remedyDestinations,
    this.currentBalance,
    this.debtBalance,
    this.minimumBalance,
    this.debtCapacity,
  }) : restrictionCodes = List.unmodifiable(restrictionCodes),
       remedyDestinations = Map.unmodifiable(remedyDestinations);
  final String accountStatus;
  final bool financiallyEligible;
  final List<String> restrictionCodes;
  final Map<String, String> remedyDestinations;
  final MoneyValue? currentBalance;

  /// Server-approved debt snapshot, distinct from the deposit and capacity.
  /// Null is unknown, never inferred or interpreted as zero.
  final MoneyValue? debtBalance;
  final MoneyValue? minimumBalance;
  final MoneyValue? debtCapacity;
}

class DepositLedgerEntryView {
  DepositLedgerEntryView({
    required String id,
    required this.occurredAt,
    required this.status,
    required this.amount,
    this.reference,
  }) : id = requireId(id, 'id');
  final String id;
  final DateTime occurredAt;
  final String status;
  final MoneyValue amount;
  final String? reference;
}

class DisputeMessageView {
  DisputeMessageView({
    required String id,
    required this.sentAt,
    required this.body,
    required this.senderLabel,
  }) : id = requireId(id, 'id');
  final String id;
  final DateTime sentAt;
  final String body;
  final String senderLabel;
}

class DisputeView {
  DisputeView({
    required String id,
    required this.scope,
    required this.status,
    required List<String> statusHistory,
    required List<DisputeMessageView> messages,
    required this.canReply,
  }) : id = requireId(id, 'id'),
       statusHistory = List.unmodifiable(statusHistory),
       messages = List.unmodifiable(messages);
  final String id;
  final WorkScope scope;
  final String status;
  final List<String> statusHistory;
  final List<DisputeMessageView> messages;
  final bool canReply;
}

/// Selector resolution is not authorization: S00 must load and authorize any
/// routed mission/dispute under the currently verified worker session.
enum NotificationTargetState { ready, pending, unavailable }

class NotificationView {
  NotificationView({
    required String id,
    required this.title,
    required this.body,
    required this.sentAt,
    required this.isRead,
    this.target,
    NotificationTargetState? targetState,
    this.promptKind,
    this.promptStatus,
  }) : id = requireId(id, 'id'),
       targetState =
           targetState ??
           (target == null
               ? NotificationTargetState.pending
               : NotificationTargetState.ready) {
    if (this.targetState == NotificationTargetState.ready && target == null) {
      throw ArgumentError('A ready notification requires a typed target');
    }
  }
  final String id;
  final String title;
  final String body;
  final DateTime sentAt;
  final bool isRead;
  final RouteIntent? target;
  final NotificationTargetState targetState;

  /// Allowlisted display hint only; it never authorizes a decision.
  final String? promptKind;
  final String? promptStatus;
}

class SupportContactView {
  const SupportContactView({
    required this.label,
    required this.channel,
    required this.value,
  });
  final String label;
  final String channel;
  final String value;
}

class TodayView {
  const TodayView({
    required this.agenda,
    required this.readiness,
    this.activeMission,
  });
  final AgendaView agenda;
  final ReadinessView readiness;
  final WorkScope? activeMission;
}
