import 'dart:async';

import 'package:common_package/common_package.dart';
import 'package:dartz/dartz.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/models/accept_extension_usecase_model.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/models/fetch_extension_requests_usecas_model.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/models/fetch_order_details_usecase_model.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/models/fetch_orders_usecase_model.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/models/reject_extension_usecase_model.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/domain/repository/orders_repo.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/domain/usecases/accept_extension_usecase_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/domain/usecases/accept_order_usecase_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/domain/usecases/arrive_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/domain/usecases/cancel_order_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/domain/usecases/complete_order_usecase_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/domain/usecases/fetch_extension_requests_usecas_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/domain/usecases/fetch_order_details_usecase_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/domain/usecases/fetch_orders_usecase_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/domain/usecases/fetch_security_code_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/domain/usecases/post_booking_location_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/domain/usecases/reject_extension_usecase_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/domain/usecases/reject_order_usecase_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/domain/usecases/start_travel_usecase_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/domain/usecases/start_work_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/domain/usecases/update_availability_usecase_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/manager/bloc/orders_bloc.dart';
import 'package:dllni_cleaninig_owner_app/core/widgets/order_card.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/widgets/extension_request_action_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../../support/finish_widget_cleanup.dart';

void main() {
  testWidgets('root navigator accept waits for its own success and closes', (
    WidgetTester tester,
  ) async {
    final bloc = _buildOrdersBloc(
      repo: _OrdersRepoFake(
        acceptResults: <Either<Failure, AcceptExtensionUsecaseModel>>[
          Right<Failure, AcceptExtensionUsecaseModel>(
            AcceptExtensionUsecaseModel(
              data: AcceptExtensionUsecaseModelData(id: 12),
            ),
          ),
        ],
      ),
    );
    final result = await _openSheet(tester, bloc, warningId: 12);

    await tester.tap(find.text('قبول الطلب'));
    await tester.pumpAndSettle();

    expect(
      result.isCompleted,
      isTrue,
      reason: 'confirmed decision closes the modal',
    );
    expect(await result.future, isTrue);
    expect(find.text('طلب تمديد مدة العمل'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await _closeOrdersBloc(tester, bloc);
  });

  testWidgets('submitted acceptance closes with mismatched response id', (
    WidgetTester tester,
  ) async {
    final bloc = _buildOrdersBloc(
      repo: _OrdersRepoFake(
        acceptResults: <Either<Failure, AcceptExtensionUsecaseModel>>[
          Right<Failure, AcceptExtensionUsecaseModel>(
            AcceptExtensionUsecaseModel(
              data: AcceptExtensionUsecaseModelData(id: 99),
            ),
          ),
        ],
      ),
    );
    final result = await _openSheet(tester, bloc, warningId: 13);

    await tester.tap(find.text('قبول الطلب'));
    await tester.pumpAndSettle();

    expect(await result.future, isTrue);
    expect(find.text('طلب تمديد مدة العمل'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await finishWidgetCleanup(tester, bloc.close());
  });

  testWidgets('submitted rejection closes even when response id is absent', (
    WidgetTester tester,
  ) async {
    final bloc = _buildOrdersBloc(
      repo: _OrdersRepoFake(
        rejectResults: <Either<Failure, RejectExtensionUsecaseModel>>[
          Right<Failure, RejectExtensionUsecaseModel>(
            RejectExtensionUsecaseModel(),
          ),
        ],
      ),
    );
    final result = await _openSheet(tester, bloc, warningId: 10);
    await tester.tap(find.text('رفض الطلب'));
    await tester.pumpAndSettle();
    expect(await result.future, isTrue);
    expect(find.text('طلب تمديد مدة العمل'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await finishWidgetCleanup(tester, bloc.close());
  });

  testWidgets('unrelated decision success before tapping does not close', (
    WidgetTester tester,
  ) async {
    final bloc = _buildOrdersBloc(
      repo: _OrdersRepoFake(
        rejectResults: <Either<Failure, RejectExtensionUsecaseModel>>[
          Right<Failure, RejectExtensionUsecaseModel>(
            RejectExtensionUsecaseModel(
              data: RejectExtensionUsecaseModelData(id: 99),
            ),
          ),
        ],
      ),
    );
    final result = await _openSheet(tester, bloc, warningId: 10);
    bloc.add(
      RejectExtensionUsecaseEvent(params: RejectExtensionUsecaseParams(id: 99)),
    );
    await tester.pumpAndSettle();
    expect(result.isCompleted, isFalse);
    expect(find.text('طلب تمديد مدة العمل'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await finishWidgetCleanup(tester, bloc.close());
  });

  testWidgets('root navigator reject stays open after failure and can retry', (
    WidgetTester tester,
  ) async {
    final bloc = _buildOrdersBloc(
      repo: _OrdersRepoFake(
        rejectResults: <Either<Failure, RejectExtensionUsecaseModel>>[
          const Left<Failure, RejectExtensionUsecaseModel>(
            ServerFailure(message: 'temporary failure', statusCode: 500),
          ),
          Right<Failure, RejectExtensionUsecaseModel>(
            RejectExtensionUsecaseModel(
              data: RejectExtensionUsecaseModelData(id: 22),
            ),
          ),
        ],
      ),
    );
    final result = await _openSheet(tester, bloc, warningId: 22);

    await tester.tap(find.text('رفض الطلب'));
    await tester.pumpAndSettle();
    expect(find.text('طلب تمديد مدة العمل'), findsOneWidget);

    await tester.tap(find.text('رفض الطلب'));
    await tester.pumpAndSettle();

    expect(await result.future, isTrue);
    expect(find.text('طلب تمديد مدة العمل'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await finishWidgetCleanup(tester, bloc.close());
  });

  testWidgets('root navigator sheet blocks system back until a decision', (
    WidgetTester tester,
  ) async {
    final bloc = _buildOrdersBloc(repo: _OrdersRepoFake());
    final result = await _openSheet(tester, bloc, warningId: 32);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('طلب تمديد مدة العمل'), findsOneWidget);
    await tester.tap(find.text('رفض الطلب'));
    await tester.pumpAndSettle();
    await result.future;
    await tester.pumpWidget(const SizedBox.shrink());
    await finishWidgetCleanup(tester, bloc.close());
  });

  testWidgets(
    'missing quote permits backend decision with 2x text and reachable actions',
    (WidgetTester tester) async {
      final bloc = _buildOrdersBloc(repo: _OrdersRepoFake());
      final result = await _openSheet(
        tester,
        bloc,
        warningId: 41,
        includeQuote: false,
        textScale: 2,
      );

      final acceptButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'قبول الطلب'),
      );
      expect(acceptButton.onPressed, isNotNull);
      await tester.ensureVisible(find.text('رفض الطلب'));
      expect(
        tester.getSize(find.widgetWithText(OutlinedButton, 'رفض الطلب')).height,
        greaterThanOrEqualTo(48),
      );
      await tester.tap(find.text('رفض الطلب'));
      await tester.pumpAndSettle();
      expect(await result.future, isTrue);

      await tester.pumpWidget(const SizedBox.shrink());
      await finishWidgetCleanup(tester, bloc.close());

      final invalidCases =
          <({double base, double margin, double total, double quote})>[
            (base: 100, margin: 0, total: double.nan, quote: 100),
            (base: 100, margin: 0, total: 100, quote: double.infinity),
            (base: 100, margin: 0, total: -1, quote: 100),
          ];
      for (var index = 0; index < invalidCases.length; index++) {
        final terms = invalidCases[index];
        final invalidBloc = _buildOrdersBloc(repo: _OrdersRepoFake());
        await _openSheet(
          tester,
          invalidBloc,
          warningId: 42 + index,
          baseAmount: terms.base,
          adminMargin: terms.margin,
          totalAmount: terms.total,
          additionalAmount: terms.quote,
          textScale: 2,
        );
        final invalidAccept = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'قبول الطلب'),
        );
        expect(
          invalidAccept.onPressed,
          isNotNull,
          reason: 'server validates terms $terms',
        );
        await tester.pumpWidget(const SizedBox.shrink());
        await finishWidgetCleanup(tester, invalidBloc.close());
      }
    },
  );

  testWidgets(
    'compact card prioritizes the worker status over global booking status',
    (WidgetTester tester) async {
      final bloc = _buildOrdersBloc(repo: _OrdersRepoFake());
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OrderCard(
              data: FetchOrdersUsecaseModelDataItem(
                id: 51,
                status: 'worker_assigned',
                statusLabel: 'تم تعيين العامل',
                workerOrderStatus: 'rejected',
                workerOrderStatusLabel: 'تم رفض تعييني',
                totalPrice: 100,
              ),
              bloc: bloc,
              index: 0,
            ),
          ),
        ),
      );

      expect(find.text('تم رفض الطلب'), findsOneWidget);
      expect(find.textContaining('تم تعيين العامل'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      await finishWidgetCleanup(tester, bloc.close());
    },
  );

  testWidgets(
    'compact card localizes worker state without duplicate global caption',
    (WidgetTester tester) async {
      final bloc = _buildOrdersBloc(repo: _OrdersRepoFake());
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OrderCard(
              data: FetchOrdersUsecaseModelDataItem(
                id: 52,
                status: 'in_progress',
                workerOrderStatus: 'rejected',
                totalPrice: 100,
              ),
              bloc: bloc,
              index: 0,
            ),
          ),
        ),
      );

      expect(find.text('تم رفض الطلب'), findsOneWidget);
      expect(find.textContaining('حالة الطلب:'), findsNothing);
      expect(find.textContaining('قيد التنفيذ'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      await finishWidgetCleanup(tester, bloc.close());
    },
  );

  testWidgets('long order status labels fit at 2x text on narrow cards', (
    WidgetTester tester,
  ) async {
    for (final width in <double>[320, 360, 430]) {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      final bloc = _buildOrdersBloc(repo: _OrdersRepoFake());
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: Scaffold(
            body: SingleChildScrollView(
              child: OrderCard(
                data: FetchOrdersUsecaseModelDataItem(
                  id: 53,
                  status: 'worker_assigned',
                  statusLabel:
                      'تم تعيين العامل والطلب بانتظار اكتمال تفاصيل الحجز',
                  workerOrderStatus: 'rejected',
                  workerOrderStatusLabel:
                      'تم رفض هذا التعيين بعد مراجعة تفاصيل المهمة كاملة',
                  totalPrice: 100,
                ),
                bloc: bloc,
                index: 0,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'width $width');
      await tester.pumpWidget(const SizedBox.shrink());
      await finishWidgetCleanup(tester, bloc.close());
    }
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('raw enum labels are localized from their own status fields', (
    WidgetTester tester,
  ) async {
    final bloc = _buildOrdersBloc(repo: _OrdersRepoFake());
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OrderCard(
            data: FetchOrdersUsecaseModelDataItem(
              id: 54,
              status: 'completed',
              statusLabel: 'pending',
              workerOrderStatus: 'rejected',
              workerOrderStatusLabel: 'pending',
              totalPrice: 100,
            ),
            bloc: bloc,
            index: 0,
          ),
        ),
      ),
    );

    expect(find.text('تم رفض الطلب'), findsOneWidget);
    expect(find.textContaining('حالة الطلب:'), findsNothing);
    expect(find.textContaining('pending'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await finishWidgetCleanup(tester, bloc.close());
  });
}

Future<void> _closeOrdersBloc(WidgetTester tester, OrdersBloc bloc) async {
  await finishWidgetCleanup(tester, bloc.close());
}

Future<Completer<bool>> _openSheet(
  WidgetTester tester,
  OrdersBloc bloc, {
  required int warningId,
  bool includeQuote = true,
  double textScale = 1,
  double baseAmount = 100,
  double adminMargin = 0,
  double? totalAmount,
  double? additionalAmount,
}) async {
  final result = Completer<bool>();
  final navigatorKey = GlobalKey<NavigatorState>();
  await tester.pumpWidget(
    MaterialApp(
      navigatorKey: navigatorKey,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () {
              ExtensionRequestActionSheet.show(
                context,
                useRootNavigator: true,
                bloc: bloc,
                warningId: warningId,
                requestedMinutes: 30,
                baseAmount: baseAmount,
                adminMargin: adminMargin,
                totalAmount: includeQuote ? (totalAmount ?? 100) : null,
                additionalAmount: includeQuote
                    ? (additionalAmount ?? 100)
                    : null,
                currency: 'SYP',
              ).then(result.complete);
            },
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return result;
}

OrdersBloc _buildOrdersBloc({required _OrdersRepoFake repo}) => OrdersBloc(
  FetchOrdersUsecaseUseCase(orders: repo),
  FetchOrderDetailsUsecaseUseCase(orders: repo),
  AcceptOrderUsecaseUseCase(orders: repo),
  StartTravelUsecaseUseCase(orders: repo),
  CompleteOrderUsecaseUseCase(orders: repo),
  CancelOrderUseCase(orders: repo),
  FetchExtensionRequestsUsecasUseCase(orders: repo),
  AcceptExtensionUsecaseUseCase(orders: repo),
  RejectExtensionUsecaseUseCase(orders: repo),
  UpdateAvailabilityUsecaseUseCase(orders: repo),
  RejectOrderUsecaseUseCase(orders: repo),
  ArriveUseCase(orders: repo),
  PostBookingLocationUseCase(orders: repo),
  FetchSecurityCodeUseCase(orders: repo),
  StartWorkUseCase(orders: repo),
);

class _OrdersRepoFake implements OrdersRepo {
  _OrdersRepoFake({
    this.acceptResults = const [],
    this.rejectResults = const [],
  });

  final List<Either<Failure, AcceptExtensionUsecaseModel>> acceptResults;
  final List<Either<Failure, RejectExtensionUsecaseModel>> rejectResults;
  var _acceptIndex = 0;
  var _rejectIndex = 0;

  @override
  DataResponse<AcceptExtensionUsecaseModel> acceptExtensionUsecase(
    AcceptExtensionUsecaseParams params,
  ) async => _next(acceptResults, _acceptIndex++);

  @override
  DataResponse<RejectExtensionUsecaseModel> rejectExtensionUsecase(
    RejectExtensionUsecaseParams params,
  ) async => rejectResults.isEmpty
      ? Right<Failure, RejectExtensionUsecaseModel>(
          RejectExtensionUsecaseModel(
            data: RejectExtensionUsecaseModelData(id: params.id),
          ),
        )
      : _next(rejectResults, _rejectIndex++);

  @override
  DataResponse<FetchExtensionRequestsUsecasModel> fetchExtensionRequestsUsecas(
    FetchExtensionRequestsUsecasParams params,
  ) async => const Left<Failure, FetchExtensionRequestsUsecasModel>(
    ServerFailure(message: 'not configured', statusCode: 500),
  );

  @override
  DataResponse<FetchOrdersUsecaseModel> fetchOrdersUsecase(
    FetchOrdersUsecaseParams params,
  ) async => const Left<Failure, FetchOrdersUsecaseModel>(
    ServerFailure(message: 'not configured', statusCode: 500),
  );

  @override
  DataResponse<FetchOrderDetailsUsecaseModel> fetchOrderDetailsUsecase(
    FetchOrderDetailsUsecaseParams params,
  ) async => const Left<Failure, FetchOrderDetailsUsecaseModel>(
    ServerFailure(message: 'not configured', statusCode: 500),
  );

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }

  Either<Failure, T> _next<T>(List<Either<Failure, T>> results, int index) {
    if (results.isEmpty) {
      return Left<Failure, T>(
        const ServerFailure(message: 'temporary failure', statusCode: 500),
      );
    }
    return results[index < results.length ? index : results.length - 1];
  }
}
