import '../../data/models/arrive_model.dart';
import '../../data/models/cleaning_team_models.dart';
import '../../data/models/fetch_orders_usecase_model.dart';
import 'cleaning_enum_translations.dart';
import 'cleaning_room_display.dart';
import 'event_assistance_order_helper.dart';

class MissionTaskItem {
  const MissionTaskItem({
    required this.label,
    this.detail,
    this.isReadOnlyInfo = false,
  });

  final String label;
  final String? detail;
  final bool isReadOnlyInfo;
}

class OrderMissionTaskMapper {
  const OrderMissionTaskMapper._();

  static const List<String> _roomTypeOrder = <String>[
    'balcony',
    'bedroom',
    'kitchen',
    'bathroom',
    'corridor',
    'living_room',
    'hall',
    'shed',
  ];

  static const List<String> _sizeOrder = <String>['large', 'medium', 'small'];

  static List<MissionTaskItem> build({
    required FetchOrdersUsecaseModelDataItem order,
  }) {
    if (EventAssistanceOrderHelper.isEventAssistance(order.propertyType)) {
      return _eventAssistanceInfoTasks(order);
    }

    final rooms = _resolveRooms(order);
    if (rooms.isNotEmpty) {
      return _tasksFromRoomAssignments(rooms);
    }

    final requirements =
        order.roomRequirements ?? const <Map<String, dynamic>>[];
    if (requirements.isNotEmpty) {
      return requirements
          .map((room) {
            final count = room['count'] is num
                ? (room['count'] as num).toInt()
                : 1;
            final roomType = (room['roomType'] ?? '').toString();
            final roomSize = (room['roomSize'] ?? '').toString();
            final type = CleaningEnumTranslations.preferArabicLabel(
              room['roomTypeLabel']?.toString(),
              roomType,
              CleaningEnumTranslations.roomType,
              fallback: 'غرفة',
            );
            final size = CleaningEnumTranslations.preferArabicLabel(
              room['roomSizeLabel']?.toString(),
              roomSize,
              CleaningEnumTranslations.roomSize,
              fallback: '',
            );
            return MissionTaskItem(
              label: '$type × $count',
              detail: [
                if (size.isNotEmpty && size != 'غير محدد') size,
              ].join(' • '),
            );
          })
          .toList(growable: false);
    }

    final breakdown = order.propertyDetails?.roomSizeBreakdown;
    if (breakdown != null && _hasAnyBreakdownCounts(breakdown)) {
      return _tasksFromBreakdown(
        breakdown,
        propertyDetails: order.propertyDetails,
      );
    }

    return _legacyPropertyTasks(order);
  }

  /// Historic bookings sometimes have room counts but neither V2
  /// requirements nor a size breakdown. Display only recorded counts;
  /// do not invent room types or imply worker-specific room allocation.
  static List<MissionTaskItem> _legacyPropertyTasks(
    FetchOrdersUsecaseModelDataItem order,
  ) {
    final details = order.propertyDetails;
    final tasks = <MissionTaskItem>[];
    void add(String name, int? count) {
      if (count != null && count > 0) {
        tasks.add(MissionTaskItem(label: '$name × $count'));
      }
    }

    add('غرفة نوم', details?.bedRooms);
    if ((details?.bedRooms ?? 0) == 0) {
      add('غرفة', details?.rooms ?? order.numberOfRooms);
    }
    add('حمام', details?.bathrooms);
    add(
      'مطبخ',
      details?.kitchens ??
          order.numberOfKitchens ??
          (details?.kitchenIncluded == true ? 1 : null),
    );
    add('شرفة', details?.balconies ?? order.numberOfBalconies);
    add('سقيفة', details?.sheds ?? order.numberOfSheds);
    final livingRoomSize = details?.livingRoomSize?.trim();
    if (livingRoomSize != null &&
        livingRoomSize.isNotEmpty &&
        livingRoomSize != 'none') {
      tasks.add(
        MissionTaskItem(
          label: 'غرفة معيشة',
          detail: CleaningEnumTranslations.roomSize(livingRoomSize),
        ),
      );
    }
    return tasks;
  }

  static List<MissionTaskItem> buildServicesInfo({
    required List<Service> services,
    required List<Addon> addons,
  }) {
    final items = <MissionTaskItem>[];

    for (final service in services) {
      final name = service.name?.trim();
      if (name == null || name.isEmpty) continue;
      items.add(
        MissionTaskItem(
          label: name,
          detail: (service.quantity ?? 0) > 1 ? 'x${service.quantity}' : null,
        ),
      );
    }

    for (final addon in addons) {
      final name = addon.name?.trim();
      if (name == null || name.isEmpty) continue;
      items.add(
        MissionTaskItem(
          label: name,
          detail: (addon.quantity ?? 0) > 1 ? 'x${addon.quantity}' : null,
        ),
      );
    }

    return items;
  }

  /// Builds the completed-service snapshot sent to the backend when the worker
  /// requests customer completion confirmation. Services are informational in
  /// the worker UI, so every displayed service/add-on is included.
  static List<Map<String, Object?>> buildCompletionServiceSnapshots({
    required List<Service> services,
    required List<Addon> addons,
  }) {
    final items = buildServicesInfo(services: services, addons: addons);

    return items
        .asMap()
        .entries
        .map((entry) {
          final item = entry.value;
          final label = item.label.trim();
          final detail = item.detail?.trim();

          return <String, Object?>{
            'name': label,
            'label': detail == null || detail.isEmpty
                ? label
                : '$label: $detail',
            if (detail != null && detail.isNotEmpty) 'detail': detail,
            'sort': entry.key,
          };
        })
        .toList(growable: false);
  }

  static String keyFor(MissionTaskItem task, int index) =>
      '${task.label}-$index';

  static List<MissionTaskItem> _eventAssistanceInfoTasks(
    FetchOrdersUsecaseModelDataItem order,
  ) {
    final customService = order.propertyDetails?.customService?.trim();
    final specialRequirement = order.propertyDetails?.specialRequirement
        ?.trim();

    return <MissionTaskItem>[
      MissionTaskItem(
        label: 'طبيعة المساعدة المطلوبة',
        detail: customService != null && customService.isNotEmpty
            ? customService
            : 'غير محددة',
        isReadOnlyInfo: true,
      ),
      MissionTaskItem(
        label: 'متطلبات خاصة',
        detail: specialRequirement != null && specialRequirement.isNotEmpty
            ? specialRequirement
            : 'لا يوجد',
        isReadOnlyInfo: true,
      ),
    ];
  }

  static List<CleaningRoomAssignmentModel> _resolveRooms(
    FetchOrdersUsecaseModelDataItem order,
  ) {
    return order.roomAssignments ?? const <CleaningRoomAssignmentModel>[];
  }

  static List<MissionTaskItem> _tasksFromRoomAssignments(
    List<CleaningRoomAssignmentModel> rooms,
  ) {
    return rooms
        .asMap()
        .entries
        .map((entry) => _taskFromRoomAssignment(entry.value, entry.key))
        .toList(growable: false);
  }

  static MissionTaskItem _taskFromRoomAssignment(
    CleaningRoomAssignmentModel room,
    int index,
  ) {
    final displayLabel = room.displayLabel?.trim();

    if (displayLabel != null &&
        displayLabel.isNotEmpty &&
        CleaningEnumTranslations.isArabicLabel(displayLabel)) {
      return MissionTaskItem(label: displayLabel);
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

    final ordinal =
        extractRoomNumber(room.roomKey) ??
        extractRoomNumber(displayLabel) ??
        index + 1;

    final hasSize = size.isNotEmpty && size != 'غير محدد';

    return MissionTaskItem(
      label: '$type $ordinal',
      detail: hasSize ? size : null,
    );
  }

  static List<MissionTaskItem> _tasksFromBreakdown(
    PropertyRoomSizeBreakdown breakdown, {
    PropertyDetailsData? propertyDetails,
  }) {
    final items = <MissionTaskItem>[];

    for (final roomType in _roomTypeOrder) {
      final counts = breakdown.countsForRoomType(roomType);
      if (counts == null) continue;

      final typeLabel = CleaningEnumTranslations.roomType(roomType);
      var ordinal = 1;

      for (final size in _sizeOrder) {
        final count = counts.countFor(size);
        if (count <= 0) continue;

        final sizeLabel = CleaningEnumTranslations.roomSize(size);
        for (var i = 0; i < count; i++) {
          items.add(
            MissionTaskItem(label: '$typeLabel $ordinal', detail: sizeLabel),
          );
          ordinal++;
        }
      }
    }

    if (breakdown.livingRoom == null || breakdown.livingRoom!.total <= 0) {
      final livingRoomTask = _livingRoomTaskFromLegacy(propertyDetails);
      if (livingRoomTask != null) items.add(livingRoomTask);
    }

    return items;
  }

  static MissionTaskItem? _livingRoomTaskFromLegacy(
    PropertyDetailsData? propertyDetails,
  ) {
    if (propertyDetails == null) return null;

    final sizeLabel = CleaningEnumTranslations.preferArabicLabel(
      propertyDetails.livingRoomSizeLabel,
      propertyDetails.livingRoomSize,
      CleaningEnumTranslations.livingRoomSize,
      fallback: '',
    );
    if (sizeLabel.isEmpty ||
        sizeLabel == 'غير محدد' ||
        sizeLabel == 'لا يوجد') {
      return null;
    }

    return MissionTaskItem(
      label: '${CleaningEnumTranslations.roomType('living_room')} 1',
      detail: sizeLabel,
    );
  }

  static bool _hasAnyBreakdownCounts(PropertyRoomSizeBreakdown breakdown) {
    for (final roomType in _roomTypeOrder) {
      final counts = breakdown.countsForRoomType(roomType);
      if (counts != null && counts.total > 0) return true;
    }
    return false;
  }
}
