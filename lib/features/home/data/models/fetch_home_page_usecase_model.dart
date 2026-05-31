import 'dart:convert';

String? _asString(dynamic value) {
  if (value == null) return null;
  if (value is String) return value;
  if (value is num || value is bool) return value.toString();
  return null;
}

int? _asInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) {
    return int.tryParse(value) ?? double.tryParse(value)?.toInt();
  }
  return null;
}

double? _asDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

num? _asNum(dynamic value) {
  if (value == null) return null;
  if (value is num) return value;
  if (value is String) return num.tryParse(value);
  return null;
}

FetchHomePageUsecaseModel fetchHomePageUsecaseModelFromJson(str) =>
    FetchHomePageUsecaseModel.fromJson(str);

String fetchHomePageUsecaseModelToJson(FetchHomePageUsecaseModel data) =>
    json.encode(data.toJson());

class FetchHomePageUsecaseModel {
  String? date;
  int? totalBookings;
  int? todayCount;
  int? completedCount;
  int? pendingCount;
  int? inProgressCount;
  int? cancelledCount;
  double? totalEarnings;
  double? todayEarnings;
  double? earningsChangePercent;
  int? newOrdersCount;
  int? pendingExtensionRequestsCount;
  AmountSummary? amountSummary;
  List<BookingsWeeklyChartItem>? bookingsWeeklyChart;
  List<InvoicesFourWeeksChartItem>? invoicesFourWeeksChart;

  FetchHomePageUsecaseModel({
    this.date,
    this.totalBookings,
    this.todayCount,
    this.completedCount,
    this.pendingCount,
    this.inProgressCount,
    this.cancelledCount,
    this.totalEarnings,
    this.todayEarnings,
    this.earningsChangePercent,
    this.newOrdersCount,
    this.pendingExtensionRequestsCount,
    this.amountSummary,
    this.bookingsWeeklyChart,
    this.invoicesFourWeeksChart,
  });

  factory FetchHomePageUsecaseModel.fromJson(Map<String, dynamic> json) {
    final amountSummaryJson = json['amountSummary'];
    final bookingsWeeklyChartJson = json['bookingsWeeklyChart'];
    final invoicesFourWeeksChartJson = json['invoicesFourWeeksChart'];

    return FetchHomePageUsecaseModel(
      date: _asString(json['date']),
      totalBookings: _asInt(json['totalBookings']),
      todayCount: _asInt(json['todayCount']),
      completedCount: _asInt(json['completedCount']),
      pendingCount: _asInt(json['pendingCount']),
      inProgressCount: _asInt(json['inProgressCount']),
      cancelledCount: _asInt(json['cancelledCount']),
      totalEarnings: _asDouble(json['totalEarnings']),
      todayEarnings: _asDouble(json['todayEarnings']),
      earningsChangePercent: _asDouble(json['earningsChangePercent']),
      newOrdersCount: _asInt(json['newOrdersCount']),
      pendingExtensionRequestsCount: _asInt(
        json['pendingExtensionRequestsCount'],
      ),
      amountSummary: amountSummaryJson is Map
          ? AmountSummary.fromJson(Map<String, dynamic>.from(amountSummaryJson))
          : null,
      bookingsWeeklyChart: bookingsWeeklyChartJson is List
          ? bookingsWeeklyChartJson
                .whereType<Map>()
                .map(
                  (item) => BookingsWeeklyChartItem.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
          : null,
      invoicesFourWeeksChart: invoicesFourWeeksChartJson is List
          ? invoicesFourWeeksChartJson
                .whereType<Map>()
                .map(
                  (item) => InvoicesFourWeeksChartItem.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'totalBookings': totalBookings,
      'todayCount': todayCount,
      'completedCount': completedCount,
      'pendingCount': pendingCount,
      'inProgressCount': inProgressCount,
      'cancelledCount': cancelledCount,
      'totalEarnings': totalEarnings,
      'todayEarnings': todayEarnings,
      'earningsChangePercent': earningsChangePercent,
      'newOrdersCount': newOrdersCount,
      'pendingExtensionRequestsCount': pendingExtensionRequestsCount,
      'amountSummary': amountSummary?.toJson(),
      'bookingsWeeklyChart': bookingsWeeklyChart
          ?.map((item) => item.toJson())
          .toList(),
      'invoicesFourWeeksChart': invoicesFourWeeksChart
          ?.map((item) => item.toJson())
          .toList(),
    };
  }
}

class AmountSummary {
  String? period;
  String? currency;
  num? workerAmount;
  num? adminAmount;
  num? grossInvoicesAmount;

  AmountSummary({
    this.period,
    this.currency,
    this.workerAmount,
    this.adminAmount,
    this.grossInvoicesAmount,
  });

  factory AmountSummary.fromJson(Map<String, dynamic> json) {
    return AmountSummary(
      period: _asString(json['period']),
      currency: _asString(json['currency']),
      workerAmount: _asNum(json['workerAmount']),
      adminAmount: _asNum(json['adminAmount']),
      grossInvoicesAmount: _asNum(json['grossInvoicesAmount']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'period': period,
      'currency': currency,
      'workerAmount': workerAmount,
      'adminAmount': adminAmount,
      'grossInvoicesAmount': grossInvoicesAmount,
    };
  }
}

class BookingsWeeklyChartItem {
  String? date;
  String? dayKey;
  String? dayLabelAr;
  int? bookingsCount;

  BookingsWeeklyChartItem({
    this.date,
    this.dayKey,
    this.dayLabelAr,
    this.bookingsCount,
  });

  factory BookingsWeeklyChartItem.fromJson(Map<String, dynamic> json) {
    return BookingsWeeklyChartItem(
      date: _asString(json['date']),
      dayKey: _asString(json['dayKey']),
      dayLabelAr: _asString(json['dayLabelAr']),
      bookingsCount: _asInt(json['bookingsCount']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'dayKey': dayKey,
      'dayLabelAr': dayLabelAr,
      'bookingsCount': bookingsCount,
    };
  }
}

class InvoicesFourWeeksChartItem {
  int? weekNumber;
  String? label;
  String? from;
  String? to;
  num? invoiceAmount;
  num? invoiceAmountThousands;

  InvoicesFourWeeksChartItem({
    this.weekNumber,
    this.label,
    this.from,
    this.to,
    this.invoiceAmount,
    this.invoiceAmountThousands,
  });

  factory InvoicesFourWeeksChartItem.fromJson(Map<String, dynamic> json) {
    return InvoicesFourWeeksChartItem(
      weekNumber: _asInt(json['weekNumber']),
      label: _asString(json['label']),
      from: _asString(json['from']),
      to: _asString(json['to']),
      invoiceAmount: _asNum(json['invoiceAmount']),
      invoiceAmountThousands: _asNum(json['invoiceAmountThousands']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'weekNumber': weekNumber,
      'label': label,
      'from': from,
      'to': to,
      'invoiceAmount': invoiceAmount,
      'invoiceAmountThousands': invoiceAmountThousands,
    };
  }
}
