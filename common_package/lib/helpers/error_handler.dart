import 'dart:core';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:equatable/equatable.dart';

import '../generated/locale_keys.g.dart';

mixin HandlingException {
  Future<Either<Failure, T>> wrapHandlingException<T>({
    required Future<T> Function() tryCall,
  }) async {
    try {
      final result = await tryCall();
      return Right(result);
    } catch (e) {
      return Left(ErrorHandler.handle(e).failure);
    }
  }
}

class ErrorHandler implements Exception {
  late Failure failure;

  ErrorHandler.handle(error) {
    if (error is DioException) {
      failure = _handleError(error);
    } else {
      failure = ServerFailure(
        message: error.toString(),
        statusCode: ResponseCode.badRequestServer,
      );
    }
  }

  Failure _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return DataSource.connectTimeOut.getFailure();
      case DioExceptionType.sendTimeout:
        return DataSource.sendTimeOut.getFailure();
      case DioExceptionType.receiveTimeout:
        return DataSource.receiveTimeOut.getFailure();
      case DioExceptionType.cancel:
        return DataSource.cancel.getFailure();
      case DioExceptionType.unknown:
        return DataSource.def.getFailure();
      case DioExceptionType.badCertificate:
        return DataSource.badRequest.getFailure();
      case DioExceptionType.connectionError:
        return DataSource.noInternetConnection.getFailure();
      case DioExceptionType.badResponse:
        switch (error.response?.statusCode) {
          case ResponseCode.internalServerError:
            return DataSource.internetServerError.getFailure();
          case ResponseCode.notFound:
            return DataSource.notFound.getFailure();
          case ResponseCode.forBidden:
            return DataSource.forBidden.getFailure();
          case ResponseCode.unAuthorized:
            return UnauthenticatedFailure(
              message: error.response?.data is Map<String, dynamic>
                  ? ErrorMessageModel.fromJson(
                      error.response!.data as Map<String, dynamic>,
                    ).statusMessage
                  : ResponseMessage.unAuthorized.tr(),
            );
          case ResponseCode.blocked:
            return UserBlockedFailure(message: AppConstants.blockedError.tr());
          case ResponseCode.notAllowed:
            return UserNotAllowedFailure(message: AppConstants.notAllowed.tr());
          case ResponseCode.badContent:
            return ServerFailure(
              message: ErrorMessageModel.fromJson(
                error.response?.data,
              ).statusMessage,
              statusCode: ResponseCode.badContent,
            );
          case ResponseCode.badRequestServer:
            return ServerFailure(
              message: ErrorMessageModel.fromJson(
                error.response?.data,
              ).statusMessage,
              statusCode: ResponseCode.badRequestServer,
            );
          default:
            return ServerFailure(
              message:
                  error.response?.data["message"].toString() ??
                  error.response?.data["errors"]?.toString() ??
                  '',
              statusCode: error.response?.statusCode ?? ResponseCode.badRequest,
            );
        }
      case DioExceptionType.transformTimeout:
        return DataSource.def.getFailure();
    }
  }
}

extension DataSourceExtension on DataSource {
  Failure getFailure() {
    switch (this) {
      case DataSource.success:
        return ServerFailure(
          statusCode: ResponseCode.success,
          message: ResponseMessage.success.tr(),
        );
      case DataSource.noInternet:
        return ServerFailure(
          statusCode: ResponseCode.noContent,
          message: ResponseMessage.noContent.tr(),
        );
      case DataSource.badRequest:
        return ServerFailure(
          statusCode: ResponseCode.badRequest,
          message: ResponseMessage.badRequest.tr(),
        );
      case DataSource.forBidden:
        return ServerFailure(
          statusCode: ResponseCode.forBidden,
          message: ResponseMessage.forbidden.tr(),
        );
      case DataSource.unAuthorized:
        return ServerFailure(
          statusCode: ResponseCode.unAuthorized,
          message: ResponseMessage.unAuthorized.tr(),
        );
      case DataSource.notFound:
        return ServerFailure(
          statusCode: ResponseCode.notFound,
          message: ResponseMessage.notFound.tr(),
        );
      case DataSource.internetServerError:
        return ServerFailure(
          statusCode: ResponseCode.internalServerError,
          message: ResponseMessage.internalServerError.tr(),
        );
      case DataSource.connectTimeOut:
        return ServerFailure(
          statusCode: ResponseCode.connectTimeOut,
          message: ResponseMessage.connectTimeout.tr(),
        );
      case DataSource.cancel:
        return ServerFailure(
          statusCode: ResponseCode.cancel,
          message: ResponseMessage.cancel.tr(),
        );
      case DataSource.receiveTimeOut:
        return ServerFailure(
          statusCode: ResponseCode.receiveTimeOut,
          message: ResponseMessage.receiveTime.tr(),
        );
      case DataSource.sendTimeOut:
        return ServerFailure(
          statusCode: ResponseCode.sendTimeOut,
          message: ResponseMessage.sendTimeout.tr(),
        );
      case DataSource.cashError:
        return ServerFailure(
          statusCode: ResponseCode.cashError,
          message: ResponseMessage.cacheError.tr(),
        );
      case DataSource.noInternetConnection:
        return ServerFailure(
          statusCode: ResponseCode.noInternetConnection,
          message: ResponseMessage.noInternetConnection.tr(),
        );
      case DataSource.def:
        return ServerFailure(
          statusCode: ResponseCode.def,
          message: ResponseMessage.def.tr(),
        );
    }
  }
}

class ResponseCode {
  static const int success = 200;
  static const int noContent = 201;
  static const int badRequest = 400;
  static const int unAuthorized = 401;
  static const int forBidden = 403;
  static const int internalServerError = 500;
  static const int notFound = 404;
  static const int notAllowed = 405;
  static const int blocked = 420;
  static const int badContent = 422;
  static const int badRequestServer = 402;
  static const int connectTimeOut = -1;
  static const int cancel = -2;
  static const int receiveTimeOut = -3;
  static const int sendTimeOut = -4;
  static const int cashError = -5;
  static const int noInternetConnection = -6;
  static const int def = -7;
}

class ResponseMessage {
  static const String success = AppConstants.success;
  static const String noContent = AppConstants.success;
  static const String badRequest = AppConstants.badRequestError;
  static const String unAuthorized = AppConstants.unauthorizedError;
  static const String forbidden = AppConstants.forbiddenError;
  static const String internalServerError = AppConstants.internalServerError;
  static const String notFound = AppConstants.notFoundError;
  static const String connectTimeout = AppConstants.timeoutError;
  static const String cancel = AppConstants.defaultError;
  static const String receiveTime = AppConstants.timeoutError;
  static const String sendTimeout = AppConstants.timeoutError;
  static const String cacheError = AppConstants.cacheError;
  static const String noInternetConnection = AppConstants.noInternetError;
  static const String def = AppConstants.defaultError;
}

class AppConstants {
  AppConstants._();

  static const String success = LocaleKeys.errorMessage_success;
  static const String badRequestError = LocaleKeys.errorMessage_badRequestError;
  static const String noContent = LocaleKeys.errorMessage_noContent;
  static const String forbiddenError = LocaleKeys.errorMessage_forbiddenError;
  static const String unauthorizedError =
      LocaleKeys.errorMessage_unauthorizedError;
  static const String notFoundError = LocaleKeys.errorMessage_notFoundError;
  static const String conflictError = LocaleKeys.errorMessage_conflictError;
  static const String blockedError = LocaleKeys.errorMessage_blockedError;
  static const String internalServerError =
      LocaleKeys.errorMessage_internalServerError;
  static const String notAllowed = LocaleKeys.errorMessage_notAllowed;

  static const String unknownError = LocaleKeys.errorMessage_unknownError;
  static const String timeoutError = LocaleKeys.errorMessage_timeoutError;
  static const String defaultError = LocaleKeys.errorMessage_defaultError;
  static const String cacheError = LocaleKeys.errorMessage_cacheError;
  static const String noInternetError = LocaleKeys.errorMessage_noInternetError;
}

class ApiInternalStatus {
  static const int success = 0;
  static const int failure = 1;
}

enum DataSource {
  success,
  noInternet,
  badRequest,
  forBidden,
  unAuthorized,
  notFound,
  internetServerError,
  connectTimeOut,
  cancel,
  receiveTimeOut,
  sendTimeOut,
  cashError,
  noInternetConnection,
  def,
}

abstract class Failure extends Equatable {
  final String message;
  final int? statusCode;

  const Failure({required this.message, this.statusCode = -1});

  @override
  List<Object?> get props => [message, statusCode];
}

class ServerFailure extends Failure {
  const ServerFailure({required super.message, super.statusCode});
}

class UnauthenticatedFailure extends Failure {
  const UnauthenticatedFailure({required super.message});
}

class UserNotAllowedFailure extends Failure {
  const UserNotAllowedFailure({required super.message});
}

class UserBlockedFailure extends Failure {
  const UserBlockedFailure({required super.message});
}

class DatabaseFailure extends Failure {
  const DatabaseFailure({required super.message});
}

class ErrorMessageModel extends Equatable {
  final String statusMessage;
  final bool success;

  const ErrorMessageModel({required this.statusMessage, required this.success});

  factory ErrorMessageModel.fromJson(Map<String, dynamic> json) {
    final apiCode = json['code']?.toString();
    if (apiCode == 'WORKER_NOT_ELIGIBLE_FOR_NEW_REQUESTS') {
      return ErrorMessageModel(
        statusMessage: _workerEligibilityMessage(json),
        success: false,
      );
    }

    String error = "";
    if (json["message"] is Map) {
      for (var item in (json["message"] as Map<String, dynamic>).entries) {
        error = "${error.isEmpty ? "" : "$error \n"} ${item.value}";
      }
    } else {
      error = json["message"].toString();
    }
    return ErrorMessageModel(
      statusMessage: error,
      success: json["success"] ?? false,
    );
  }

  static String _workerEligibilityMessage(Map<String, dynamic> json) {
    final reason = _workerEligibilityReason(json);
    switch (reason) {
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
      default:
        return 'لا يمكن لحسابك قبول طلبات جديدة حالياً.';
    }
  }

  static String? _workerEligibilityReason(Map<String, dynamic> json) {
    final directEligibility = json['dispatchEligibility'];
    if (directEligibility is Map) {
      final reason =
          directEligibility['reasonCode'] ?? directEligibility['reason_code'];
      if (reason != null) return reason.toString().trim().toLowerCase();
    }

    final errors = json['errors'];
    if (errors is Map) {
      final workerEligibility =
          errors['workerEligibility'] ?? errors['worker_eligibility'];
      if (workerEligibility is List && workerEligibility.isNotEmpty) {
        final first = workerEligibility.first;
        if (first is Map) {
          final reason = first['reasonCode'] ?? first['reason_code'];
          if (reason != null) return reason.toString().trim().toLowerCase();
        }
      }
    }

    return null;
  }

  @override
  List<Object?> get props => [statusMessage, success];
}
