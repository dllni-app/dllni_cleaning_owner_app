import '../../data/models/cleaning_team_models.dart';
import '../../data/models/fetch_orders_usecase_model.dart';
import 'cleaning_enum_translations.dart';

class PropertyAttributeLabelsHelper {
  static int roomTypeCount(
    PropertyDetailsData? property, {
    required String roomType,
    int? fallback,
    List<CleaningRoomAssignmentModel>? roomAssignments,
  }) {
    final breakdown = property?.roomSizeBreakdown;
    if (breakdown != null) {
      final counts = breakdown.countsForRoomType(roomType);
      if (counts != null && counts.total > 0) return counts.total;
    }

    if (roomAssignments != null && roomAssignments.isNotEmpty) {
      final normalizedType = roomType.trim().toLowerCase();
      final matched = roomAssignments
          .where(
            (room) =>
                (room.roomType ?? '').trim().toLowerCase() == normalizedType,
          )
          .length;
      if (matched > 0) return matched;
    }

    return fallback ?? 0;
  }

  static int roomTypeCountForOrder(
    FetchOrdersUsecaseModelDataItem order, {
    required String roomType,
  }) {
    return roomTypeCount(
      order.propertyDetails,
      roomType: roomType,
      fallback: _legacyCountForOrder(order, roomType),
      roomAssignments: order.roomAssignments,
    );
  }

  static int? _legacyCountForOrder(
    FetchOrdersUsecaseModelDataItem order,
    String roomType,
  ) {
    final property = order.propertyDetails;
    switch (roomType) {
      case 'living_room':
      case 'bedroom':
      case 'hall':
        return null;
      case 'bathroom':
        return property?.bathrooms;
      case 'kitchen':
        final kitchens = property?.kitchens ?? order.numberOfKitchens;
        if (kitchens != null && kitchens > 0) return kitchens;
        if (property?.kitchenIncluded == true || property?.kitchen != null) {
          return 1;
        }
        return null;
      case 'balcony':
        return property?.balconies ?? order.numberOfBalconies;
      default:
        return null;
    }
  }

  static int kitchenCountForOrder(FetchOrdersUsecaseModelDataItem order) {
    return roomTypeCountForOrder(order, roomType: 'kitchen');
  }

  static int kitchenCount(PropertyDetailsData? property) {
    final fromBreakdown = roomTypeCount(property, roomType: 'kitchen');
    if (fromBreakdown > 0) return fromBreakdown;

    final kitchens = property?.kitchens;
    if (kitchens != null && kitchens > 0) return kitchens;
    if (property?.kitchenIncluded == true || property?.kitchen != null) {
      return 1;
    }
    return 0;
  }

  static String formatCount(int count) => count > 0 ? count.toString() : '-';

  static const List<String> _roomTypeOrder = <String>[
    'balcony',
    'bedroom',
    'kitchen',
    'bathroom',
    'corridor',
    'living_room',
  ];

  static const List<String> _sizeOrder = <String>['large', 'medium', 'small'];

  static List<String> build(PropertyDetailsData? property) {
    if (property == null) return const <String>[];

    final breakdown = property.roomSizeBreakdown;
    if (breakdown != null && _hasAnyBreakdownCounts(breakdown)) {
      return _fromBreakdown(breakdown);
    }

    return _fromLegacyFields(property);
  }

  static List<String> buildForOrder(FetchOrdersUsecaseModelDataItem order) {
    final property = order.propertyDetails;
    if (property == null) return const <String>[];

    final breakdown = property.roomSizeBreakdown;
    if (breakdown != null && _hasAnyBreakdownCounts(breakdown)) {
      return _fromBreakdown(breakdown);
    }

    return _fromLegacyFields(property);
  }

  static bool _hasAnyBreakdownCounts(PropertyRoomSizeBreakdown breakdown) {
    for (final roomType in _roomTypeOrder) {
      final counts = breakdown.countsForRoomType(roomType);
      if (counts != null && counts.total > 0) return true;
    }
    return false;
  }

  static List<String> _fromBreakdown(PropertyRoomSizeBreakdown breakdown) {
    final labels = <String>[];

    for (final roomType in _roomTypeOrder) {
      final counts = breakdown.countsForRoomType(roomType);
      if (counts == null) continue;

      for (final size in _sizeOrder) {
        final count = counts.countFor(size);
        if (count <= 0) continue;
        labels.add(_breakdownChip(roomType: roomType, size: size, count: count));
      }
    }

    return labels;
  }

  static String _breakdownChip({
    required String roomType,
    required String size,
    required int count,
  }) {
    final typeLabel = CleaningEnumTranslations.roomType(roomType);
    final sizeLabel = CleaningEnumTranslations.roomSize(size);
    return '$count $typeLabel $sizeLabel';
  }

  static List<String> _fromLegacyFields(PropertyDetailsData property) {
    final labels = <String>[];

    final bathrooms = property.bathrooms;
    if (bathrooms != null && bathrooms > 0) {
      labels.add('$bathrooms حمام');
    }

    final bedrooms = property.bedRooms;
    if (bedrooms != null && bedrooms > 0) {
      labels.add('$bedrooms غرف نوم');
    }

    final kitchens = property.kitchens;
    if (kitchens != null && kitchens > 0) {
      labels.add('$kitchens مطبخ');
    } else if (property.kitchenIncluded == true || property.kitchen != null) {
      labels.add('مطبخ');
    }

    final balconies = property.balconies;
    if (balconies != null && balconies > 0) {
      labels.add('$balconies شرفة');
    }

    final livingRoomLabel = _livingRoomLabel(property);
    if (livingRoomLabel != null) labels.add(livingRoomLabel);

    return labels;
  }

  static String? _livingRoomLabel(PropertyDetailsData property) {
    final sizeLabel = CleaningEnumTranslations.preferArabicLabel(
      property.livingRoomSizeLabel,
      property.livingRoomSize,
      CleaningEnumTranslations.livingRoomSize,
      fallback: '',
    );
    if (sizeLabel.isEmpty || sizeLabel == 'غير محدد' || sizeLabel == 'لا يوجد') {
      return null;
    }
    return 'غرفة معيشة $sizeLabel';
  }
}
