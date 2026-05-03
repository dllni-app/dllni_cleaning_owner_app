import 'dart:convert';

SecurityCodeModel securityCodeModelFromJson(dynamic str) {
  final map = str is String ? json.decode(str) as Map<String, dynamic> : Map<String, dynamic>.from(str as Map);
  return SecurityCodeModel.fromJson(map);
}

class SecurityCodeModel {
  SecurityCodeModel({this.data});

  SecurityCodeData? data;

  factory SecurityCodeModel.fromJson(Map<String, dynamic> json) {
    return SecurityCodeModel(
      data: json['data'] is Map ? SecurityCodeData.fromJson(Map<String, dynamic>.from(json['data'] as Map)) : null,
    );
  }
}

class SecurityCodeData {
  SecurityCodeData({this.securityCode, this.expiresAt});

  String? securityCode;
  String? expiresAt;

  factory SecurityCodeData.fromJson(Map<String, dynamic> json) {
    return SecurityCodeData(
      securityCode: json['securityCode']?.toString(),
      expiresAt: json['expiresAt']?.toString(),
    );
  }
}
