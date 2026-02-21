import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class TokenInterceptor extends Interceptor {
  final String? token;
  final String? fcm;
  final String? lang;
  final Function()? onRequestFunction;

  TokenInterceptor({required this.token, required this.fcm, required this.lang, required this.onRequestFunction});

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    try {
      if (onRequestFunction != null) {
        onRequestFunction!();
      }

      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
        log('========================> token: $token');
      }

      if (fcm != null) {
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
