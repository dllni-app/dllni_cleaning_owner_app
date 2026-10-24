import '../contracts/common.dart';
import '../contracts/models.dart';
import '../contracts/navigation.dart';
import '../contracts/requests.dart';
import 'transport.dart';

/// Strict V2 fixture DTO decoders. Field names describe the proposed S02 wire
/// contract and are not evidence that the running backend serves them yet.
class WorkerWireMappers {
  const WorkerWireMappers._();

  static Map<String, Object?> object(Object? input) {
    if (input is! Map || input.keys.any((key) => key is! String)) {
      throw const WireContractException();
    }
    return input.cast<String, Object?>();
  }

  static List<Object?> list(Object? input) {
    if (input is! List) throw const WireContractException();
    return input.cast<Object?>();
  }

  static String string(Object? value) {
    if (value is String && value.trim().isNotEmpty) return value;
    throw const WireContractException();
  }

  static String? nullableString(Object? value) =>
      value == null ? null : string(value);

  static bool boolean(Object? value) {
    if (value is bool) return value;
    throw const WireContractException();
  }

  static int integer(Object? value) {
    if (value is int) return value;
    throw const WireContractException();
  }

  static String safeStatus(Object? value, Set<String> known) {
    if (value is! String) return 'unknown';
    return known.contains(value) ? value : 'unknown';
  }

  static const assignmentStatuses = {
    'pending',
    'accepted',
    'assigned',
    'completed',
    'cancelled',
    'rejected',
    'in_progress',
    'active',
    'unassigned',
  };

  static DateTime? instant(Object? raw) {
    if (raw == null) return null;
    final value = string(raw);
    if (!RegExp(r'(Z|[+-]\d\d:\d\d)$').hasMatch(value)) {
      throw const WireContractException();
    }
    final parsed = DateTime.tryParse(value);
    if (parsed == null) throw const WireContractException();
    return parsed.toUtc();
  }

  static DateTime requiredInstant(Object? raw) =>
      instant(raw) ?? (throw const WireContractException());

  static String businessDate(Object? raw) {
    final value = string(raw);
    DateRange(from: value, to: value);
    return value;
  }

  static List<String> strings(Object? value) =>
      list(value).map(string).toList(growable: false);

  static Map<String, String> stringMap(Object? value) =>
      object(value).map((key, value) => MapEntry(key, string(value)));

  static Map<String, String?> nullableStringMap(Object? value) =>
      object(value).map((key, value) => MapEntry(key, nullableString(value)));

  static MoneyValue? money(Object? value) {
    if (value == null) return null;
    final map = object(value);
    // Never round binary floats or substitute zero for missing money.
    if (map['decimal'] is! String) throw const WireContractException();
    return MoneyValue(
      decimal: string(map['decimal']),
      currency: string(map['currency']),
    );
  }

  static WorkScope scope(Object? value) {
    final map = object(value);
    return WorkScope(
      bookingId: string(map['bookingId']),
      sessionId: nullableString(map['sessionId']),
      assignmentId: nullableString(map['assignmentId']),
    );
  }

  static WorkSummary work(Object? value) {
    final map = object(value);
    return WorkSummary(
      label: string(map['label']),
      type: string(map['type']),
      area: nullableString(map['area']),
      locationSummary: nullableString(map['locationSummary']),
    );
  }

  static OperationalContext operational(Object? value) {
    final map = object(value);
    final rawOwner = map['executionOwner'];
    final owner = rawOwner == 'worker'
        ? ExecutionOwner.worker
        : rawOwner == 'supervisor'
        ? ExecutionOwner.supervisor
        : null;
    final rawActions = strings(map['allowedActions']);
    final actions = rawActions
        .map(WorkerAction.fromWire)
        .whereType<WorkerAction>()
        .toSet();
    final unknownAction = actions.length != rawActions.length;
    final reasons = strings(map['blockedReasons']).toSet();
    final unknownReasons = !blockedReasonCodes.containsAll(reasons);
    final validReasons = reasons.intersection(blockedReasonCodes);
    if (unknownAction || unknownReasons || owner == null) {
      validReasons.add('unavailable');
    }
    final reportedCapability = boolean(map['executionCapability']);
    final reportedAttendance = boolean(map['canRecordAttendance']);
    // Unrecognized capabilities cannot enable lifecycle or attendance.
    final trusted = owner != null && !unknownAction && !unknownReasons;
    final execution =
        trusted && owner == ExecutionOwner.worker && reportedCapability;
    return OperationalContext(
      executionOwner: owner,
      executionCapability: execution,
      allowedActions: trusted ? actions : const {},
      blockedReasons: validReasons,
      canRecordAttendance: trusted && reportedAttendance,
    );
  }

  static OperationalContext _guardStatus(
    OperationalContext context,
    String status,
    String assignmentStatus,
  ) {
    if (status != 'unknown' && assignmentStatus != 'unknown') return context;
    return OperationalContext(
      executionOwner: context.executionOwner,
      executionCapability: false,
      allowedActions: const {},
      blockedReasons: {...context.blockedReasons, 'unavailable'},
      canRecordAttendance: false,
    );
  }

  static Page<T> page<T>(Object? value, T Function(Object?) mapper) {
    final envelope = object(value);
    final meta = object(envelope['meta']);
    return Page<T>(
      items: list(envelope['data']).map(mapper).toList(growable: false),
      page: integer(meta['page']),
      lastPage: integer(meta['lastPage']),
      total: integer(meta['total']),
    );
  }

  static ReadinessView readiness(Object? value) {
    final map = object(value);
    return ReadinessView(
      accountState: string(map['accountState']),
      completenessItems: strings(map['completenessItems']),
      canReceiveRequests: boolean(map['canReceiveRequests']),
      financialRestrictionCodes: strings(map['financialRestrictionCodes']),
      remedyDestinations: stringMap(map['remedyDestinations']),
    );
  }

  static WorkerProfileView profile(Object? value) {
    final map = object(value);
    return WorkerProfileView(
      workerId: string(map['workerId']),
      displayName: string(map['displayName']),
      accountState: string(map['accountState']),
      editableValues: nullableStringMap(map['editableValues']),
      workPreferences: stringMap(map['workPreferences']),
      phone: nullableString(map['phone']),
      reviewAverage: nullableString(map['reviewAverage']),
      trustScore: map['trustScore'] == null ? null : integer(map['trustScore']),
    );
  }

  static WorkingHoursSlot workingHoursSlot(Object? value) {
    final map = object(value);
    return WorkingHoursSlot(
      day: integer(map['day']),
      startLocalTime: string(map['startLocalTime']),
      endLocalTime: string(map['endLocalTime']),
    );
  }

  static StartLocationDraft startLocation(Object? value) {
    final map = object(value);
    final lat = map['latitude'];
    final lng = map['longitude'];
    if ((lat != null && lat is! num) || (lng != null && lng is! num)) {
      throw const WireContractException();
    }
    return StartLocationDraft(
      source: string(map['source']),
      latitude: (lat as num?)?.toDouble(),
      longitude: (lng as num?)?.toDouble(),
      savedLocationId: nullableString(map['savedLocationId']),
    );
  }

  static OfferView offer(Object? value) {
    final map = object(value);
    return OfferView(
      bookingId: string(map['bookingId']),
      bookingType: string(map['bookingType']),
      discoverable: boolean(map['discoverable']),
      eligible: boolean(map['eligible']),
      work: work(map['work']),
      acceptanceModes: strings(map['acceptanceModes']),
      visitChoices: list(map['visitChoices']).map(scope).toList(),
      pricingIsFinal: boolean(map['pricingIsFinal']),
      workerAmount: money(map['workerAmount']),
    );
  }

  static JobSummaryView job(Object? value) {
    final map = object(value);
    return JobSummaryView(
      bookingId: string(map['bookingId']),
      reference: string(map['reference']),
      bookingStatus: safeStatus(map['bookingStatus'], assignmentStatuses),
      ownAssignmentStatus: safeStatus(
        map['ownAssignmentStatus'],
        assignmentStatuses,
      ),
      work: work(map['work']),
      visitCount: map['visitCount'] == null ? null : integer(map['visitCount']),
    );
  }

  static AgendaItemView agendaItem(Object? value) {
    final map = object(value);
    final status = safeStatus(map['status'], assignmentStatuses);
    final ownAssignmentStatus = safeStatus(
      map['ownAssignmentStatus'],
      assignmentStatuses,
    );
    return AgendaItemView(
      key: string(map['key']),
      scope: scope(map['scope']),
      scheduledDate: businessDate(map['scheduledDate']),
      status: status,
      ownAssignmentStatus: ownAssignmentStatus,
      work: work(map['work']),
      operational: _guardStatus(
        operational(map['operationalContext']),
        status,
        ownAssignmentStatus,
      ),
      startsAt: instant(map['startsAt']),
      endsAt: instant(map['endsAt']),
      taskIntervalLabel: nullableString(map['taskIntervalLabel']),
    );
  }

  static AgendaView agenda(Object? value) {
    final map = object(value);
    final summary = object(map['summary']);
    return AgendaView(
      items: page<AgendaItemView>(map, agendaItem),
      timezone: string(map['timezone']),
      activeVisits: integer(summary['activeVisits']),
      nextVisit: summary['nextVisit'] == null
          ? null
          : agendaItem(summary['nextVisit']),
    );
  }

  static MissionView mission(Object? value) {
    final map = object(value);
    final status = safeStatus(map['status'], assignmentStatuses);
    final ownAssignmentStatus = safeStatus(
      map['ownAssignmentStatus'],
      assignmentStatuses,
    );
    return MissionView(
      scope: scope(map['scope']),
      status: status,
      stage: string(map['stage']),
      ownAssignmentStatus: ownAssignmentStatus,
      operational: _guardStatus(
        operational(map['operationalContext']),
        status,
        ownAssignmentStatus,
      ),
      ownServices: strings(map['ownServices']),
      serviceLines: map['serviceLines'] == null
          ? const []
          : list(map['serviceLines']).map(_missionServiceLine).toList(),
      ownRooms: strings(map['ownRooms']),
      waitingReasons: strings(map['waitingReasons']),
      customerPhone: nullableString(map['customerPhone']),
      customerLocation: nullableString(map['customerLocation']),
      verificationCode: nullableString(map['verificationCode']),
      startedAt: instant(map['startedAt']),
      expiresAt: instant(map['expiresAt']),
      billableStartAt: instant(map['billableStartAt']),
    );
  }

  static MissionServiceLineView _missionServiceLine(Object? value) {
    final map = object(value);
    return MissionServiceLineView(
      scope: scope(map['scope']),
      lineId: string(map['lineId']),
      label: string(map['label']),
      status: string(map['status']),
      allowedActions: strings(
        map['allowedActions'],
      ).map(WorkerAction.fromWire).whereType<WorkerAction>().toSet(),
    );
  }

  static InventoryView inventory(Object? value) {
    final map = object(value);
    return InventoryView(
      scope: scope(map['scope']),
      items: list(map['items']).map((value) {
        final item = object(value);
        return InventoryItemView(
          itemId: string(item['itemId']),
          reservationId: nullableString(item['reservationId']),
          name: string(item['name']),
          quantity: string(item['quantity']),
          custodyState: string(item['custodyState']),
          allowedActions: strings(
            item['allowedActions'],
          ).map(WorkerAction.fromWire).whereType<WorkerAction>().toSet(),
        );
      }).toList(),
    );
  }

  static DecisionView decision(Object? value) {
    final map = object(value);
    return DecisionView(
      requestId: string(map['requestId']),
      scope: scope(map['scope']),
      kind: string(map['kind']),
      status: string(map['status']),
      decisionActor: string(map['decisionActor']),
      extensionFamily: switch (map['extensionFamily']) {
        'fixedTimeWarning' => ExtensionRecordFamily.fixedTimeWarning,
        'openTimeExtension' => ExtensionRecordFamily.openTimeExtension,
        _ => null,
      },
      currentValues: nullableStringMap(map['currentValues']),
      proposedValues: nullableStringMap(map['proposedValues']),
      pricedAmount: money(map['pricedAmount']),
    );
  }

  static EarningEntryView earning(Object? value) {
    final map = object(value);
    return EarningEntryView(
      key: string(map['key']),
      scope: scope(map['scope']),
      completedDate: businessDate(map['completedDate']),
      currency: string(map['currency']),
      authoritativeAmount: money(map['authoritativeAmount']),
      reconciliationState: string(map['reconciliationState']),
      frozenBreakdown: object(
        map['frozenBreakdown'],
      ).map((key, value) => MapEntry(key, money(value))),
      financialState: nullableString(map['financialState']),
    );
  }

  static EarningsView earnings(Object? value) {
    final map = object(value);
    final summary = object(map['summary']);
    return EarningsView(
      entries: page<EarningEntryView>(map, earning),
      completedTotals: object(summary['completedTotals']).map(
        (key, value) => MapEntry(
          key,
          money(value) ?? (throw const WireContractException()),
        ),
      ),
      incompleteEntries: integer(summary['incompleteEntries']),
      periodLabel: string(summary['periodLabel']),
    );
  }

  static DepositView deposit(Object? value) {
    final map = object(value);
    return DepositView(
      accountStatus: string(map['accountStatus']),
      financiallyEligible: boolean(map['financiallyEligible']),
      restrictionCodes: strings(map['restrictionCodes']),
      remedyDestinations: stringMap(map['remedyDestinations']),
      currentBalance: money(map['currentBalance']),
      debtBalance: money(map['debtBalance']),
      minimumBalance: money(map['minimumBalance']),
      debtCapacity: money(map['debtCapacity']),
    );
  }

  static DepositLedgerEntryView depositEntry(Object? value) {
    final map = object(value);
    return DepositLedgerEntryView(
      id: string(map['id']),
      occurredAt: requiredInstant(map['occurredAt']),
      status: string(map['status']),
      amount: money(map['amount']) ?? (throw const WireContractException()),
      reference: nullableString(map['reference']),
    );
  }

  static DisputeView dispute(Object? value) {
    final map = object(value);
    return DisputeView(
      id: string(map['id']),
      scope: scope(map['scope']),
      status: string(map['status']),
      statusHistory: strings(map['statusHistory']),
      messages: list(map['messages']).map((value) {
        final msg = object(value);
        return DisputeMessageView(
          id: string(msg['id']),
          sentAt: requiredInstant(msg['sentAt']),
          body: string(msg['body']),
          senderLabel: string(msg['senderLabel']),
        );
      }).toList(),
      canReply: boolean(map['canReply']),
    );
  }

  static NotificationView notification(Object? value) {
    final map = object(value);
    // Only validated *selectors* are exposed. Root must still fetch/authorize
    // current worker's exact booking/visit before navigation renders content.
    final data = map['data'] is Map ? object(map['data']) : <String, Object?>{};
    final unavailable = data['state'] == 'unavailable' || data['actionable'] == false;
    final targetName = data['deep_link_target'] ?? data['deepLinkTarget'];
    RouteIntent? target;
    var targetState = NotificationTargetState.pending;
    if (unavailable) {
      targetState = NotificationTargetState.unavailable;
    } else if (targetName != null) {
      if (targetName is! String ||
          !const {'cleaning_booking_details', '/orderdetails',
                  '/transactiondetails', 'dispute_thread', '/emergencysos'}
              .contains(targetName)) {
        targetState = NotificationTargetState.unavailable;
      } else {
        final action = data['action'];
        final rawCanonical = map['canonicalType'] ?? map['canonical_type'];
        final isDispute = rawCanonical == 'cleaning.booking.dispute_opened' ||
            action == 'dispute_opened';
        final routeName = isDispute ? 'dispute_thread' : targetName;
        final identity = <String, Object?>{};
        var invalidIdentity = false;
        for (final name in const [
          'bookingId', 'booking_id', 'orderId', 'order_id',
          'sessionId', 'session_id', 'cleaningBookingSessionId',
          'cleaning_booking_session_id', 'assignmentId', 'assignment_id',
          'disputeId', 'dispute_id',
        ]) {
          if (!data.containsKey(name)) continue;
          final raw = data[name];
          if (raw is int && raw > 0) {
            identity[name] = raw;
          } else if (raw is String &&
              RegExp(r'^[A-Za-z0-9_-]{1,96}$').hasMatch(raw)) {
            identity[name] = raw;
          } else {
            invalidIdentity = true;
          }
        }
        if (invalidIdentity) {
          targetState = NotificationTargetState.unavailable;
        } else {
          final resolution = LegacyRouteAdapter.resolve(
              routeName, identity, origin: RouteOrigin.notification);
          if (resolution.isAvailable) {
            target = resolution.intent;
            targetState = NotificationTargetState.ready;
          } else {
            targetState = resolution.errorCode == 'target_invalid' ||
                    resolution.errorCode == 'target_unknown'
                ? NotificationTargetState.unavailable
                : NotificationTargetState.pending;
          }
        }
      }
    }
    const promptKinds = {'extension_request', 'schedule_change',
      'price_adjustment', 'completion_decision', 'open_time_end'};
    const promptStatuses = {'pending', 'active', 'needs_response',
      'expired', 'handled', 'completed', 'unavailable'};
    final kind = data['action'];
    final status = data['decisionStatus'] ?? data['decision_status'];
    final promptStatus = status == 'actionable' && data['actionable'] == true
        ? 'actionable'
        : status is String && promptStatuses.contains(status) ? status : null;
    final readValue = map['isRead'];
    final readTime = map['readAt'] ?? map['read_at'];
    if (readValue != null && readValue is! bool) {
      throw const WireContractException();
    }
    if (readTime != null) requiredInstant(readTime);
    return NotificationView(
      id: string(map['id']),
      title: string(map['title']),
      body: string(map['body']),
      sentAt: requiredInstant(map['sentAt'] ?? map['createdAt'] ?? map['created_at']),
      isRead: readValue is bool ? readValue : readTime != null,
      target: target,
      targetState: targetState,
      promptKind: kind is String && promptKinds.contains(kind) ? kind : null,
      promptStatus: promptStatus,
    );
  }

  /// Accepts the frozen V2 pagination shape and the existing Laravel
  /// JsonResource paginator aliases. It never drops unavailable notification
  /// items locally; visibility and ownership are backend responsibilities.
  static Page<NotificationView> notificationPage(Object? value) {
    final envelope = object(value);
    final meta = object(envelope['meta']);
    return Page<NotificationView>(
      items: list(envelope['data']).map(notification).toList(growable: false),
      page: integer(meta['page'] ?? meta['current_page']),
      lastPage: integer(meta['lastPage'] ?? meta['last_page']),
      total: integer(meta['total']),
    );
  }

  static SupportContactView supportContact(Object? value) {
    final map = object(value);
    return SupportContactView(
      label: string(map['label']),
      channel: string(map['channel']),
      value: string(map['value']),
    );
  }
}
