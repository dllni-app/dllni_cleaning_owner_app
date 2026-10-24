import 'package:flutter_test/flutter_test.dart';

Future<void> finishWidgetCleanup(
  WidgetTester tester,
  Future<void> cleanup,
) async {
  var finished = false;
  final completion = cleanup.then((_) => finished = true);
  // BLoC cancellation can cross the widget clock and real stream callbacks.
  for (var attempt = 0; attempt < 50 && !finished; attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 1)),
    );
    await tester.pump(const Duration(milliseconds: 10));
  }
  expect(finished, isTrue, reason: 'widget cleanup completes');
  await completion;
}
