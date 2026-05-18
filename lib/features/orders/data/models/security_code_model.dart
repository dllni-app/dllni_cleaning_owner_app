import 'dart:convert';

SecurityCodeModel securityCodeModelFromJson(dynamic str) {
  final map = str is String
      ? json.decode(str) as Map<String, dynamic>
      : Map<String, dynamic>.from(str as Map);
  return SecurityCodeModel.fromJson(map);
}

class SecurityCodeModel {
  SecurityCodeModel({this.data});

  SecurityCodeData? data;

  factory SecurityCodeModel.fromJson(Map<String, dynamic> json) {
    if (json['data'] is Map) {
      final parsed = SecurityCodeData.fromJson(
        Map<String, dynamic>.from(json['data'] as Map),
      );
      if (parsed.hasCode) {
        return SecurityCodeModel(data: parsed);
      }
    }

    final flat = SecurityCodeData.tryParseFromMap(json);
    if (flat != null) {
      return SecurityCodeModel(data: flat);
    }

    return SecurityCodeModel();
  }

  /// Parses a security code embedded in arrive / booking payloads.
  static SecurityCodeModel? tryFromBookingPayload(Map<String, dynamic> json) {
    final parsed = SecurityCodeData.tryParseFromBookingPayload(json);
    if (parsed == null || !parsed.hasCode) return null;
    return SecurityCodeModel(data: parsed);
  }
}

class SecurityCodeData {
  SecurityCodeData({this.securityCode, this.expiresAt});

  String? securityCode;
  String? expiresAt;

  bool get hasCode =>
      securityCode != null && securityCode!.trim().isNotEmpty;

  factory SecurityCodeData.fromJson(Map<String, dynamic> json) {
    return tryParseFromMap(json) ?? SecurityCodeData();
  }

  static SecurityCodeData? tryParseFromBookingPayload(Map<String, dynamic> json) {
    return _parseFromMap(
      json,
      const <String>[
        'securityCode',
        'security_code',
        'verificationCode',
        'verification_code',
      ],
    );
  }

  static SecurityCodeData? tryParseFromMap(Map<String, dynamic> json) {
    return _parseFromMap(
      json,
      const <String>[
        'securityCode',
        'security_code',
        'verificationCode',
        'verification_code',
        'code',
      ],
    );
  }

  static SecurityCodeData? _parseFromMap(
    Map<String, dynamic> json,
    List<String> codeKeys,
  ) {
    final code = _pick(json, codeKeys);
    final expiresAt = _pick(json, const <String>[
      'expiresAt',
      'expires_at',
      'securityCodeExpiresAt',
      'security_code_expires_at',
    ]);

    if (code == null && expiresAt == null) {
      return null;
    }

    final normalizedCode = code?.toString().trim();
    return SecurityCodeData(
      securityCode:
          normalizedCode == null || normalizedCode.isEmpty
              ? null
              : normalizedCode,
      expiresAt: expiresAt?.toString(),
    );
  }
}

dynamic _pick(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    if (!map.containsKey(key)) continue;
    final value = map[key];
    if (value != null) return value;
  }
  return null;
}
