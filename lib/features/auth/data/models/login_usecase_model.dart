import 'dart:convert';

String? _asString(dynamic value) {
  if (value == null) return null;
  if (value is String) return value;
  if (value is num || value is bool) return value.toString();
  return null;
}

int? _asInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) {
    return int.tryParse(value) ?? double.tryParse(value)?.toInt();
  }
  return null;
}

double? _asDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

num? _asNum(dynamic value) {
  if (value == null) return null;
  if (value is num) return value;
  if (value is String) return num.tryParse(value);
  return null;
}

bool? _asBool(dynamic value) {
  if (value == null) return null;
  if (value is bool) return value;
  if (value is num) {
    if (value == 1) return true;
    if (value == 0) return false;
  }
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true' || normalized == '1') return true;
    if (normalized == 'false' || normalized == '0') return false;
  }
  return null;
}

List<dynamic>? _asDynamicList(dynamic value) {
  if (value is! List) return null;
  return value.map(_asDynamic).toList();
}

dynamic _asDynamic(dynamic value) {
  if (value == null) return null;
  if (value is List) {
    return value.map(_asDynamic).toList();
  }
  if (value is Map) {
    final map = <String, dynamic>{};
    value.forEach((key, nestedValue) {
      map['$key'] = _asDynamic(nestedValue);
    });
    return map;
  }
  if (value is String || value is num || value is bool) {
    return value;
  }
  return value.toString();
}

LoginUsecaseModel loginUsecaseModelFromJson(str) => LoginUsecaseModel.fromJson(str is String ? json.decode(str) : str);

String loginUsecaseModelToJson(LoginUsecaseModel data) => json.encode(data.toJson());


LoginUsecaseModelUser loginUsecaseModelUserFromJson(str) => LoginUsecaseModelUser.fromJson(str is String ? json.decode(str) : str);

String loginUsecaseModelUserToJson(LoginUsecaseModelUser data) => json.encode(data.toJson());


class LoginUsecaseModel {
  LoginUsecaseModelUser? user;
  String? token;

  LoginUsecaseModel({
    this.user,
    this.token,
  });

  factory LoginUsecaseModel.fromJson(Map<String, dynamic> json) {
    return LoginUsecaseModel(
      user: json['user'] is Map ? LoginUsecaseModelUser.fromJson(Map<String, dynamic>.from(json['user'] as Map)) : null,
      token: _asString(json['token']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user?.toJson(),
      'token': token,
    };
  }
}

class LoginUsecaseModelUser {
  String? moduleType;
  String? emailVerifiedAt;

  LoginUsecaseModelUser({
    this.moduleType,
    this.emailVerifiedAt,
  });

  factory LoginUsecaseModelUser.fromJson(Map<String, dynamic> json) {
    return LoginUsecaseModelUser(
      moduleType: _asString(json['moduleType']),
      emailVerifiedAt: _asString(json['emailVerifiedAt']),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'moduleType': moduleType,
      'emailVerifiedAt': emailVerifiedAt,
    };
  }
}
