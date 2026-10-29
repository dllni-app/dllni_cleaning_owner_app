import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dllni_cleaninig_owner_app/features/home/view/widgets/worker_v2_replacement_offers_card.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/models/worker_v2_replacement_offer.dart';

class _OffersGateway implements WorkerV2ReplacementOffersGateway {
  _OffersGateway(this.offers);

  final List<WorkerV2ReplacementOffer> offers;
  int accepts = 0;

  @override
  Future<List<WorkerV2ReplacementOffer>> fetch() async =>
      List<WorkerV2ReplacementOffer>.from(offers);

  @override
  Future<bool> accept(WorkerV2ReplacementOffer offer) async {
    accepts++;
    return true;
  }
}

void main() {
  const offer = WorkerV2ReplacementOffer(
    requestId: 9,
    bookingId: 84,
    visitSequence: 2,
    scheduledDate: '2026-10-30',
    scheduledTime: '09:00',
  );

  test('parses only authenticated valid server offer envelopes', () {
    final decoded = workerV2ReplacementOffersFromJson({
      'data': {
        'offers': [
          {
            'requestId': 9,
            'bookingId': 84,
            'visitSequence': 2,
            'scheduledDate': '2026-10-30',
            'scheduledTime': '09:00',
          },
          {'requestId': -1, 'bookingId': 84, 'visitSequence': 1},
        ],
      },
    });
    expect(decoded, hasLength(1));
    expect(decoded.single.bookingId, 84);
    expect(workerV2ReplacementOffersFromJson({'data': null}), isEmpty);
  });

  testWidgets('hides the offer card when this worker has no offers', (
    tester,
  ) async {
    final gateway = _OffersGateway([]);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: WorkerV2ReplacementOffersCard(gateway: gateway)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('عروض زيارات بديلة'), findsNothing);
    expect(find.byType(FilledButton), findsNothing);
    expect(gateway.accepts, 0);
  });

  testWidgets('accepts one specific visit only after worker confirmation', (
    tester,
  ) async {
    final gateway = _OffersGateway([offer]);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: WorkerV2ReplacementOffersCard(gateway: gateway)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('الزيارة 2 — 2026-10-30 09:00'), findsOneWidget);
    await tester.tap(find.byKey(const Key('v2-accept-replacement-9')));
    await tester.pumpAndSettle();
    expect(gateway.accepts, 0);
    await tester.tap(find.text('ليس الآن'));
    await tester.pumpAndSettle();
    expect(gateway.accepts, 0);
    await tester.tap(find.byKey(const Key('v2-accept-replacement-9')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('أوافق على هذه الزيارة'));
    await tester.pumpAndSettle();
    expect(gateway.accepts, 1);
    expect(find.byKey(const Key('v2-accept-replacement-9')), findsNothing);
  });
}
