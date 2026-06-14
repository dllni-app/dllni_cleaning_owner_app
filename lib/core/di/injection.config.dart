// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:common_package/common_package.dart' as _i960;
import 'package:common_package/helpers/dio_network.dart' as _i497;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

import '../../features/auth/data/repository/auth_repo_impl.dart' as _i751;
import '../../features/auth/data/source/auth_remote_data_source.dart' as _i777;
import '../../features/auth/domain/repository/auth_repo.dart' as _i976;
import '../../features/auth/domain/usecases/login_usecase_use_case.dart'
    as _i462;
import '../../features/auth/view/manager/bloc/auth_bloc.dart' as _i958;
import '../../features/calender/data/repository/calender_repo_impl.dart'
    as _i325;
import '../../features/calender/data/source/calender_remote_data_source.dart'
    as _i148;
import '../../features/calender/domain/repository/calender_repo.dart' as _i333;
import '../../features/calender/view/manager/bloc/calender_bloc.dart' as _i472;
import '../../features/home/data/repository/home_repo_impl.dart' as _i1013;
import '../../features/home/data/source/home_remote_data_source.dart' as _i557;
import '../../features/home/domain/repository/home_repo.dart' as _i396;
import '../../features/home/domain/usecases/fetch_home_page_usecase_use_case.dart'
    as _i1024;
import '../../features/home/view/manager/bloc/home_bloc.dart' as _i648;
import '../../features/main/data/repository/main_repo_impl.dart' as _i959;
import '../../features/main/data/source/main_remote_data_source.dart' as _i931;
import '../../features/main/domain/repository/main_repo.dart' as _i540;
import '../../features/main/view/manager/bloc/main_bloc.dart' as _i98;
import '../../features/orders/data/repository/orders_repo_impl.dart' as _i849;
import '../../features/orders/data/source/orders_remote_data_source.dart'
    as _i702;
import '../../features/orders/domain/repository/orders_repo.dart' as _i132;
import '../../features/orders/domain/usecases/accept_extension_usecase_use_case.dart'
    as _i533;
import '../../features/orders/domain/usecases/accept_order_usecase_use_case.dart'
    as _i778;
import '../../features/orders/domain/usecases/arrive_use_case.dart' as _i800;
import '../../features/orders/domain/usecases/cancel_order_use_case.dart'
    as _i1;
import '../../features/orders/domain/usecases/complete_order_usecase_use_case.dart'
    as _i199;
import '../../features/orders/domain/usecases/create_cleaning_booking_sos_use_case.dart'
    as _i458;
import '../../features/orders/domain/usecases/fetch_extension_requests_usecas_use_case.dart'
    as _i717;
import '../../features/orders/domain/usecases/fetch_order_details_usecase_use_case.dart'
    as _i718;
import '../../features/orders/domain/usecases/fetch_orders_usecase_use_case.dart'
    as _i406;
import '../../features/orders/domain/usecases/fetch_security_code_use_case.dart'
    as _i310;
import '../../features/orders/domain/usecases/post_booking_location_use_case.dart'
    as _i931;
import '../../features/orders/domain/usecases/reject_extension_usecase_use_case.dart'
    as _i537;
import '../../features/orders/domain/usecases/reject_order_usecase_use_case.dart'
    as _i452;
import '../../features/orders/domain/usecases/start_travel_usecase_use_case.dart'
    as _i713;
import '../../features/orders/domain/usecases/start_work_use_case.dart'
    as _i738;
import '../../features/orders/domain/usecases/update_availability_usecase_use_case.dart'
    as _i13;
import '../../features/orders/view/manager/bloc/orders_bloc.dart' as _i305;
import '../../features/profile/data/repository/profile_repo_impl.dart' as _i265;
import '../../features/profile/data/source/profile_remote_data_source.dart'
    as _i502;
import '../../features/profile/domain/repository/profile_repo.dart' as _i275;
import '../../features/profile/domain/usecases/fetch_deposit_account_use_case.dart'
    as _i38;
import '../../features/profile/domain/usecases/fetch_deposit_transactions_use_case.dart'
    as _i547;
import '../../features/profile/domain/usecases/fetch_dispute_details_usecase_use_case.dart'
    as _i961;
import '../../features/profile/domain/usecases/fetch_disputes_usecase_use_case.dart'
    as _i947;
import '../../features/profile/domain/usecases/fetch_notifications_use_case.dart'
    as _i438;
import '../../features/profile/domain/usecases/fetch_worker_profile_usecase_use_case.dart'
    as _i338;
import '../../features/profile/domain/usecases/fetch_worker_reviews_use_case.dart'
    as _i959;
import '../../features/profile/domain/usecases/fetch_worker_statistics_use_case.dart'
    as _i280;
import '../../features/profile/domain/usecases/mark_all_notifications_read_use_case.dart'
    as _i10;
import '../../features/profile/domain/usecases/mark_notification_read_use_case.dart'
    as _i338;
import '../../features/profile/domain/usecases/update_dispute_use_case.dart'
    as _i973;
import '../../features/profile/domain/usecases/update_worker_profile_use_case.dart'
    as _i857;
import '../../features/profile/domain/usecases/update_worker_work_areas_use_case.dart'
    as _i780;
import '../../features/profile/view/manager/bloc/profile_bloc.dart' as _i821;
import '../realtime/cleaning_booking_pusher_service.dart' as _i432;
import 'injection.dart' as _i464;

// initializes the registration of main-scope dependencies inside of GetIt
_i174.GetIt $initGetIt(
  _i174.GetIt getIt, {
  String? environment,
  _i526.EnvironmentFilter? environmentFilter,
}) {
  final gh = _i526.GetItHelper(getIt, environment, environmentFilter);
  final injectableModule = _$InjectableModule();
  gh.factory<_i472.CalenderBloc>(() => _i472.CalenderBloc());
  gh.factory<_i98.MainBloc>(() => _i98.MainBloc());
  gh.singleton<_i960.DioNetwork>(() => injectableModule.dio);
  gh.lazySingleton<_i432.CleaningBookingPusherService>(
    () => _i432.CleaningBookingPusherService(),
  );
  gh.lazySingleton<_i148.CalenderRemoteDataSource>(
    () => _i148.CalenderRemoteDataSource(),
  );
  gh.lazySingleton<_i931.MainRemoteDataSource>(
    () => _i931.MainRemoteDataSource(),
  );
  gh.lazySingleton<_i540.MainRepo>(() => _i959.MainRepoImpl());
  gh.lazySingleton<_i557.HomeRemoteDataSource>(
    () => _i557.HomeRemoteDataSource(dioNetwork: gh<_i497.DioNetwork>()),
  );
  gh.lazySingleton<_i702.OrdersRemoteDataSource>(
    () => _i702.OrdersRemoteDataSource(dioNetwork: gh<_i497.DioNetwork>()),
  );
  gh.lazySingleton<_i502.ProfileRemoteDataSource>(
    () => _i502.ProfileRemoteDataSource(dioNetwork: gh<_i497.DioNetwork>()),
  );
  gh.lazySingleton<_i333.CalenderRepo>(() => _i325.CalenderRepoImpl());
  gh.lazySingleton<_i275.ProfileRepo>(
    () => _i265.ProfileRepoImpl(
      profileRemoteDataSource: gh<_i502.ProfileRemoteDataSource>(),
    ),
  );
  gh.lazySingleton<_i38.FetchDepositAccountUseCase>(
    () => _i38.FetchDepositAccountUseCase(profileRepo: gh<_i275.ProfileRepo>()),
  );
  gh.lazySingleton<_i547.FetchDepositTransactionsUseCase>(
    () => _i547.FetchDepositTransactionsUseCase(
      profileRepo: gh<_i275.ProfileRepo>(),
    ),
  );
  gh.lazySingleton<_i438.FetchNotificationsUseCase>(
    () => _i438.FetchNotificationsUseCase(profileRepo: gh<_i275.ProfileRepo>()),
  );
  gh.lazySingleton<_i959.FetchWorkerReviewsUseCase>(
    () => _i959.FetchWorkerReviewsUseCase(profileRepo: gh<_i275.ProfileRepo>()),
  );
  gh.lazySingleton<_i10.MarkAllNotificationsReadUseCase>(
    () => _i10.MarkAllNotificationsReadUseCase(
      profileRepo: gh<_i275.ProfileRepo>(),
    ),
  );
  gh.lazySingleton<_i338.MarkNotificationReadUseCase>(
    () =>
        _i338.MarkNotificationReadUseCase(profileRepo: gh<_i275.ProfileRepo>()),
  );
  gh.lazySingleton<_i777.AuthRemoteDataSource>(
    () => _i777.AuthRemoteDataSource(dioNetwork: gh<_i497.DioNetwork>()),
  );
  gh.lazySingleton<_i132.OrdersRepo>(
    () => _i849.OrdersRepoImpl(
      ordersRemoteDataSource: gh<_i702.OrdersRemoteDataSource>(),
    ),
  );
  gh.lazySingleton<_i396.HomeRepo>(
    () => _i1013.HomeRepoImpl(
      homeRemoteDataSource: gh<_i557.HomeRemoteDataSource>(),
    ),
  );
  gh.lazySingleton<_i533.AcceptExtensionUsecaseUseCase>(
    () => _i533.AcceptExtensionUsecaseUseCase(orders: gh<_i132.OrdersRepo>()),
  );
  gh.lazySingleton<_i778.AcceptOrderUsecaseUseCase>(
    () => _i778.AcceptOrderUsecaseUseCase(orders: gh<_i132.OrdersRepo>()),
  );
  gh.lazySingleton<_i800.ArriveUseCase>(
    () => _i800.ArriveUseCase(orders: gh<_i132.OrdersRepo>()),
  );
  gh.lazySingleton<_i1.CancelOrderUseCase>(
    () => _i1.CancelOrderUseCase(orders: gh<_i132.OrdersRepo>()),
  );
  gh.lazySingleton<_i199.CompleteOrderUsecaseUseCase>(
    () => _i199.CompleteOrderUsecaseUseCase(orders: gh<_i132.OrdersRepo>()),
  );
  gh.lazySingleton<_i458.CreateCleaningBookingSosUseCase>(
    () => _i458.CreateCleaningBookingSosUseCase(orders: gh<_i132.OrdersRepo>()),
  );
  gh.lazySingleton<_i717.FetchExtensionRequestsUsecasUseCase>(
    () => _i717.FetchExtensionRequestsUsecasUseCase(
      orders: gh<_i132.OrdersRepo>(),
    ),
  );
  gh.lazySingleton<_i718.FetchOrderDetailsUsecaseUseCase>(
    () => _i718.FetchOrderDetailsUsecaseUseCase(orders: gh<_i132.OrdersRepo>()),
  );
  gh.lazySingleton<_i406.FetchOrdersUsecaseUseCase>(
    () => _i406.FetchOrdersUsecaseUseCase(orders: gh<_i132.OrdersRepo>()),
  );
  gh.lazySingleton<_i310.FetchSecurityCodeUseCase>(
    () => _i310.FetchSecurityCodeUseCase(orders: gh<_i132.OrdersRepo>()),
  );
  gh.lazySingleton<_i931.PostBookingLocationUseCase>(
    () => _i931.PostBookingLocationUseCase(orders: gh<_i132.OrdersRepo>()),
  );
  gh.lazySingleton<_i537.RejectExtensionUsecaseUseCase>(
    () => _i537.RejectExtensionUsecaseUseCase(orders: gh<_i132.OrdersRepo>()),
  );
  gh.lazySingleton<_i452.RejectOrderUsecaseUseCase>(
    () => _i452.RejectOrderUsecaseUseCase(orders: gh<_i132.OrdersRepo>()),
  );
  gh.lazySingleton<_i713.StartTravelUsecaseUseCase>(
    () => _i713.StartTravelUsecaseUseCase(orders: gh<_i132.OrdersRepo>()),
  );
  gh.lazySingleton<_i738.StartWorkUseCase>(
    () => _i738.StartWorkUseCase(orders: gh<_i132.OrdersRepo>()),
  );
  gh.lazySingleton<_i13.UpdateAvailabilityUsecaseUseCase>(
    () => _i13.UpdateAvailabilityUsecaseUseCase(orders: gh<_i132.OrdersRepo>()),
  );
  gh.lazySingleton<_i961.FetchDisputeDetailsUsecaseUseCase>(
    () => _i961.FetchDisputeDetailsUsecaseUseCase(
      profile: gh<_i275.ProfileRepo>(),
    ),
  );
  gh.lazySingleton<_i947.FetchDisputesUsecaseUseCase>(
    () => _i947.FetchDisputesUsecaseUseCase(profile: gh<_i275.ProfileRepo>()),
  );
  gh.lazySingleton<_i338.FetchWorkerProfileUsecaseUseCase>(
    () => _i338.FetchWorkerProfileUsecaseUseCase(
      profile: gh<_i275.ProfileRepo>(),
    ),
  );
  gh.lazySingleton<_i280.FetchWorkerStatisticsUseCase>(
    () => _i280.FetchWorkerStatisticsUseCase(profile: gh<_i275.ProfileRepo>()),
  );
  gh.lazySingleton<_i973.UpdateDisputeUseCase>(
    () => _i973.UpdateDisputeUseCase(profile: gh<_i275.ProfileRepo>()),
  );
  gh.lazySingleton<_i857.UpdateWorkerProfileUseCase>(
    () => _i857.UpdateWorkerProfileUseCase(profile: gh<_i275.ProfileRepo>()),
  );
  gh.lazySingleton<_i780.UpdateWorkerWorkAreasUseCase>(
    () => _i780.UpdateWorkerWorkAreasUseCase(profile: gh<_i275.ProfileRepo>()),
  );
  gh.lazySingleton<_i976.AuthRepo>(
    () => _i751.AuthRepoImpl(
      authRemoteDataSource: gh<_i777.AuthRemoteDataSource>(),
    ),
  );
  gh.lazySingleton<_i1024.FetchHomePageUsecaseUseCase>(
    () => _i1024.FetchHomePageUsecaseUseCase(home: gh<_i396.HomeRepo>()),
  );
  gh.factory<_i821.ProfileBloc>(
    () => _i821.ProfileBloc(
      gh<_i338.FetchWorkerProfileUsecaseUseCase>(),
      gh<_i947.FetchDisputesUsecaseUseCase>(),
      gh<_i961.FetchDisputeDetailsUsecaseUseCase>(),
      gh<_i280.FetchWorkerStatisticsUseCase>(),
      gh<_i780.UpdateWorkerWorkAreasUseCase>(),
      gh<_i973.UpdateDisputeUseCase>(),
      gh<_i857.UpdateWorkerProfileUseCase>(),
      gh<_i38.FetchDepositAccountUseCase>(),
      gh<_i547.FetchDepositTransactionsUseCase>(),
      gh<_i438.FetchNotificationsUseCase>(),
      gh<_i10.MarkAllNotificationsReadUseCase>(),
      gh<_i338.MarkNotificationReadUseCase>(),
      gh<_i959.FetchWorkerReviewsUseCase>(),
    ),
  );
  gh.factory<_i648.HomeBloc>(
    () => _i648.HomeBloc(gh<_i1024.FetchHomePageUsecaseUseCase>()),
  );
  gh.factory<_i305.OrdersBloc>(
    () => _i305.OrdersBloc(
      gh<_i406.FetchOrdersUsecaseUseCase>(),
      gh<_i718.FetchOrderDetailsUsecaseUseCase>(),
      gh<_i778.AcceptOrderUsecaseUseCase>(),
      gh<_i713.StartTravelUsecaseUseCase>(),
      gh<_i199.CompleteOrderUsecaseUseCase>(),
      gh<_i1.CancelOrderUseCase>(),
      gh<_i717.FetchExtensionRequestsUsecasUseCase>(),
      gh<_i533.AcceptExtensionUsecaseUseCase>(),
      gh<_i537.RejectExtensionUsecaseUseCase>(),
      gh<_i13.UpdateAvailabilityUsecaseUseCase>(),
      gh<_i452.RejectOrderUsecaseUseCase>(),
      gh<_i800.ArriveUseCase>(),
      gh<_i931.PostBookingLocationUseCase>(),
      gh<_i310.FetchSecurityCodeUseCase>(),
      gh<_i738.StartWorkUseCase>(),
    ),
  );
  gh.lazySingleton<_i462.LoginUsecaseUseCase>(
    () => _i462.LoginUsecaseUseCase(auth: gh<_i976.AuthRepo>()),
  );
  gh.factory<_i958.AuthBloc>(
    () => _i958.AuthBloc(gh<_i462.LoginUsecaseUseCase>()),
  );
  return getIt;
}

class _$InjectableModule extends _i464.InjectableModule {}
