import 'package:common_package/common_package.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('bootstrapApp throws when supportedLocales is empty', () async {
    final config = AppBootstrapConfig(
      navigatorKey: GlobalKey<NavigatorState>(),
      app: const SizedBox.shrink(),
      configureDependencies: () async {},
      enableNotifications: false,
      supportedLocales: const [],
    );

    await expectLater(bootstrapApp(config), throwsArgumentError);
  });

  testWidgets('bootstrapApp runs when notifications are disabled', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    var configured = false;
    await bootstrapApp(
      AppBootstrapConfig(
        navigatorKey: GlobalKey<NavigatorState>(),
        app: const MaterialApp(
          home: Scaffold(body: Text('Bootstrapped')),
        ),
        configureDependencies: () async {
          configured = true;
        },
        enableNotifications: false,
      ),
    );

    await tester.pumpAndSettle();
    expect(configured, isTrue);
    expect(find.text('Bootstrapped'), findsOneWidget);
  });

  test('common_package export smoke', () {
    const routePage = AutoRoutePage(path: '/sample');
    final noParams = NoParams();
    const pagination = PaginationStateModel<int>();

    expect(routePage.path, '/sample');
    expect(noParams.getBody(), isEmpty);
    expect(noParams.getParams(), isEmpty);
    expect(pagination.status, BlocStatus.init);
  });
}
