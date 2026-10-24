import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dllni_cleaninig_owner_app/presentation/worker_v2/design_system/design_system.dart';
import 'package:dllni_cleaninig_owner_app/presentation/worker_v2/design_system/examples/component_gallery.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final font = FontLoader('cairo')
      ..addFont(rootBundle.load('assets/fonts/cairo.ttf'));
    await font.load();
    final icons = FontLoader('MaterialIcons')..addFont(_materialIconFont());
    await icons.load();
  });

  for (final arabic in [true, false]) {
    testWidgets('component gallery ${arabic ? 'Arabic RTL' : 'English LTR'}', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(430, 1360);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: WorkerV2Theme.light(),
          locale: Locale(arabic ? 'ar' : 'en'),
          home: Directionality(
            textDirection: arabic ? TextDirection.rtl : TextDirection.ltr,
            child: WrComponentGallery(arabic: arabic),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(WrSectionPanel), findsNWidgets(4));
      final rows = tester
          .widgetList<WrListRow>(find.byType(WrListRow))
          .toList();
      final intervalRows = rows
          .where((row) => row.subtitle?.contains('UTC') ?? false)
          .toList();
      expect(intervalRows.length, 3);
      expect(
        intervalRows.map((row) => row.subtitleDirection),
        everyElement(TextDirection.ltr),
      );
      final intervalText = find.text(intervalRows.first.subtitle!);
      expect(
        tester
            .widget<Directionality>(
              find
                  .ancestor(
                    of: intervalText,
                    matching: find.byType(Directionality),
                  )
                  .first,
            )
            .textDirection,
        TextDirection.ltr,
      );
      expect(
        tester
            .widget<Directionality>(
              find
                  .ancestor(
                    of: find.text(arabic ? 'مثال غرفة 1' : 'Sample room 1'),
                    matching: find.byType(Directionality),
                  )
                  .first,
            )
            .textDirection,
        arabic ? TextDirection.rtl : TextDirection.ltr,
      );
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/gallery_${arabic ? 'ar' : 'en'}_430.png'),
      );
    });
  }

  testWidgets('five RTL navigation entries fit at 320px and scale 2', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: WorkerV2Theme.light(),
        locale: const Locale('ar'),
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: const Directionality(
            textDirection: TextDirection.rtl,
            child: WrComponentGallery(arabic: true),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(WrNavigationItem), findsNWidgets(5));
    final utcRow = tester
        .widgetList<WrListRow>(find.byType(WrListRow))
        .firstWhere((row) => row.subtitle?.contains('UTC') ?? false);
    expect(utcRow.subtitleDirection, TextDirection.ltr);
    expect(
      tester
          .widget<Directionality>(
            find
                .ancestor(
                  of: find.text(utcRow.subtitle!),
                  matching: find.byType(Directionality),
                )
                .first,
          )
          .textDirection,
      TextDirection.ltr,
    );
    expect(find.text('الأرباح'), findsWidgets);
    expect(find.text('الحساب'), findsOneWidget);
    await tester.ensureVisible(find.text('13.25 USD'));
    await tester.pumpAndSettle();
    expect(find.text('13.25 USD'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<ByteData> _materialIconFont() async {
  // Flutter's SDK supplies the icons. Resolve it from the active test engine
  // so goldens render real glyphs without adding app fonts/assets.
  var directory = File(Platform.resolvedExecutable).absolute.parent;
  for (var i = 0; i < 12; i++) {
    final file = File(
      '${directory.path}${Platform.pathSeparator}'
      'bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    );
    if (await file.exists()) {
      return ByteData.sublistView(await file.readAsBytes());
    }
    if (directory.parent.path == directory.path) break;
    directory = directory.parent;
  }
  throw StateError('Flutter SDK MaterialIcons font unavailable for gallery');
}
