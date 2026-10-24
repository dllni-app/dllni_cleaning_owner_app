import 'package:common_package/common_package.dart';
import 'package:dartz/dartz.dart';
import 'package:dllni_cleaninig_owner_app/features/home/data/models/fetch_home_page_usecase_model.dart';
import 'package:dllni_cleaninig_owner_app/features/home/domain/repository/home_repo.dart';
import 'package:dllni_cleaninig_owner_app/features/home/domain/usecases/fetch_home_page_usecase_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/home/view/manager/bloc/home_bloc.dart';
import 'package:dllni_cleaninig_owner_app/features/home/view/widgets/statistics_row.dart';
import 'package:dllni_cleaninig_owner_app/features/home/view/widgets/today_overview_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../../support/finish_widget_cleanup.dart';

void main() {
  testWidgets(
    'unknown and nonfinite earnings stay unknown on both home cards',
    (WidgetTester tester) async {
      for (final earnings in <double?>[
        null,
        double.nan,
        double.infinity,
        0,
        125,
      ]) {
        final bloc = HomeBloc(
          FetchHomePageUsecaseUseCase(home: _HomeRepo(earnings: earnings)),
        );
        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider.value(
              value: bloc,
              child: Scaffold(
                body: Column(
                  children: [
                    const TodayOverviewCard(),
                    StatisticsRow(onStatusTap: (_) {}, onStatisticsTap: () {}),
                  ],
                ),
              ),
            ),
          ),
        );
        bloc.add(
          FetchHomePageUsecaseEvent(params: FetchHomePageUsecaseParams()),
        );
        await tester.pumpAndSettle();

        if (earnings == null || !earnings.isFinite) {
          expect(find.text('— ل.س'), findsOneWidget);
          expect(find.text('—'), findsOneWidget);
        } else {
          final formatted = earnings == 0 ? '0' : '125';
          expect(find.text('$formatted ل.س'), findsNWidgets(2));
        }
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(const SizedBox.shrink());
        await finishWidgetCleanup(tester, bloc.close());
      }
    },
  );

  testWidgets(
    'home earnings and metric labels remain readable at large text scales',
    (WidgetTester tester) async {
      for (final width in <double>[320, 360, 430]) {
        for (final scale in <double>[1.5, 2]) {
          tester.view.physicalSize = Size(width, 1200);
          tester.view.devicePixelRatio = 1;
          final bloc = HomeBloc(
            FetchHomePageUsecaseUseCase(home: _HomeRepo(earnings: 300)),
          );
          var earningsTapped = false;
          await tester.pumpWidget(
            MaterialApp(
              home: BlocProvider.value(
                value: bloc,
                child: MediaQuery(
                  data: MediaQueryData(
                    size: Size(width, 1200),
                    textScaler: TextScaler.linear(scale),
                  ),
                  child: Scaffold(
                    body: SingleChildScrollView(
                      child: Column(
                        children: [
                          const TodayOverviewCard(),
                          StatisticsRow(
                            onStatusTap: (_) {},
                            onStatisticsTap: () => earningsTapped = true,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          bloc.add(
            FetchHomePageUsecaseEvent(params: FetchHomePageUsecaseParams()),
          );
          await tester.pumpAndSettle();

          expect(find.text('إجمالي الطلبات'), findsOneWidget);
          final metricLabel = tester.renderObject<RenderParagraph>(
            find.text('إجمالي الطلبات'),
          );
          expect(metricLabel.didExceedMaxLines, isFalse);
          expect(find.text('300 ل.س'), findsNWidgets(2));
          for (var index = 0; index < 2; index++) {
            final earningsText = tester.renderObject<RenderParagraph>(
              find.text('300 ل.س').at(index),
            );
            expect(earningsText.didExceedMaxLines, isFalse);
          }
          expect(
            tester.takeException(),
            isNull,
            reason: '$width dp at $scale x',
          );

          await tester.ensureVisible(find.text('الإيرادات'));
          await tester.tap(find.text('الإيرادات'));
          expect(earningsTapped, isTrue);
          await tester.pumpWidget(const SizedBox.shrink());
          await finishWidgetCleanup(tester, bloc.close());
        }
      }
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    },
  );
}

class _HomeRepo implements HomeRepo {
  _HomeRepo({required this.earnings});

  final double? earnings;

  @override
  DataResponse<FetchHomePageUsecaseModel> fetchHomePageUsecase(
    FetchHomePageUsecaseParams params,
  ) async => Right<Failure, FetchHomePageUsecaseModel>(
    FetchHomePageUsecaseModel(totalEarnings: earnings),
  );
}
