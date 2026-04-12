import 'package:dio/dio.dart';

class UnauthorizedInterceptor extends Interceptor {
  UnauthorizedInterceptor({
    this.onUnauthorized,
    this.excludedPathSuffixes = const [],
  });

  final Future<void> Function()? onUnauthorized;
  final List<String> excludedPathSuffixes;

  static bool _handlingUnauthorized = false;

  bool _isExcluded(RequestOptions ro) {
    final path = ro.path;
    final combined = '${ro.baseUrl}${ro.path}';
    for (final suffix in excludedPathSuffixes) {
      if (suffix.isEmpty) continue;
      if (path.endsWith(suffix) || combined.endsWith(suffix)) {
        return true;
      }
    }
    return false;
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final status = err.response?.statusCode;
    final ro = err.requestOptions;

    if (status == 401 && !_isExcluded(ro) && onUnauthorized != null) {
      if (!_handlingUnauthorized) {
        _handlingUnauthorized = true;
        onUnauthorized!().whenComplete(() => _handlingUnauthorized = false);
      }
    }
    return super.onError(err, handler);
  }
}
