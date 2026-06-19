import 'dart:convert';

Map<String, dynamic> _map(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, val) => MapEntry(key.toString(), val));
  }
  return <String, dynamic>{};
}

dynamic _pick(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final value = map[key];
    if (value != null) return value;
  }
  return null;
}

bool? _bool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value == 1 ? true : value == 0 ? false : null;
  final normalized = value?.toString().trim().toLowerCase();
  if (normalized == 'true' || normalized == '1') return true;
  if (normalized == 'false' || normalized == '0') return false;
  return null;
}

String? _string(dynamic value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

CompletionRequestModel completionRequestModelFromJson(dynamic json) =>
    CompletionRequestModel.fromJson(_map(json));

String completionRequestModelToJson(CompletionRequestModel data) =>
    jsonEncode(data.toJson());

class CompletionRequestModel {
  final bool? isAwaitingCustomerConfirmation;
  final String? message;
  final String? requestedAt;
  final String? expiresAt;
  final CompletionRequestActionsModel? actions;

  const CompletionRequestModel({
    this.isAwaitingCustomerConfirmation,
    this.message,
    this.requestedAt,
    this.expiresAt,
    this.actions,
  });

  factory CompletionRequestModel.fromJson(Map<String, dynamic> json) {
    final actionPayload = _pick(json, const <String>['actions']);

    return CompletionRequestModel(
      isAwaitingCustomerConfirmation: _bool(_pick(json, const <String>[
        'isAwaitingCustomerConfirmation',
        'is_awaiting_customer_confirmation',
      ])),
      message: _string(_pick(json, const <String>['message'])),
      requestedAt: _string(_pick(json, const <String>[
        'requestedAt',
        'requested_at',
      ])),
      expiresAt: _string(_pick(json, const <String>[
        'expiresAt',
        'expires_at',
      ])),
      actions: actionPayload is Map
          ? CompletionRequestActionsModel.fromJson(_map(actionPayload))
          : null,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'isAwaitingCustomerConfirmation': isAwaitingCustomerConfirmation,
        'message': message,
        'requestedAt': requestedAt,
        'expiresAt': expiresAt,
        'actions': actions?.toJson(),
      };
}

class CompletionRequestActionsModel {
  final bool? canConfirm;
  final bool? canDecline;
  final bool? canRequestExtension;

  const CompletionRequestActionsModel({
    this.canConfirm,
    this.canDecline,
    this.canRequestExtension,
  });

  factory CompletionRequestActionsModel.fromJson(Map<String, dynamic> json) {
    return CompletionRequestActionsModel(
      canConfirm: _bool(_pick(json, const <String>[
        'canConfirm',
        'can_confirm',
        'confirm',
      ])),
      canDecline: _bool(_pick(json, const <String>[
        'canReject',
        'can_reject',
        'reject',
      ])),
      canRequestExtension: _bool(_pick(json, const <String>[
        'canRequestExtension',
        'can_request_extension',
        'requestExtension',
        'request_extension',
      ])),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'canConfirm': canConfirm,
        'canReject': canDecline,
        'canRequestExtension': canRequestExtension,
      };
}
