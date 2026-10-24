import 'dart:typed_data';

import 'package:common_package/common_package.dart';
import 'package:dio/dio.dart';
import 'package:dllni_cleaninig_owner_app/core/di/injection.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/repository/orders_repo_impl.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/source/orders_remote_data_source.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/domain/usecases/fetch_order_details_usecase_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/manager/bloc/orders_bloc.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/screens/order_details_screen.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/view/screens/transaction_details_screen.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/view/widgets/notification_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toastification/toastification.dart';

void main() {
  setUp(() async => getIt.reset());
  tearDown(() async {
    AppToast.setSuppressErrorToasts(false);
    await getIt.reset();
    DioNetwork.dio.close(force: true);
  });

  for (final invalidId in <dynamic>[
    12.5,
    double.infinity,
    1e100,
    9223372036854775808.0,
    0,
    -4,
    'not-an-id',
    null,
  ]) {
    testWidgets('rejects explicit invalid booking id $invalidId before HTTP', (
      tester,
    ) async {
      final http = await _registerNavigationDependencies(returnedBookingId: 12);
      final observer = _RecordingNavigatorObserver();

      await _openNotification(tester, observer, <String, dynamic>{
        'bookingId': invalidId,
      });

      expect(http.requests, isEmpty);
      expect(observer.pushedRoutes, isEmpty);
    });
  }

  testWidgets('rejects conflicting explicit booking aliases before HTTP', (
    tester,
  ) async {
    final http = await _registerNavigationDependencies(returnedBookingId: 12);
    final observer = _RecordingNavigatorObserver();

    await _openNotification(tester, observer, const <String, dynamic>{
      'bookingId': 12,
      'order_id': 13,
    });

    expect(http.requests, isEmpty);
    expect(observer.pushedRoutes, isEmpty);
  });

  for (final alias in <String>[
    'sessionId',
    'session_id',
    'cleaningBookingSessionId',
    'cleaning_booking_session_id',
  ]) {
    testWidgets('preserves selected session from $alias', (tester) async {
      final http = await _registerNavigationDependencies(returnedBookingId: 12);
      final observer = _RecordingNavigatorObserver();

      await _openNotification(tester, observer, <String, dynamic>{
        'booking_id': 12,
        alias: 34,
      });

      expect(http.requests, <String>['GET /api/v1/cleaning-bookings/12']);
      final settings = observer.pushedRoutes.single;
      expect(settings.name, '/orderdetails');
      final params = settings.arguments! as OrderDetailsScreenParams;
      expect(params.order.id, 12);
      expect(params.selectedSessionId, 34);
    });
  }

  testWidgets('allows an absent optional session id', (tester) async {
    final http = await _registerNavigationDependencies(returnedBookingId: 12);
    final observer = _RecordingNavigatorObserver();

    await _openNotification(tester, observer, const <String, dynamic>{
      'bookingId': '12',
    });

    final params =
        observer.pushedRoutes.single.arguments! as OrderDetailsScreenParams;
    expect(http.requests, <String>['GET /api/v1/cleaning-bookings/12']);
    expect(params.selectedSessionId, isNull);
  });

  testWidgets('retains exactly represented integral doubles', (tester) async {
    final http = await _registerNavigationDependencies(returnedBookingId: 12);
    final observer = _RecordingNavigatorObserver();

    await _openNotification(tester, observer, const <String, dynamic>{
      'bookingId': 12.0,
      'sessionId': 34.0,
    });

    expect(http.requests, <String>['GET /api/v1/cleaning-bookings/12']);
    final params =
        observer.pushedRoutes.single.arguments! as OrderDetailsScreenParams;
    expect(params.order.id, 12);
    expect(params.selectedSessionId, 34);
  });

  testWidgets('preserves the new-order route flag after identity validation', (
    tester,
  ) async {
    final http = await _registerNavigationDependencies(returnedBookingId: 12);
    final observer = _RecordingNavigatorObserver();

    await _openNotification(tester, observer, const <String, dynamic>{
      'bookingId': 12,
    }, canonicalType: 'cleaning.booking.new_order_request');

    final params =
        observer.pushedRoutes.single.arguments! as OrderDetailsScreenParams;
    expect(http.requests, <String>['GET /api/v1/cleaning-bookings/12']);
    expect(params.isNewOrder, isTrue);
  });

  testWidgets('rejects an invalid explicit session without HTTP fallback', (
    tester,
  ) async {
    final http = await _registerNavigationDependencies(returnedBookingId: 12);
    final observer = _RecordingNavigatorObserver();

    await _openNotification(tester, observer, const <String, dynamic>{
      'bookingId': 12,
      'cleaningBookingSessionId': 0,
    });

    expect(http.requests, isEmpty);
    expect(observer.pushedRoutes, isEmpty);
  });

  for (final invalidSessionId in <dynamic>[
    12.5,
    double.infinity,
    double.nan,
    1e100,
    9223372036854775808.0,
    0,
    -4,
    'not-an-id',
    null,
  ]) {
    testWidgets('rejects explicit invalid session $invalidSessionId', (
      tester,
    ) async {
      final http = await _registerNavigationDependencies(returnedBookingId: 12);
      final observer = _RecordingNavigatorObserver();

      await _openNotification(tester, observer, <String, dynamic>{
        'bookingId': 12,
        'session_id': invalidSessionId,
      });

      expect(http.requests, isEmpty);
      expect(observer.pushedRoutes, isEmpty);
    });
  }

  testWidgets('rejects conflicting session aliases without HTTP fallback', (
    tester,
  ) async {
    final http = await _registerNavigationDependencies(returnedBookingId: 12);
    final observer = _RecordingNavigatorObserver();

    await _openNotification(tester, observer, const <String, dynamic>{
      'bookingId': 12,
      'sessionId': 34,
      'cleaning_booking_session_id': 35,
    });

    expect(http.requests, isEmpty);
    expect(observer.pushedRoutes, isEmpty);
  });

  testWidgets('keeps unavailable new-order notifications out of details', (
    tester,
  ) async {
    AppToast.setSuppressErrorToasts(true);
    final http = await _registerNavigationDependencies(returnedBookingId: 12);
    final observer = _RecordingNavigatorObserver();

    await _openNotification(
      tester,
      observer,
      const <String, dynamic>{'bookingId': 12, 'state': 'unavailable'},
      type: 'new_order',
      canonicalType: 'cleaning.booking.new_order_request',
    );

    expect(http.requests, isEmpty);
    expect(observer.pushedRoutes, isEmpty);
  });

  testWidgets('does not navigate when HTTP returns a different booking id', (
    tester,
  ) async {
    final http = await _registerNavigationDependencies(returnedBookingId: 99);
    final observer = _RecordingNavigatorObserver();

    await _openNotification(tester, observer, const <String, dynamic>{
      'bookingId': 12,
    });

    expect(http.requests, <String>['GET /api/v1/cleaning-bookings/12']);
    expect(observer.pushedRoutes, isEmpty);
  });

  testWidgets('does not route a dispute notification from another module', (
    tester,
  ) async {
    final http = await _registerNavigationDependencies(returnedBookingId: 12);
    final observer = _RecordingNavigatorObserver();

    await _openNotification(
      tester,
      observer,
      const <String, dynamic>{'disputeId': 34},
      module: 'delivery',
      canonicalType: 'cleaning.dispute.updated',
    );

    expect(http.requests, isEmpty);
    expect(observer.pushedRoutes, isEmpty);
  });

  testWidgets('rejects malformed dispute aliases', (tester) async {
    final http = await _registerNavigationDependencies(returnedBookingId: 12);
    final observer = _RecordingNavigatorObserver();

    await _openNotification(tester, observer, const <String, dynamic>{
      'disputeId': 34,
      'dispute_id': null,
    }, canonicalType: 'cleaning.dispute.updated');

    expect(http.requests, isEmpty);
    expect(observer.pushedRoutes, isEmpty);
  });

  for (final invalidDisputeId in <dynamic>[
    34.5,
    double.infinity,
    1e100,
    9223372036854775808.0,
    0,
    -3,
    'invalid',
    null,
  ]) {
    testWidgets('rejects explicit invalid dispute id $invalidDisputeId', (
      tester,
    ) async {
      final http = await _registerNavigationDependencies(returnedBookingId: 12);
      final observer = _RecordingNavigatorObserver();

      await _openNotification(tester, observer, <String, dynamic>{
        'dispute_id': invalidDisputeId,
      }, canonicalType: 'cleaning.dispute.updated');

      expect(http.requests, isEmpty);
      expect(observer.pushedRoutes, isEmpty);
    });
  }

  testWidgets('accepts an exactly represented dispute id double', (
    tester,
  ) async {
    final http = await _registerNavigationDependencies(returnedBookingId: 12);
    final observer = _RecordingNavigatorObserver();

    await _openNotification(tester, observer, const <String, dynamic>{
      'disputeId': 34.0,
    }, canonicalType: 'cleaning.dispute.updated');

    expect(http.requests, isEmpty);
    final params =
        observer.pushedRoutes.single.arguments!
            as TransactionDetailsScreenParam;
    expect(params.id, 34);
  });

  testWidgets('opens a cleaning dispute using its positive integer id', (
    tester,
  ) async {
    final http = await _registerNavigationDependencies(returnedBookingId: 12);
    final observer = _RecordingNavigatorObserver();

    await _openNotification(tester, observer, const <String, dynamic>{
      'dispute_id': '34',
    }, canonicalType: 'cleaning.dispute.updated');

    expect(http.requests, isEmpty);
    final settings = observer.pushedRoutes.single;
    expect(settings.name, '/transactiondetails');
    final params = settings.arguments! as TransactionDetailsScreenParam;
    expect(params.id, 34);
  });
}

Future<_NavigationHttpFixture> _registerNavigationDependencies({
  required int returnedBookingId,
}) async {
  final http = _NavigationHttpFixture(returnedBookingId);
  final remoteSource = OrdersRemoteDataSource(dioNetwork: http.network);
  final repo = OrdersRepoImpl(ordersRemoteDataSource: remoteSource);
  getIt.registerSingleton<FetchOrderDetailsUsecaseUseCase>(
    FetchOrderDetailsUsecaseUseCase(orders: repo),
  );
  getIt.registerSingleton<OrdersBloc>(_OrdersBlocFake());
  return http;
}

Future<void> _openNotification(
  WidgetTester tester,
  _RecordingNavigatorObserver observer,
  Map<String, dynamic> payload, {
  String module = 'cleaning',
  String? canonicalType = 'cleaning.booking.updated',
  String? type,
}) async {
  final navigatorKey = GlobalKey<NavigatorState>();
  AppToast.bindNavigatorKey(navigatorKey);
  await tester.pumpWidget(
    ToastificationWrapper(
      child: MaterialApp(
        navigatorKey: navigatorKey,
        navigatorObservers: <NavigatorObserver>[observer],
        onGenerateRoute: (settings) => MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const Scaffold(body: Text('destination')),
        ),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              key: const Key('open_notification'),
              onPressed: () => tryNavigateFromNotificationPayload(
                context,
                module: module,
                canonicalType: canonicalType,
                type: type,
                data: payload,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.byKey(const Key('open_notification')));
  await tester.pumpAndSettle();
}

class _RecordingNavigatorObserver extends NavigatorObserver {
  final List<RouteSettings> pushedRoutes = <RouteSettings>[];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route.settings.name != '/') pushedRoutes.add(route.settings);
  }
}

class _OrdersBlocFake extends Fake implements OrdersBloc {}

class _NavigationHttpFixture {
  _NavigationHttpFixture(int returnedBookingId)
    : adapter = _BookingDetailsHttpAdapter(returnedBookingId),
      network = DioNetwork(baseUrl: 'https://worker.example.test') {
    DioNetwork.dio.httpClientAdapter = adapter;
  }

  final _BookingDetailsHttpAdapter adapter;
  final DioNetwork network;

  List<String> get requests => adapter.requests;
}

class _BookingDetailsHttpAdapter implements HttpClientAdapter {
  _BookingDetailsHttpAdapter(this.returnedBookingId);

  final int returnedBookingId;
  final List<String> requests = <String>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add('${options.method} ${options.path}');
    return ResponseBody.fromString(
      '{"data":{"id":$returnedBookingId}}',
      200,
      headers: const <String, List<String>>{
        Headers.contentTypeHeader: <String>['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
