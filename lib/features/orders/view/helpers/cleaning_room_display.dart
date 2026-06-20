import '../../data/models/cleaning_team_models.dart';
import 'cleaning_enum_translations.dart';

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
