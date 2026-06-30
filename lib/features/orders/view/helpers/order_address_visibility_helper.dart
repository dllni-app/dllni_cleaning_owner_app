import '../../data/models/cleaning_booking_status.dart';

String visibleOrderAddress({
  required String? address,
  required String? status,
}) {
  final trimmedAddress = address?.trim();
  if (trimmedAddress == null || trimmedAddress.isEmpty) return '-';

  final normalizedStatus = status?.trim().toLowerCase();
  final isPending =
      normalizedStatus == CleaningBookingStatus.pending ||
      (normalizedStatus?.contains('pending') ?? false);
  if (!isPending) return trimmedAddress;

  final parts = trimmedAddress
      .split(RegExp(r'[,،]|\s+[-–—]\s+'))
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .toList(growable: false);

  if (parts.isEmpty) return trimmedAddress;
  return parts.first;
}
