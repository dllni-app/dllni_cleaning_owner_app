import 'dart:developer';

import 'package:common_package/helpers/shared_preferences_helper.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class TokenInterceptor extends Interceptor {
  final String? tokenKey;
  final String? fcmKey;
  final String? lang;
  final Function()? onRequestFunction;

  TokenInterceptor({required this.tokenKey, required this.fcmKey, required this.lang, required this.onRequestFunction});

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    try {
      if (onRequestFunction != null) {
        onRequestFunction!();
      }

      if (tokenKey != null) {
        final token = SharedPreferencesHelper.getData(key: tokenKey!) ?? '';
        options.headers['Authorization'] = 'Bearer $token';
        log('========================> token: $token');
      }

      if (fcmKey != null) {
        final fcm = SharedPreferencesHelper.getData(key: fcmKey!) ?? '';
        options.headers['fcm-token'] = fcm;
        log('========================> fcm: $fcm');
      }

      if (lang != null) {
        options.headers['App-Language'] = lang;
        log('========================> lang: $lang');
      }
    } catch (e) {
      debugPrint('TokenInterceptor Error: $e');
    }

    super.onRequest(options, handler);
  }
}
