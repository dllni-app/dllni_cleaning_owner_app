import 'package:common_package/common_package.dart';
import 'package:dartz/dartz.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/data/models/notification_api_models.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/domain/repository/profile_repo.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/domain/usecases/delete_all_notifications_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/domain/usecases/delete_notification_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/domain/usecases/fetch_cleaning_neighborhoods_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/domain/usecases/fetch_deposit_account_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/domain/usecases/fetch_deposit_transactions_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/domain/usecases/fetch_dispute_details_usecase_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/domain/usecases/fetch_disputes_usecase_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/domain/usecases/fetch_notifications_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/domain/usecases/fetch_worker_profile_usecase_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/domain/usecases/fetch_worker_reviews_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/domain/usecases/fetch_worker_statistics_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/domain/usecases/fetch_worker_working_hours_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/domain/usecases/mark_all_notifications_read_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/domain/usecases/mark_notification_read_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/domain/usecases/update_dispute_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/domain/usecases/update_worker_profile_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/domain/usecases/update_worker_work_areas_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/domain/usecases/update_worker_working_hours_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/view/manager/bloc/profile_bloc.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/view/screens/notifications_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../../support/finish_widget_cleanup.dart';

void main() {
  testWidgets('empty feed and recoverable load failure offer a working retry', (
    WidgetTester tester,
  ) async {
    final bloc = _buildBloc([
      const Left<Failure, FetchNotificationsPageModel>(
        ServerFailure(message: 'offline', statusCode: 500),
      ),
      const Right<Failure, FetchNotificationsPageModel>(
        FetchNotificationsPageModel(
          data: <NotificationResourceModel>[],
          meta: PaginationMetaModel(currentPage: 1, perPage: 10, total: 0),
        ),
      ),
    ]);
    await _pumpScreen(tester, bloc);

    expect(
      find.text('تعذر تحميل الإشعارات. تحقق من الاتصال ثم حاول مرة أخرى.'),
      findsOneWidget,
    );
    await tester.tap(find.text('إعادة المحاولة'));
    await tester.pumpAndSettle();
    expect(find.text('لا توجد إشعارات'), findsOneWidget);

    await _disposeScreen(tester, bloc);
  });

  testWidgets('transient refresh failure keeps prior rows and shows recovery', (
    WidgetTester tester,
  ) async {
    final bloc = _buildBloc([
      Right<Failure, FetchNotificationsPageModel>(_pageWithPrivateRow()),
      const Left<Failure, FetchNotificationsPageModel>(
        ServerFailure(message: 'temporary network error', statusCode: 500),
      ),
    ]);
    await _pumpScreen(tester, bloc);
    expect(find.text('Private notification'), findsOneWidget);

    bloc.add(
      FetchNotificationsEvent(
        params: FetchNotificationsParams(),
        isReload: true,
        preserveExisting: true,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Private notification'), findsOneWidget);
    expect(
      find.text('تعذر تحميل الإشعارات. تحقق من الاتصال ثم حاول مرة أخرى.'),
      findsOneWidget,
    );
    await _disposeScreen(tester, bloc);
  });

  testWidgets('403 refresh conceals rows authorized by an earlier response', (
    WidgetTester tester,
  ) async {
    final bloc = _buildBloc([
      Right<Failure, FetchNotificationsPageModel>(_pageWithPrivateRow()),
      const Left<Failure, FetchNotificationsPageModel>(
        ServerFailure(message: 'forbidden', statusCode: 403),
      ),
    ]);
    await _pumpScreen(tester, bloc);
    expect(find.text('Private notification'), findsOneWidget);

    bloc.add(
      FetchNotificationsEvent(
        params: FetchNotificationsParams(),
        isReload: true,
        preserveExisting: true,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Private notification'), findsNothing);
    expect(
      find.text('لا تملك صلاحية الوصول إلى هذه الإشعارات.'),
      findsOneWidget,
    );
    await _disposeScreen(tester, bloc);
  });

  testWidgets(
    'initial reload failure does not restore stale notification rows',
    (WidgetTester tester) async {
      final bloc = _buildBloc([
        Right<Failure, FetchNotificationsPageModel>(_pageWithPrivateRow()),
        const Left<Failure, FetchNotificationsPageModel>(
          ServerFailure(message: 'temporary network error', statusCode: 500),
        ),
      ]);
      await _pumpScreen(tester, bloc);
      expect(find.text('Private notification'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await _pumpScreen(tester, bloc);

      expect(find.text('Private notification'), findsNothing);
      expect(
        find.text('تعذر تحميل الإشعارات. تحقق من الاتصال ثم حاول مرة أخرى.'),
        findsOneWidget,
      );
      await _disposeScreen(tester, bloc);
    },
  );
}

Future<void> _pumpScreen(WidgetTester tester, ProfileBloc bloc) async {
  await tester.pumpWidget(
    MaterialApp(
      home: NotificationsScreen(
        args: NotificationsScreenParams(profileBloc: bloc),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _disposeScreen(WidgetTester tester, ProfileBloc bloc) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await finishWidgetCleanup(tester, bloc.close());
}

FetchNotificationsPageModel _pageWithPrivateRow() =>
    FetchNotificationsPageModel(
      data: <NotificationResourceModel>[
        NotificationResourceModel(
          id: 'private-1',
          type: 'general',
          title: 'Private notification',
          body: 'Authorized message',
          createdAt: DateTime.now().toIso8601String(),
        ),
      ],
      meta: const PaginationMetaModel(currentPage: 1, perPage: 10, total: 1),
    );

ProfileBloc _buildBloc(
  List<Either<Failure, FetchNotificationsPageModel>> responses,
) {
  final repo = _UnusedProfileRepo();
  final fetchNotifications = _QueuedFetchNotificationsUseCase(
    profileRepo: repo,
    responses: responses,
  );
  return ProfileBloc(
    FetchWorkerProfileUsecaseUseCase(profile: repo),
    FetchDisputesUsecaseUseCase(profile: repo),
    FetchDisputeDetailsUsecaseUseCase(profile: repo),
    FetchWorkerStatisticsUseCase(profile: repo),
    UpdateWorkerWorkAreasUseCase(profile: repo),
    UpdateDisputeUseCase(profile: repo),
    UpdateWorkerProfileUseCase(profile: repo),
    FetchDepositAccountUseCase(profileRepo: repo),
    FetchDepositTransactionsUseCase(profileRepo: repo),
    fetchNotifications,
    MarkAllNotificationsReadUseCase(profileRepo: repo),
    MarkNotificationReadUseCase(profileRepo: repo),
    DeleteNotificationUseCase(profileRepo: repo),
    DeleteAllNotificationsUseCase(profileRepo: repo),
    FetchWorkerReviewsUseCase(profileRepo: repo),
    FetchCleaningNeighborhoodsUseCase(profile: repo),
    FetchWorkerWorkingHoursUseCase(profile: repo),
    UpdateWorkerWorkingHoursUseCase(profile: repo),
  );
}

class _QueuedFetchNotificationsUseCase extends FetchNotificationsUseCase {
  _QueuedFetchNotificationsUseCase({
    required super.profileRepo,
    required this.responses,
  });

  final List<Either<Failure, FetchNotificationsPageModel>> responses;
  var _index = 0;

  @override
  DataResponse<FetchNotificationsPageModel> call(
    FetchNotificationsParams params,
  ) async {
    final index = _index++;
    return responses[index < responses.length ? index : responses.length - 1];
  }
}

class _UnusedProfileRepo implements ProfileRepo {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
