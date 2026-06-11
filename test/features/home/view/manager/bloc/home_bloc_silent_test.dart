import 'package:common_package/common_package.dart';
import 'package:dartz/dartz.dart';
import 'package:dllni_cleaninig_owner_app/features/home/data/models/fetch_home_page_usecase_model.dart';
import 'package:dllni_cleaninig_owner_app/features/home/domain/repository/home_repo.dart';
import 'package:dllni_cleaninig_owner_app/features/home/domain/usecases/fetch_home_page_usecase_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/home/view/manager/bloc/home_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HomeBloc silent fetch', () {
    test('silent fetch does not emit loading when existing data is present', () async {
      final repo = _FakeHomeRepo(
        responses: const [
          _HomeRepoResponse(pendingCount: 1),
          _HomeRepoResponse(pendingCount: 2),
        ],
      );
      final bloc = HomeBloc(FetchHomePageUsecaseUseCase(home: repo));

      bloc.add(FetchHomePageUsecaseEvent(params: FetchHomePageUsecaseParams()));
      await _flushBlocQueue();

      expect(bloc.state.homePageUsecaseStatus, BlocStatus.success);
      expect(bloc.state.homePageUsecase?.pendingCount, 1);

      final statuses = <BlocStatus?>[];
      final subscription = bloc.stream.listen(
        (state) => statuses.add(state.homePageUsecaseStatus),
      );

      bloc.add(
        FetchHomePageUsecaseEvent(
          params: FetchHomePageUsecaseParams(),
          silent: true,
        ),
      );
      await _flushBlocQueue();
      await subscription.cancel();

      expect(statuses.where((status) => status == BlocStatus.loading), isEmpty);
      expect(bloc.state.homePageUsecaseStatus, BlocStatus.success);
      expect(bloc.state.homePageUsecase?.pendingCount, 2);
      await bloc.close();
    });

    test('silent failure preserves previous successful state', () async {
      final repo = _FakeHomeRepo(
        responses: const [
          _HomeRepoResponse(pendingCount: 3),
          _HomeRepoResponse(failure: true),
        ],
      );
      final bloc = HomeBloc(FetchHomePageUsecaseUseCase(home: repo));

      bloc.add(FetchHomePageUsecaseEvent(params: FetchHomePageUsecaseParams()));
      await _flushBlocQueue();
      expect(bloc.state.homePageUsecase?.pendingCount, 3);

      bloc.add(
        FetchHomePageUsecaseEvent(
          params: FetchHomePageUsecaseParams(),
          silent: true,
        ),
      );
      await _flushBlocQueue();

      expect(bloc.state.homePageUsecaseStatus, BlocStatus.success);
      expect(bloc.state.homePageUsecase?.pendingCount, 3);
      await bloc.close();
    });
  });
}

Future<void> _flushBlocQueue() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

class _HomeRepoResponse {
  const _HomeRepoResponse({this.pendingCount, this.failure = false});

  final int? pendingCount;
  final bool failure;
}

class _FakeHomeRepo implements HomeRepo {
  _FakeHomeRepo({required this.responses});

  final List<_HomeRepoResponse> responses;
  int _callIndex = 0;

  @override
  DataResponse<FetchHomePageUsecaseModel> fetchHomePageUsecase(
    FetchHomePageUsecaseParams params,
  ) async {
    final response = responses[_callIndex >= responses.length
        ? responses.length - 1
        : _callIndex];
    _callIndex++;

    if (response.failure) {
      return const Left(ServerFailure(message: 'network error'));
    }

    return Right(
      FetchHomePageUsecaseModel(pendingCount: response.pendingCount),
    );
  }
}
