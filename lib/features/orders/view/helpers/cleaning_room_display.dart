import '../../data/models/cleaning_team_models.dart';
import '../../data/models/fetch_orders_usecase_model.dart';
import 'cleaning_enum_translations.dart';

List<CleaningRoomAssignmentModel> assignedRoomsForCurrentWorker(
  FetchOrdersUsecaseModelDataItem order,
) {
  final rooms = order.roomAssignments ?? const <CleaningRoomAssignmentModel>[];
  if (rooms.isEmpty) return const <CleaningRoomAssignmentModel>[];

  final explicitlyAssigned = rooms
      .where((room) => room.isAssignedToMe)
      .toList(growable: false);
  if (explicitlyAssigned.isNotEmpty) return explicitlyAssigned;

  final roomIds = order.myAssignment?.roomIds ?? const <int>[];
  if (roomIds.isNotEmpty) {
    return rooms
        .where((room) => room.id != null && roomIds.contains(room.id))
        .toList(growable: false);
  }

  final workerId = order.myAssignment?.workerId;
  if (workerId == null) return const <CleaningRoomAssignmentModel>[];

  return rooms
      .where((room) => room.assignedWorkerId == workerId)
      .toList(growable: false);
}

int? extractRoomNumber(String? roomKey) {
  final match = RegExp(r'(\d+)').firstMatch(roomKey ?? '');
  if (match == null) return null;
  return int.tryParse(match.group(1)!);
}

String assignedRoomLabel(CleaningRoomAssignmentModel room, int index) {
  final displayLabel = room.displayLabel?.trim();

  if (displayLabel != null &&
      displayLabel.isNotEmpty &&
      CleaningEnumTranslations.isArabicLabel(displayLabel)) {
    return displayLabel;
  }

  final type = CleaningEnumTranslations.preferArabicLabel(
    room.roomTypeLabel,
    room.roomType,
    CleaningEnumTranslations.roomType,
    fallback: 'غرفة',
  );
  final size = CleaningEnumTranslations.preferArabicLabel(
    room.roomSizeLabel,
    room.roomSize,
    CleaningEnumTranslations.roomSize,
    fallback: '',
  );

  final ordinal = extractRoomNumber(room.roomKey) ??
      extractRoomNumber(displayLabel) ??
      index + 1;

  if (size.isEmpty || size == 'غير محدد') return '$type $ordinal';

  return '$type $ordinal - $size';
}
