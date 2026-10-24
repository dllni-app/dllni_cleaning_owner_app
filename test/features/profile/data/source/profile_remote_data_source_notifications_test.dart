import 'dart:typed_data';

import 'package:common_package/helpers/typedef.dart';
import 'package:common_package/helpers/dio_network.dart';
import 'package:dio/dio.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/data/source/profile_remote_data_source.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/domain/usecases/delete_notification_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/domain/usecases/fetch_notifications_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/domain/usecases/mark_notification_read_use_case.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('notification feed and mutations use the worker account API', () async {
    final adapter = _RecordingHttpAdapter();
    final network = DioNetwork(baseUrl: 'https://worker.example.test');
    DioNetwork.dio.httpClientAdapter = adapter;
    final source = ProfileRemoteDataSource(dioNetwork: network);

    await source.fetchNotifications(FetchNotificationsParams());
    await source.markAllNotificationsRead(NoParams());
    await source.markNotificationRead(
      MarkNotificationReadParams(notificationId: 'notice-7'),
    );
    await source.deleteNotification(
      DeleteNotificationParams(notificationId: 'notice-7'),
    );
    await source.deleteAllNotifications(NoParams());

    expect(adapter.requests, [
      'GET /api/v1/cleaning/worker/account/notifications',
      'PATCH /api/v1/cleaning/worker/account/notifications/read-all',
      'PATCH /api/v1/cleaning/worker/account/notifications/notice-7/read',
      'DELETE /api/v1/cleaning/worker/account/notifications/notice-7',
      'DELETE /api/v1/cleaning/worker/account/notifications/all',
    ]);
    DioNetwork.dio.close(force: true);
  });
}

class _RecordingHttpAdapter implements HttpClientAdapter {
  final requests = <String>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add('${options.method} ${options.path}');
    final isFeed = options.method == 'GET';
    return ResponseBody.fromString(
      isFeed
          ? '{"data":[],"meta":{"current_page":1,"per_page":10,"total":0}}'
          : '{"success":true}',
      200,
      headers: const <String, List<String>>{
        Headers.contentTypeHeader: <String>['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
