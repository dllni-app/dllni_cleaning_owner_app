import 'dart:convert';

import 'fetch_deposit_account_usecase_model.dart';

Map<String, dynamic> _toMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, val) => MapEntry(key.toString(), val));
  }
  return <String, dynamic>{};
}

dynamic _pick(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    if (!map.containsKey(key)) continue;
    final value = map[key];
    if (value != null) return value;
  }
  return null;
}

bool? _toBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) {
    if (value == 1) return true;
    if (value == 0) return false;
  }
  final normalized = value?.toString().trim().toLowerCase();
  if (normalized == 'true' || normalized == '1') return true;
  if (normalized == 'false' || normalized == '0') return false;
  return null;
}

int? _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? double.tryParse(value)?.toInt();
  return null;
}

String? _toStringValue(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

WorkerDispatchEligibilityModel workerDispatchEligibilityModelFromJson(
  dynamic json,
) => WorkerDispatchEligibilityModel.fromJson(_toMap(json));

String workerDispatchEligibilityModelToJson(
  WorkerDispatchEligibilityModel data,
) => jsonEncode(data.toJson());

class WorkerDispatchEligibilityModel {
  final bool? canReceiveNewRequests;
  final bool? canAcceptNewBookings;
  final bool? canStartAssignedWork;
  final String? status;
  final String? reasonCode;
  final String? startWorkReasonCode;
  final String? title;
  final String? message;
  final FetchDepositAccountUsecaseModel? depositSummary;
  final int? availableNewOrdersCount;
  final int? blockedNewOrdersCount;

  const WorkerDispatchEligibilityModel({
    this.canReceiveNewRequests,
    this.canAcceptNewBookings,
    this.canStartAssignedWork,
    this.status,
    this.reasonCode,
    this.startWorkReasonCode,
    this.title,
    this.message,
    this.depositSummary,
    this.availableNewOrdersCount,
    this.blockedNewOrdersCount,
  });

  factory WorkerDispatchEligibilityModel.fromJson(Map<String, dynamic> json) {
    final depositJson = _pick(json, const <String>[
      'depositSummary',
      'deposit_summary',
    ]);

    return WorkerDispatchEligibilityModel(
      canReceiveNewRequests: _toBool(
        _pick(json, const <String>[
          'canReceiveNewRequests',
          'can_receive_new_requests',
        ]),
      ),
      canAcceptNewBookings: _toBool(
        _pick(json, const <String>[
          'canAcceptNewBookings',
          'can_accept_new_bookings',
        ]),
      ),
      canStartAssignedWork: _toBool(
        _pick(json, const <String>[
          'canStartAssignedWork',
          'can_start_assigned_work',
        ]),
      ),
      status: _toStringValue(_pick(json, const <String>['status'])),
      reasonCode: _toStringValue(
        _pick(json, const <String>['reasonCode', 'reason_code']),
      ),
      startWorkReasonCode: _toStringValue(
        _pick(json, const <String>[
          'startWorkReasonCode',
          'start_work_reason_code',
        ]),
      ),
      title: _toStringValue(_pick(json, const <String>['title'])),
      message: _toStringValue(_pick(json, const <String>['message'])),
      depositSummary: depositJson is Map
          ? FetchDepositAccountUsecaseModel.fromJson(_toMap(depositJson))
          : null,
      availableNewOrdersCount: _toInt(
        _pick(json, const <String>[
          'availableNewOrdersCount',
          'available_new_orders_count',
        ]),
      ),
      blockedNewOrdersCount: _toInt(
        _pick(json, const <String>[
          'blockedNewOrdersCount',
          'blocked_new_orders_count',
        ]),
      ),
    );
  }

  bool get blocksNewRequests =>
      canReceiveNewRequests == false || canAcceptNewBookings == false;

  String get effectiveReasonCode =>
      (reasonCode ?? status ?? 'not_eligible').trim().toLowerCase();

  String get userMessageAr {
    switch (effectiveReasonCode) {
      case 'eligible':
        return 'حسابك جاهز لاستقبال وقبول الطلبات الجديدة.';
      case 'worker_inactive':
        return 'حسابك غير مفعل حالياً. فعّل الحساب لاستقبال الطلبات الجديدة.';
      case 'worker_suspended':
        return 'حسابك موقوف مؤقتاً. يرجى التواصل مع الدعم لمعرفة التفاصيل.';
      case 'trust_score_too_low':
        return 'درجة الثقة أقل من الحد المطلوب لاستقبال الطلبات الجديدة.';
      case 'deposit_required_before_start':
        return 'رصيد التأمين أقل من الحد المطلوب لبدء العمل.';
      case 'deposit_below_allowed_balance':
        return 'رصيد التأمين أقل من الحد المسموح. يرجى شحن حساب التأمين لاستقبال الطلبات الجديدة.';
      case 'insufficient_commission_capacity':
        final blockedCount = blockedNewOrdersCount ?? 0;
        final countText = blockedCount > 0 ? ' يوجد $blockedCount طلب غير ظاهر حالياً.' : '';
        return 'رصيد التأمين المتاح لا يغطي عمولة بعض الطلبات الجديدة.$countText يرجى شحن حساب التأمين أو انتظار تحرير العمولة المحجوزة.';
      default:
        return 'لا يمكن لحسابك استقبال الطلبات الجديدة حالياً.';
    }
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'canReceiveNewRequests': canReceiveNewRequests,
      'canAcceptNewBookings': canAcceptNewBookings,
      'canStartAssignedWork': canStartAssignedWork,
      'status': status,
      'reasonCode': reasonCode,
      'startWorkReasonCode': startWorkReasonCode,
      'title': title,
      'message': message,
      'depositSummary': depositSummary?.toJson(),
      'availableNewOrdersCount': availableNewOrdersCount,
      'blockedNewOrdersCount': blockedNewOrdersCount,
    };
  }
}
