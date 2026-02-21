import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'logger_interceptor.dart';
import 'token_interceptor.dart';

class DioNetwork {
  final List<Interceptor> interceptors;
  final String baseUrl;
  static late Dio dio;

  final String? token;
  final String? fcm;
  final String? lang;
  final Function()? onRequestFunction;

  DioNetwork({this.interceptors = const [], required this.baseUrl, this.onRequestFunction, this.fcm, this.token, this.lang}) {
    dio = Dio(BaseOptions(baseUrl: baseUrl, receiveDataWhenStatusError: true));
    dio.options.headers = {'Accept': 'application/json'};
    dio.interceptors.addAll([
      LoggerInterceptor(),
      TokenInterceptor(lang: lang, token: token, fcm: fcm, onRequestFunction: onRequestFunction),
      ...interceptors,
    ]);
  }

  Future<dynamic> _prepareRequestData(Map<String, dynamic> data) async {
    bool hasFile = data.values.any(
      (value) =>
          value is File ||
          value is Uint8List ||
          (value is List &&
              value.any((item) => item is File || item is Uint8List || (item is Map && item.values.any((v) => v is File || v is Uint8List)))) ||
          (value is Map && value.values.any((v) => v is File || v is Uint8List)),
    );

    if (hasFile) {
      FormData formData = FormData();

      for (var entry in data.entries) {
        final key = entry.key;
        final value = entry.value;

        if (value is File || value is Uint8List) {
          formData.files.add(await _handleFile(key, value));
        } else if (value is List) {
          bool isFileList = value.any(
            (item) => item is File || item is Uint8List || (item is Map && item.values.any((v) => v is File || v is Uint8List)),
          );

          if (isFileList) {
            for (var item in value) {
              if (item is File || item is Uint8List) {
                formData.files.add(await _handleFile(key, item));
              } else if (item is Map<String, dynamic>) {
                for (var mapEntry in item.entries) {
                  final fileKey = mapEntry.key;
                  final fileValue = mapEntry.value;
                  if (fileValue is File || fileValue is Uint8List) {
                    formData.files.add(await _handleFile(key, fileValue, customFileName: fileKey));
                  } else {
                    formData.fields.add(MapEntry(fileKey, fileValue.toString()));
                  }
                }
              } else {
                formData.fields.add(MapEntry(key, item.toString()));
              }
            }
          } else {
            for (var item in value) {
              formData.fields.add(MapEntry(key, item.toString()));
            }
          }
        } else if (value is Map<String, dynamic>) {
          for (var mapEntry in value.entries) {
            final fileKey = mapEntry.key;
            final fileValue = mapEntry.value;
            if (fileValue is File || fileValue is Uint8List) {
              formData.files.add(await _handleFile(key, fileValue, customFileName: fileKey));
            } else {
              formData.fields.add(MapEntry(fileKey, fileValue.toString()));
            }
          }
        } else {
          formData.fields.add(MapEntry(key, value.toString()));
        }
      }
      return formData;
    }
    return data;
  }

  Future<MapEntry<String, MultipartFile>> _handleFile(String key, dynamic file, {String? customFileName}) async {
    if (file is File) {
      return MapEntry(key, await MultipartFile.fromFile(file.path, filename: customFileName ?? file.path.split('/').last));
    } else if (file is Uint8List) {
      return MapEntry(key, MultipartFile.fromBytes(file, filename: customFileName ?? 'uploaded_file'));
    } else {
      throw UnsupportedError('Unsupported file type: ${file.runtimeType}');
    }
  }

  Future<Response> postData({
    required String endPoint,
    required Map<String, dynamic> data,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? params,
  }) async {
    dio.options.headers.addAll(headers ?? {});
    dynamic requestData = await _prepareRequestData(data);
    return await dio.post(endPoint, data: requestData, queryParameters: params);
  }

  Future<Response> putData({
    required String endPoint,
    required Map<String, dynamic> data,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? params,
  }) async {
    dio.options.headers.addAll(headers ?? {});
    dynamic requestData = await _prepareRequestData(data);
    return await dio.put(endPoint, data: requestData, queryParameters: params);
  }

  Future<Response> patchData({
    required String endPoint,
    required Map<String, dynamic> data,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? params,
  }) async {
    dio.options.headers.addAll(headers ?? {});
    dynamic requestData = await _prepareRequestData(data);
    return await dio.patch(endPoint, data: requestData, queryParameters: params);
  }

  Future<Response> deleteData({
    required String endPoint,
    Map<String, dynamic>? data,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? params,
  }) async {
    dio.options.headers.addAll(headers ?? {});
    return await dio.delete(endPoint, data: data, queryParameters: params);
  }

  Future<Response> getData({
    required String endPoint,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? params,
    Map<String, dynamic>? data,
  }) async {
    dio.options.headers.addAll(headers ?? {});
    return await dio.get(endPoint, queryParameters: params, data: data);
  }
}
