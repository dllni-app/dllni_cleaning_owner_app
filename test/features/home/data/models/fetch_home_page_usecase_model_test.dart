import 'package:dllni_cleaninig_owner_app/features/home/data/models/fetch_home_page_usecase_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FetchHomePageUsecaseModel parsing', () {
    test('parses dashboard payload with new additive wallet fields', () {
      final model = fetchHomePageUsecaseModelFromJson(<String, dynamic>{
        'date': '2026-05-27',
        'totalBookings': 42,
        'todayCount': 3,
        'completedCount': 30,
        'pendingCount': 7,
        'inProgressCount': 2,
        'cancelledCount': 3,
        'totalEarnings': 8450000,
        'todayEarnings': 420000,
        'earningsChangePercent': 11.4,
        'newOrdersCount': 4,
        'pendingExtensionRequestsCount': 1,
        'amountSummary': <String, dynamic>{
          'period': 'last_4_weeks',
          'currency': 'SYP',
          'workerAmount': 8450000,
          'adminAmount': 1950000,
          'grossInvoicesAmount': 10400000,
        },
        'bookingsWeeklyChart': <Map<String, dynamic>>[
          <String, dynamic>{
            'date': '2026-05-25',
            'dayKey': 'monday',
            'dayLabelAr': 'الاثنين',
            'bookingsCount': 8,
          },
          <String, dynamic>{
            'date': '2026-05-26',
            'dayKey': 'tuesday',
            'dayLabelAr': 'الثلاثاء',
            'bookingsCount': 12,
          },
        ],
        'invoicesFourWeeksChart': <Map<String, dynamic>>[
          <String, dynamic>{
            'weekNumber': 1,
            'label': 'week_1',
            'from': '2026-05-04',
            'to': '2026-05-10',
            'invoiceAmount': 420000,
            'invoiceAmountThousands': 420,
          },
          <String, dynamic>{
            'weekNumber': 2,
            'label': 'week_2',
            'from': '2026-05-11',
            'to': '2026-05-17',
            'invoiceAmount': 510000,
            'invoiceAmountThousands': 510,
          },
        ],
      });

      expect(model.date, '2026-05-27');
      expect(model.earningsChangePercent, 11.4);
      expect(model.amountSummary, isNotNull);
      expect(model.amountSummary!.workerAmount, 8450000);
      expect(model.amountSummary!.adminAmount, 1950000);
      expect(model.amountSummary!.currency, 'SYP');

      expect(model.bookingsWeeklyChart, isNotNull);
      expect(model.bookingsWeeklyChart!.length, 2);
      expect(model.bookingsWeeklyChart!.first.dayKey, 'monday');
      expect(model.bookingsWeeklyChart!.first.bookingsCount, 8);

      expect(model.invoicesFourWeeksChart, isNotNull);
      expect(model.invoicesFourWeeksChart!.length, 2);
      expect(model.invoicesFourWeeksChart!.first.invoiceAmountThousands, 420);
      expect(model.invoicesFourWeeksChart!.first.weekNumber, 1);
    });

    test('remains backward compatible when new fields are absent', () {
      final model = fetchHomePageUsecaseModelFromJson(<String, dynamic>{
        'totalBookings': 12,
        'todayCount': 2,
        'completedCount': 6,
        'pendingCount': 3,
        'inProgressCount': 1,
        'cancelledCount': 2,
        'totalEarnings': 1500000,
        'todayEarnings': 120000,
        'newOrdersCount': 1,
        'pendingExtensionRequestsCount': 0,
      });

      expect(model.totalBookings, 12);
      expect(model.todayEarnings, 120000);
      expect(model.amountSummary, isNull);
      expect(model.bookingsWeeklyChart, isNull);
      expect(model.invoicesFourWeeksChart, isNull);
      expect(model.earningsChangePercent, isNull);
      expect(model.date, isNull);
    });
  });
}
