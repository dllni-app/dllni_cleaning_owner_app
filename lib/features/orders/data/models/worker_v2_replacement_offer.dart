class WorkerV2ReplacementOffer {
  const WorkerV2ReplacementOffer({
    required this.requestId,
    required this.bookingId,
    required this.visitSequence,
    required this.scheduledDate,
    required this.scheduledTime,
  });

  final int requestId;
  final int bookingId;
  final int visitSequence;
  final String scheduledDate;
  final String scheduledTime;

  static int _number(dynamic value) =>
      value is num ? value.toInt() : int.tryParse('$value') ?? 0;

  factory WorkerV2ReplacementOffer.fromJson(Map<dynamic, dynamic> json) {
    return WorkerV2ReplacementOffer(
      requestId: _number(json['requestId']),
      bookingId: _number(json['bookingId']),
      visitSequence: _number(json['visitSequence']),
      scheduledDate: (json['scheduledDate'] ?? '').toString(),
      scheduledTime: (json['scheduledTime'] ?? '').toString(),
    );
  }
}

List<WorkerV2ReplacementOffer> workerV2ReplacementOffersFromJson(dynamic json) {
  if (json is! Map || json['data'] is! Map) return const [];
  final offers = (json['data'] as Map)['offers'];
  if (offers is! List) return const [];

  return offers
      .whereType<Map>()
      .map(WorkerV2ReplacementOffer.fromJson)
      .where(
        (offer) =>
            offer.requestId > 0 &&
            offer.bookingId > 0 &&
            offer.visitSequence > 0,
      )
      .toList(growable: false);
}
