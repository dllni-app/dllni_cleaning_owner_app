import 'dart:convert';

import 'common.dart';
import 'models.dart';

/// Filter objects form part of the query/cache key. Date ranges are inclusive
/// business calendar dates in Asia/Damascus, never UTC instant filters.
class DateRange {
  DateRange({required this.from, required this.to}) {
    final pattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    if (!pattern.hasMatch(from) ||
        !pattern.hasMatch(to) ||
        !_validCalendarDay(from) ||
        !_validCalendarDay(to) ||
        from.compareTo(to) > 0) {
      throw ArgumentError('Expected ordered YYYY-MM-DD dates');
    }
  }
  final String from;
  final String to;
  String get key => '$from/$to';

  static DateTime _dayUtc(String value) {
    final parts = value.split('-').map(int.parse).toList();
    return DateTime.utc(parts[0], parts[1], parts[2]);
  }

  static bool _validCalendarDay(String value) =>
      _dayUtc(value).toIso8601String().substring(0, 10) == value;

  int get inclusiveDays => _dayUtc(to).difference(_dayUtc(from)).inDays + 1;
}

class PageQuery {
  PageQuery({this.page = 1, this.perPage = 20}) {
    if (page < 1 || perPage < 1 || perPage > 100) {
      throw ArgumentError('Expected page>=1 and perPage from 1 to 100');
    }
  }
  final int page;
  final int perPage;
  String get key => '$page/$perPage';
}

class OfferQuery {
  OfferQuery({PageQuery? page, this.status, this.search})
    : page = page ?? PageQuery();
  final PageQuery page;
  final String? status;
  final String? search;
  String get key => jsonEncode([page.page, page.perPage, status, search]);
}

class BookingQuery {
  BookingQuery({PageQuery? page, this.status, this.search})
    : page = page ?? PageQuery();
  final PageQuery page;
  final String? status;
  final String? search;
  String get key => jsonEncode([page.page, page.perPage, status, search]);
}

class AgendaQuery {
  AgendaQuery({this.dates, PageQuery? page}) : page = page ?? PageQuery() {
    if (dates != null && dates!.inclusiveDays > 31) {
      throw ArgumentError('Agenda range cannot exceed 31 inclusive days');
    }
  }
  final DateRange? dates;
  final PageQuery page;
  String get key => '${dates?.key ?? 'current-week'}/${page.key}';
}

class EarningsQuery {
  EarningsQuery({this.dates, PageQuery? page}) : page = page ?? PageQuery();
  final DateRange? dates;
  final PageQuery page;
  String get key => '${dates?.key ?? 'all-time'}/${page.key}';
}

class LedgerQuery {
  LedgerQuery({PageQuery? page, this.status}) : page = page ?? PageQuery();
  final PageQuery page;
  final String? status;
  String get key => jsonEncode([page.page, page.perPage, status]);
}

class DisputeQuery {
  DisputeQuery({PageQuery? page, this.status}) : page = page ?? PageQuery();
  final PageQuery page;
  final String? status;
  String get key => jsonEncode([page.page, page.perPage, status]);
}

class NotificationQuery {
  NotificationQuery({PageQuery? page, this.unreadOnly = false})
    : page = page ?? PageQuery();
  final PageQuery page;
  final bool unreadOnly;
  String get key => '${page.key}/$unreadOnly';
}

class ProfileDraft {
  ProfileDraft(Map<String, String?> supportedFields)
    : supportedFields = Map.unmodifiable(supportedFields);
  final Map<String, String?> supportedFields;
}

class WorkAreaDraft {
  WorkAreaDraft(List<String> selectedAreaIds)
    : selectedAreaIds = List.unmodifiable(selectedAreaIds);
  final List<String> selectedAreaIds;
}

class WorkingHoursDraft {
  WorkingHoursDraft(List<WorkingHoursSlot> slots)
    : slots = List.unmodifiable(slots);
  final List<WorkingHoursSlot> slots;
}

class WorkingHoursSlot {
  const WorkingHoursSlot({
    required this.day,
    required this.startLocalTime,
    required this.endLocalTime,
  });
  final int day;
  final String startLocalTime;
  final String endLocalTime;
}

class StartLocationDraft {
  const StartLocationDraft({
    required this.source,
    this.latitude,
    this.longitude,
    this.savedLocationId,
  });
  final String source;
  final double? latitude;
  final double? longitude;
  final String? savedLocationId;
}

enum OfferDecisionKind { decline, acceptLegacy, acceptAll, acceptSelected }

class OfferDecision {
  OfferDecision({
    required this.kind,
    List<String> selectedSessionIds = const [],
  }) : selectedSessionIds = List.unmodifiable(selectedSessionIds) {
    if (kind == OfferDecisionKind.acceptSelected &&
        selectedSessionIds.isEmpty) {
      throw ArgumentError('Selected acceptance requires session IDs');
    }
    if (kind != OfferDecisionKind.acceptSelected &&
        selectedSessionIds.isNotEmpty) {
      throw ArgumentError('Selected IDs apply only to acceptSelected');
    }
  }
  final OfferDecisionKind kind;
  final List<String> selectedSessionIds;
}

/// Typed operational commands preserve the exact visit and never fall back to
/// a parent booking or sibling session if the selected visit is unavailable.
sealed class MissionCommand {
  const MissionCommand(this.scope);
  final WorkScope scope;
  String get type;
}

final class SimpleMissionCommand extends MissionCommand {
  const SimpleMissionCommand(super.scope, this.action);
  final SimpleMissionAction action;
  @override
  String get type => switch (action) {
    SimpleMissionAction.startTravel => WorkerAction.startTravel.wireName,
    SimpleMissionAction.arrive => WorkerAction.arrive.wireName,
    SimpleMissionAction.confirmWorkStart =>
      WorkerAction.confirmWorkStart.wireName,
    SimpleMissionAction.receiveMaterials =>
      WorkerAction.receiveMaterials.wireName,
  };
}

enum SimpleMissionAction {
  startTravel,
  arrive,
  confirmWorkStart,
  receiveMaterials,
}

/// Typed legacy completion checklist snapshot. S03 maps it to the existing
/// dual snake/camel wire fields for legacy bookings; session completion only
/// forwards its optional message and never substitutes sibling scopes.
class CompletionTaskSnapshot {
  CompletionTaskSnapshot({
    required String name,
    required this.label,
    this.detail,
    required this.sort,
  }) : name = requireId(name, 'name') {
    if (label.trim().isEmpty || sort < 0) {
      throw ArgumentError('Invalid completion checklist item');
    }
  }
  final String name;
  final String label;
  final String? detail;
  final int sort;
}

final class CompletionReportCommand extends MissionCommand {
  CompletionReportCommand(
    super.scope, {
    this.completionMessage,
    List<CompletionTaskSnapshot> cleaningServices = const [],
    List<CompletionTaskSnapshot> propertiesRooms = const [],
  }) : cleaningServices = List.unmodifiable(cleaningServices),
       propertiesRooms = List.unmodifiable(propertiesRooms) {
    if (scope.sessionId != null &&
        (cleaningServices.isNotEmpty || propertiesRooms.isNotEmpty)) {
      throw ArgumentError('Session completion accepts message only');
    }
  }
  final String? completionMessage;
  final List<CompletionTaskSnapshot> cleaningServices;
  final List<CompletionTaskSnapshot> propertiesRooms;
  @override
  String get type => WorkerAction.submitCompletion.wireName;
}

final class SpecialServiceStartCommand extends MissionCommand {
  SpecialServiceStartCommand(super.scope, {required String lineId})
    : lineId = requireId(lineId, 'lineId');
  final String lineId;
  @override
  String get type => WorkerAction.startSpecialService.wireName;
}

enum SpecialServiceFinishStatus { completed, unable }

final class SpecialServiceFinishCommand extends MissionCommand {
  SpecialServiceFinishCommand(
    super.scope, {
    required String lineId,
    required this.status,
    this.reason,
    List<String> afterImages = const [],
  }) : lineId = requireId(lineId, 'lineId'),
       afterImages = List.unmodifiable(afterImages) {
    if (status == SpecialServiceFinishStatus.unable &&
        (reason == null || reason!.trim().isEmpty)) {
      throw ArgumentError('Unable status requires a reason');
    }
  }
  final String lineId;
  final SpecialServiceFinishStatus status;
  final String? reason;
  final List<String> afterImages;
  @override
  String get type => WorkerAction.finishSpecialService.wireName;
}

final class AcknowledgeEquipmentCommand extends MissionCommand {
  AcknowledgeEquipmentCommand(super.scope, {required String reservationId})
    : reservationId = requireId(reservationId, 'reservationId');
  final String reservationId;
  @override
  String get type => WorkerAction.acknowledgeEquipment.wireName;
}

final class ReturnEquipmentCommand extends MissionCommand {
  ReturnEquipmentCommand(
    super.scope, {
    required String reservationId,
    this.failureReason,
  }) : reservationId = requireId(reservationId, 'reservationId');
  final String reservationId;
  final String? failureReason;
  @override
  String get type => WorkerAction.returnEquipment.wireName;
}

final class CancellationCommand extends MissionCommand {
  const CancellationCommand(super.scope, {required this.reason});
  final String reason;
  @override
  String get type => 'cancel_assignment';
}

final class ExtensionDecisionCommand extends MissionCommand {
  ExtensionDecisionCommand(
    super.scope, {
    required String extensionId,
    required this.family,
    required this.accept,
    this.reason,
    this.additionalMinutes,
  }) : extensionId = requireId(extensionId, 'extensionId') {
    validate();
  }

  /// Actual open-time/extension record identity, independent of visit scope.
  final String extensionId;
  final ExtensionRecordFamily family;
  final bool accept;

  /// Existing extension decision endpoints accept an optional rejection reason.
  final String? reason;
  final int? additionalMinutes;

  bool get _validAdditionalMinutes =>
      additionalMinutes == null ||
      (accept &&
          family == ExtensionRecordFamily.fixedTimeWarning &&
          additionalMinutes! > 0);

  void validate() {
    if (!_validAdditionalMinutes) {
      throw ArgumentError(
        'Additional minutes require an accepted fixed time warning',
      );
    }
  }

  @override
  String get type => accept ? 'accept_extension' : 'reject_extension';
}

final class OpenTimeEndCommand extends MissionCommand {
  const OpenTimeEndCommand(super.scope, {required this.approve, this.reason});

  /// The existing end decision is addressed by booking/visit scope, not a request ID.
  final bool approve;
  final String? reason;
  @override
  String get type => 'decide_open_time_end';
}

final class ScheduleChangeCommand extends MissionCommand {
  ScheduleChangeCommand(
    super.scope, {
    required String changeRequestId,
    required this.approve,
    this.reason,
  }) : changeRequestId = requireId(changeRequestId, 'changeRequestId');
  final String changeRequestId;
  final bool approve;
  final String? reason;
  @override
  String get type => 'decide_schedule_change';
}

final class PriceAdjustmentCommand extends MissionCommand {
  const PriceAdjustmentCommand(
    super.scope, {
    required this.reason,
    required this.requestedAmount,
  });
  final String reason;
  final MoneyValue requestedAmount;
  @override
  String get type => 'request_price_adjustment';
}

class SosDraft {
  const SosDraft({
    required this.reason,
    this.message,
    this.latitude,
    this.longitude,
  });
  final String reason;
  final String? message;
  final double? latitude;
  final double? longitude;
}
