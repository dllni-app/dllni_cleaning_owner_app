import 'dart:convert';

Map<String, dynamic> _map(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  return const <String, dynamic>{};
}

int? _int(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

double? _double(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '');
}

bool? _bool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  final normalized = value?.toString().trim().toLowerCase();
  if (normalized == 'true' || normalized == '1') return true;
  if (normalized == 'false' || normalized == '0') return false;
  return null;
}

String? _string(dynamic value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

Map<String, dynamic> _bookingMap(Map<String, dynamic> root) {
  for (final key in const ['data', 'order', 'booking']) {
    final candidate = root[key];
    if (candidate is Map) return _map(candidate);
  }
  return root;
}

class WorkerSessionAssignmentModel {
  final int? id;
  final int? parentAssignmentId;
  final int? workerId;
  final String? workerName;
  final String? status;
  final String? startedTravelAt;
  final String? arrivedAt;
  final String? locationUpdatedAt;
  final double? lastLatitude;
  final double? lastLongitude;
  final String? startApprovedAt;
  final String? workStartedAt;
  final String? workFinishedAt;
  final String? workerCompletionMessage;
  final double? serviceShareAmount;
  final double? travelFee;
  final double? adminMarginAmount;
  final double? workerAmount;
  final double? totalHours;
  final double? grossAmount;
  final double? netAmount;
  final String? currency;

  const WorkerSessionAssignmentModel({
    this.id,
    this.parentAssignmentId,
    this.workerId,
    this.workerName,
    this.status,
    this.startedTravelAt,
    this.arrivedAt,
    this.locationUpdatedAt,
    this.lastLatitude,
    this.lastLongitude,
    this.startApprovedAt,
    this.workStartedAt,
    this.workFinishedAt,
    this.workerCompletionMessage,
    this.serviceShareAmount,
    this.travelFee,
    this.adminMarginAmount,
    this.workerAmount,
    this.totalHours,
    this.grossAmount,
    this.netAmount,
    this.currency,
  });

  factory WorkerSessionAssignmentModel.fromJson(Map<String, dynamic> json) {
    return WorkerSessionAssignmentModel(
      id: _int(json['id'] ?? json['assignmentId'] ?? json['assignment_id']),
      parentAssignmentId: _int(
        json['parentAssignmentId'] ?? json['parent_assignment_id'],
      ),
      workerId: _int(json['workerId'] ?? json['worker_id']),
      workerName: _string(json['workerName'] ?? json['worker_name']),
      status: _string(json['status']),
      startedTravelAt: _string(
        json['startedTravelAt'] ?? json['started_travel_at'],
      ),
      arrivedAt: _string(json['arrivedAt'] ?? json['arrived_at']),
      locationUpdatedAt: _string(
        json['locationUpdatedAt'] ?? json['location_updated_at'],
      ),
      lastLatitude: _double(json['lastLatitude'] ?? json['last_latitude']),
      lastLongitude: _double(json['lastLongitude'] ?? json['last_longitude']),
      startApprovedAt: _string(
        json['startApprovedAt'] ?? json['start_approved_at'],
      ),
      workStartedAt: _string(json['workStartedAt'] ?? json['work_started_at']),
      workFinishedAt: _string(
        json['workFinishedAt'] ?? json['work_finished_at'],
      ),
      workerCompletionMessage: _string(
        json['workerCompletionMessage'] ?? json['worker_completion_message'],
      ),
      serviceShareAmount: _double(
        json['serviceShareAmount'] ?? json['service_share_amount'],
      ),
      travelFee: _double(json['travelFee'] ?? json['travel_fee']),
      adminMarginAmount: _double(
        json['adminMarginAmount'] ?? json['admin_margin_amount'],
      ),
      workerAmount: _double(json['workerAmount'] ?? json['worker_amount']),
      totalHours: _double(json['totalHours'] ?? json['total_hours']),
      grossAmount: _double(
        json['grossAmount'] ??
            json['gross_amount'] ??
            json['workerGrossTotal'] ??
            json['worker_gross_total'],
      ),
      netAmount: _double(
        json['netAmount'] ??
            json['net_amount'] ??
            json['workerNetTotal'] ??
            json['worker_net_total'],
      ),
      currency: _string(json['currency']),
    );
  }
}

class WorkerSessionPricingModel {
  final double? basePrice;
  final double? travelFee;
  final double? travelDistanceKm;
  final double? adminMargin;
  final double? extensionFeeTotal;
  final double? cancellationFee;
  final double? totalPrice;
  final bool? isPricingFinal;
  final String? currency;

  const WorkerSessionPricingModel({
    this.basePrice,
    this.travelFee,
    this.travelDistanceKm,
    this.adminMargin,
    this.extensionFeeTotal,
    this.cancellationFee,
    this.totalPrice,
    this.isPricingFinal,
    this.currency,
  });

  factory WorkerSessionPricingModel.fromJson(Map<String, dynamic> json) {
    return WorkerSessionPricingModel(
      basePrice: _double(json['basePrice'] ?? json['base_price']),
      travelFee: _double(json['travelFee'] ?? json['travel_fee']),
      travelDistanceKm: _double(
        json['travelDistanceKm'] ?? json['travel_distance_km'],
      ),
      adminMargin: _double(json['adminMargin'] ?? json['admin_margin']),
      extensionFeeTotal: _double(
        json['extensionFeeTotal'] ?? json['extension_fee_total'],
      ),
      cancellationFee: _double(
        json['cancellationFee'] ?? json['cancellation_fee'],
      ),
      totalPrice: _double(json['totalPrice'] ?? json['total_price']),
      isPricingFinal: _bool(json['isPricingFinal'] ?? json['is_pricing_final']),
      currency: _string(json['currency']),
    );
  }
}

class WorkerSessionFinancialModel {
  final double? baseAmount;
  final double? travelAmount;
  final double? extensionAmount;
  final double? cancellationAmount;
  final double? grossAmount;
  final double? netAmount;
  final String? currency;

  const WorkerSessionFinancialModel({
    this.baseAmount,
    this.travelAmount,
    this.extensionAmount,
    this.cancellationAmount,
    this.grossAmount,
    this.netAmount,
    this.currency,
  });

  factory WorkerSessionFinancialModel.fromJson(Map<String, dynamic> json) {
    return WorkerSessionFinancialModel(
      baseAmount: _double(json['baseAmount'] ?? json['base_amount']),
      travelAmount: _double(json['travelAmount'] ?? json['travel_amount']),
      extensionAmount: _double(
        json['extensionAmount'] ?? json['extension_amount'],
      ),
      cancellationAmount: _double(
        json['cancellationAmount'] ?? json['cancellation_amount'],
      ),
      grossAmount: _double(json['grossAmount'] ?? json['gross_amount']),
      netAmount: _double(json['netAmount'] ?? json['net_amount']),
      currency: _string(json['currency']),
    );
  }
}

class WorkerBookingSessionModel {
  final int? id;
  final int sequence;
  final DateTime? date;
  final String? time;
  final double hours;
  final String status;
  final String? statusLabel;
  final bool isToday;
  final bool isPast;
  final bool canStartTravel;
  final bool canArrive;
  final bool canStartWork;
  final bool canComplete;
  final bool canExtend;
  final bool canCancel;
  final String? startedTravelAt;
  final String? arrivedAt;
  final String? customerConfirmedAt;
  final String? workStartedAt;
  final String? workFinishedAt;
  final String? cancelledAt;
  final String? cancellationReason;
  final String? cancelledByRole;
  final WorkerSessionPricingModel? pricing;
  final WorkerSessionAssignmentModel? workerAssignmentState;
  final List<WorkerSessionAssignmentModel> workerAssignments;
  final WorkerSessionFinancialModel? financial;

  const WorkerBookingSessionModel({
    this.id,
    required this.sequence,
    this.date,
    this.time,
    required this.hours,
    required this.status,
    this.statusLabel,
    required this.isToday,
    required this.isPast,
    required this.canStartTravel,
    required this.canArrive,
    required this.canStartWork,
    required this.canComplete,
    required this.canExtend,
    required this.canCancel,
    this.startedTravelAt,
    this.arrivedAt,
    this.customerConfirmedAt,
    this.workStartedAt,
    this.workFinishedAt,
    this.cancelledAt,
    this.cancellationReason,
    this.cancelledByRole,
    this.pricing,
    this.workerAssignmentState,
    this.workerAssignments = const <WorkerSessionAssignmentModel>[],
    this.financial,
  });

  factory WorkerBookingSessionModel.fromJson(Map<String, dynamic> json) {
    final assignmentStateRaw =
        json['workerAssignmentState'] ??
        json['worker_assignment_state'] ??
        json['myAssignment'] ??
        json['my_assignment'] ??
        json['assignment'];
    final assignmentsRaw =
        json['workerAssignments'] ?? json['worker_assignments'];
    final financialRaw = json['financial'] ?? json['workerFinancial'];

    return WorkerBookingSessionModel(
      id: _int(json['id']),
      sequence: _int(json['sequence']) ?? 1,
      date: DateTime.tryParse(_string(json['date']) ?? ''),
      time: _string(json['time']),
      hours:
          _double(
            json['hours'] ?? json['durationHours'] ?? json['duration_hours'],
          ) ??
          0,
      status: _string(json['status']) ?? 'scheduled',
      statusLabel: _string(json['statusLabel'] ?? json['status_label']),
      isToday: _bool(json['isToday'] ?? json['is_today']) ?? false,
      isPast: _bool(json['isPast'] ?? json['is_past']) ?? false,
      canStartTravel:
          _bool(json['canStartTravel'] ?? json['can_start_travel']) ??
          _bool(json['canStart'] ?? json['can_start']) ??
          false,
      canArrive: _bool(json['canArrive'] ?? json['can_arrive']) ?? false,
      canStartWork:
          _bool(json['canStartWork'] ?? json['can_start_work']) ?? false,
      canComplete: _bool(json['canComplete'] ?? json['can_complete']) ?? false,
      canExtend: _bool(json['canExtend'] ?? json['can_extend']) ?? false,
      canCancel: _bool(json['canCancel'] ?? json['can_cancel']) ?? false,
      startedTravelAt: _string(
        json['startedTravelAt'] ?? json['started_travel_at'],
      ),
      arrivedAt: _string(json['arrivedAt'] ?? json['arrived_at']),
      customerConfirmedAt: _string(
        json['customerConfirmedAt'] ?? json['customer_confirmed_at'],
      ),
      workStartedAt: _string(json['workStartedAt'] ?? json['work_started_at']),
      workFinishedAt: _string(
        json['workFinishedAt'] ?? json['work_finished_at'],
      ),
      cancelledAt: _string(json['cancelledAt'] ?? json['cancelled_at']),
      cancellationReason: _string(
        json['cancellationReason'] ?? json['cancellation_reason'],
      ),
      cancelledByRole: _string(
        json['cancelledByRole'] ?? json['cancelled_by_role'],
      ),
      pricing: json['pricing'] is Map
          ? WorkerSessionPricingModel.fromJson(_map(json['pricing']))
          : null,
      workerAssignmentState: assignmentStateRaw is Map
          ? WorkerSessionAssignmentModel.fromJson(_map(assignmentStateRaw))
          : null,
      workerAssignments: assignmentsRaw is List
          ? assignmentsRaw
                .whereType<Map>()
                .map(
                  (item) => WorkerSessionAssignmentModel.fromJson(_map(item)),
                )
                .toList(growable: false)
          : const <WorkerSessionAssignmentModel>[],
      financial: financialRaw is Map
          ? WorkerSessionFinancialModel.fromJson(_map(financialRaw))
          : null,
    );
  }

  WorkerSessionAssignmentModel? get assignment => workerAssignmentState;
  bool get canStart => canStartTravel;
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
  bool get isTerminal =>
      isCompleted || isCancelled || status == 'under_dispute';
  bool get isInProgress => status == 'in_progress';
  bool get isAwaitingStartVerification =>
      status == 'awaiting_start_verification';
  bool get isAwaitingWorkerStartConfirmation =>
      status == 'awaiting_worker_start_confirmation';
  bool get isAwaitingCustomerCompletion =>
      status == 'awaiting_customer_completion';
}

class WorkerBookingScheduleModel {
  final String mode;
  final int daysCount;
  final int completedDaysCount;
  final int cancelledDaysCount;
  final int remainingDaysCount;
  final double totalHours;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final WorkerBookingSessionModel? nextSession;
  final List<WorkerBookingSessionModel> sessions;

  const WorkerBookingScheduleModel({
    required this.mode,
    required this.daysCount,
    required this.completedDaysCount,
    required this.cancelledDaysCount,
    required this.remainingDaysCount,
    required this.totalHours,
    this.firstDate,
    this.lastDate,
    this.nextSession,
    this.sessions = const <WorkerBookingSessionModel>[],
  });

  factory WorkerBookingScheduleModel.fromJson(Map<String, dynamic> json) {
    final rawSessions = json['sessions'];
    final sessions = rawSessions is List
        ? rawSessions
              .whereType<Map>()
              .map((item) => WorkerBookingSessionModel.fromJson(_map(item)))
              .toList(growable: false)
        : const <WorkerBookingSessionModel>[];
    final rawNext = json['nextSession'] ?? json['next_session'];

    return WorkerBookingScheduleModel(
      mode:
          _string(json['mode']) ??
          (sessions.length > 1 ? 'multi_day' : 'single_day'),
      daysCount:
          _int(json['daysCount'] ?? json['days_count']) ?? sessions.length,
      completedDaysCount:
          _int(json['completedDaysCount'] ?? json['completed_days_count']) ??
          sessions.where((item) => item.isCompleted).length,
      cancelledDaysCount:
          _int(json['cancelledDaysCount'] ?? json['cancelled_days_count']) ??
          sessions.where((item) => item.isCancelled).length,
      remainingDaysCount:
          _int(json['remainingDaysCount'] ?? json['remaining_days_count']) ??
          sessions.where((item) => !item.isTerminal).length,
      totalHours:
          _double(json['totalHours'] ?? json['total_hours']) ??
          sessions
              .where((item) => !item.isCancelled)
              .fold<double>(0, (sum, item) => sum + item.hours),
      firstDate: DateTime.tryParse(
        _string(json['firstDate'] ?? json['first_date']) ?? '',
      ),
      lastDate: DateTime.tryParse(
        _string(json['lastDate'] ?? json['last_date']) ?? '',
      ),
      nextSession: rawNext is Map
          ? WorkerBookingSessionModel.fromJson(_map(rawNext))
          : null,
      sessions: sessions,
    );
  }

  bool get isMultiDay => mode == 'multi_day' || sessions.length > 1;

  WorkerBookingSessionModel? sessionById(int? sessionId) {
    if (sessionId == null) return null;
    for (final session in sessions) {
      if (session.id == sessionId) return session;
    }
    return null;
  }
}

class WorkerMultiDayBookingEnvelope {
  final int? bookingId;
  final String? bookingNumber;
  final String? status;
  final WorkerBookingScheduleModel? schedule;
  final WorkerBookingSessionModel? session;

  const WorkerMultiDayBookingEnvelope({
    this.bookingId,
    this.bookingNumber,
    this.status,
    this.schedule,
    this.session,
  });

  factory WorkerMultiDayBookingEnvelope.fromJson(Map<String, dynamic> root) {
    final booking = _bookingMap(root);
    final scheduleRaw = booking['schedule'];
    final sessionRaw = root['session'];
    return WorkerMultiDayBookingEnvelope(
      bookingId: _int(booking['id']),
      bookingNumber: _string(
        booking['bookingNumber'] ?? booking['booking_number'],
      ),
      status: _string(booking['status']),
      schedule: scheduleRaw is Map
          ? WorkerBookingScheduleModel.fromJson(_map(scheduleRaw))
          : null,
      session: sessionRaw is Map
          ? WorkerBookingSessionModel.fromJson(_map(sessionRaw))
          : null,
    );
  }
}

WorkerMultiDayBookingEnvelope workerMultiDayBookingEnvelopeFromJson(
  dynamic json,
) {
  if (json is String) {
    return WorkerMultiDayBookingEnvelope.fromJson(_map(jsonDecode(json)));
  }
  return WorkerMultiDayBookingEnvelope.fromJson(_map(json));
}
