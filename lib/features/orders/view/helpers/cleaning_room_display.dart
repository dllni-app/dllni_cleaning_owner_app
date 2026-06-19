import '../../data/models/cleaning_team_models.dart';
import 'cleaning_enum_translations.dart';

int? extractRoomNumber(String? roomKey) {
  final match = RegExp(r'(\d+)').firstMatch(roomKey ?? '');
  if (match == null) return null;
  return int.tryParse(match.group(1)!);
}

bool _looksLikeRawEnglishRoomLabel(String value) {
  final normalized = value.toLowerCase();
  return RegExp(r'\b(small|medium|large|bedroom|living_room|bathroom)\b')
      .hasMatch(normalized);
}

String assignedRoomLabel(CleaningRoomAssignmentModel room, int index) {
  final backendTypeLabel = room.roomTypeLabel?.trim();
  final backendSizeLabel = room.roomSizeLabel?.trim();
  final displayLabel = room.displayLabel?.trim();

  final type = backendTypeLabel != null && backendTypeLabel.isNotEmpty
      ? backendTypeLabel
      : CleaningEnumTranslations.roomType(room.roomType);

  final size = backendSizeLabel != null && backendSizeLabel.isNotEmpty
      ? backendSizeLabel
      : CleaningEnumTranslations.roomSize(room.roomSize);

  if (displayLabel != null &&
      displayLabel.isNotEmpty &&
      !_looksLikeRawEnglishRoomLabel(displayLabel)) {
    return displayLabel;
  }

  final ordinal = extractRoomNumber(room.roomKey) ?? index + 1;
  if (size.isEmpty || size == 'غير محدد') {
    return '$type $ordinal';
  }
  return '$type $ordinal - $size';
}
