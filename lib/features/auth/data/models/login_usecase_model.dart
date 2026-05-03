import 'dart:convert';

String? _asString(dynamic value) {
  if (value == null) return null;
  if (value is String) return value;
  if (value is num || value is bool) return value.toString();
  return null;
}

LoginUsecaseModel loginUsecaseModelFromJson(str) =>
    LoginUsecaseModel.fromJson(str is String ? json.decode(str) : str);

String loginUsecaseModelToJson(LoginUsecaseModel data) =>
    json.encode(data.toJson());

LoginUsecaseModelUser loginUsecaseModelUserFromJson(str) =>
    LoginUsecaseModelUser.fromJson(str is String ? json.decode(str) : str);

String loginUsecaseModelUserToJson(LoginUsecaseModelUser data) =>
    json.encode(data.toJson());

class LoginUsecaseModel {
  LoginUsecaseModelUser? user;
  String? token;

  LoginUsecaseModel({this.user, this.token});

  factory LoginUsecaseModel.fromJson(Map<String, dynamic> json) {
    return LoginUsecaseModel(
      user: json['user'] is Map
          ? LoginUsecaseModelUser.fromJson(
              Map<String, dynamic>.from(json['user'] as Map),
            )
          : null,
      token: _asString(json['token']),
    );
  }

  Map<String, dynamic> toJson() {
    return {'user': user?.toJson(), 'token': token};
  }
}

class LoginUsecaseModelUser {
  int? id;
  int? workerId;
  String? moduleType;
  String? emailVerifiedAt;

  LoginUsecaseModelUser({
    this.id,
    this.workerId,
    this.moduleType,
    this.emailVerifiedAt,
  });

  factory LoginUsecaseModelUser.fromJson(Map<String, dynamic> json) {
    return LoginUsecaseModelUser(
      id: (json['id'] as num?)?.toInt(),
      workerId:
          (json['workerId'] as num?)?.toInt() ??
          (json['worker_id'] as num?)?.toInt(),
      moduleType: _asString(json['moduleType']),
      emailVerifiedAt: _asString(json['emailVerifiedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'workerId': workerId,
      'moduleType': moduleType,
      'emailVerifiedAt': emailVerifiedAt,
    };
  }
}
