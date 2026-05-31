import '../../data/models/fetch_worker_profile_usecase_model.dart';
import 'package:flutter/material.dart';

const String profileLocationSectionLabelAr = 'موقع بدء المهمة';
const String profileWorkAreasSectionLabelAr = 'مناطق العمل';
const String profileWorkingTimeSectionLabelAr = 'أوقات العمل';

class WorkerProfileCompletenessResult {
  const WorkerProfileCompletenessResult({
    required this.hasMissionStartLocation,
    required this.hasWorkAreas,
    required this.hasWorkingTime,
  });

  final bool hasMissionStartLocation;
  final bool hasWorkAreas;
  final bool hasWorkingTime;

  bool get isComplete =>
      hasMissionStartLocation && hasWorkAreas && hasWorkingTime;

  List<String> get missingSectionsAr {
    final sections = <String>[];
    if (!hasMissionStartLocation) {
      sections.add(profileLocationSectionLabelAr);
    }
    if (!hasWorkAreas) {
      sections.add(profileWorkAreasSectionLabelAr);
    }
    if (!hasWorkingTime) {
      sections.add(profileWorkingTimeSectionLabelAr);
    }
    return sections;
  }
}

class WorkerProfileCompletenessPromptGate {
  static bool _alreadyPromptedInSession = false;

  static bool consumeShouldPrompt(WorkerProfileCompletenessResult result) {
    if (_alreadyPromptedInSession) return false;
    if (result.isComplete) return false;
    _alreadyPromptedInSession = true;
    return true;
  }

  static void resetForTests() {
    _alreadyPromptedInSession = false;
  }
}

WorkerProfileCompletenessResult evaluateWorkerProfileCompleteness(
  FetchWorkerProfileUsecaseModelData? data,
) {
  if (data == null) {
    return const WorkerProfileCompletenessResult(
      hasMissionStartLocation: false,
      hasWorkAreas: false,
      hasWorkingTime: false,
    );
  }

  final hasLocation = _hasMissionStartLocation(data);
  final hasWorkAreas = _hasWorkAreas(data);
  final hasWorkingTime = _hasWorkingTime(data);
  return WorkerProfileCompletenessResult(
    hasMissionStartLocation: hasLocation,
    hasWorkAreas: hasWorkAreas,
    hasWorkingTime: hasWorkingTime,
  );
}

bool _hasMissionStartLocation(FetchWorkerProfileUsecaseModelData data) {
  final address = (data.homeAddress ?? '').trim();
  return data.homeLatitude != null &&
      data.homeLongitude != null &&
      address.isNotEmpty;
}

bool _hasWorkAreas(FetchWorkerProfileUsecaseModelData data) {
  final zones = data.zones ?? const <Zone>[];
  return zones.any(
    (zone) => (zone.name ?? '').trim().isNotEmpty && (zone.isActive ?? true),
  );
}

bool _hasWorkingTime(FetchWorkerProfileUsecaseModelData data) {
  final defaultHours = data.defaultWorkingHours;
  if (defaultHours == null) return false;
  final days = <WorkingDay?>[
    defaultHours.sunday,
    defaultHours.monday,
    defaultHours.tuesday,
    defaultHours.wednesday,
    defaultHours.thursday,
    defaultHours.friday,
    defaultHours.saturday,
  ];
  return days.any(_isValidWorkingDay);
}

bool _isValidWorkingDay(WorkingDay? day) {
  if (day == null || !day.isWorking) return false;
  return day.hours.any((item) => _isValidPeriod(item.from, item.to));
}

bool _isValidPeriod(String? from, String? to) {
  final fromValue = (from ?? '').trim();
  final toValue = (to ?? '').trim();
  if (fromValue.isEmpty || toValue.isEmpty) return false;
  if (fromValue == toValue) return false;
  return _isTimeToken(fromValue) && _isTimeToken(toValue);
}

bool _isTimeToken(String value) {
  final parts = value.split(':');
  if (parts.length != 2) return false;
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) return false;
  return hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59;
}

bool isProfileSectionIncompleteByIndex(
  int sectionIndex,
  WorkerProfileCompletenessResult result,
) {
  return switch (sectionIndex) {
    1 => !result.hasWorkAreas,
    2 => !result.hasMissionStartLocation,
    3 => !result.hasWorkingTime,
    _ => false,
  };
}

class IncompleteSectionWarningIcon extends StatelessWidget {
  const IncompleteSectionWarningIcon({super.key, this.size = 19});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'بيانات غير مكتملة',
      child: Icon(
        Icons.warning_amber_rounded,
        size: size,
        color: const Color(0xffF59E0B),
      ),
    );
  }
}

class IncompleteProfileWarningDialog extends StatelessWidget {
  const IncompleteProfileWarningDialog({
    super.key,
    required this.missingSectionsAr,
    required this.onCompleteNow,
    required this.onLater,
  });

  final List<String> missingSectionsAr;
  final VoidCallback onCompleteNow;
  final VoidCallback onLater;

  @override
  Widget build(BuildContext context) {
    final lines = missingSectionsAr.map((item) => '• $item').join('\n');
    return AlertDialog(
      title: const Text('بيانات الحساب غير مكتملة'),
      content: Text(
        'يرجى استكمال البيانات التالية لتحسين ظهور الطلبات:\n$lines',
      ),
      actions: [
        TextButton(onPressed: onLater, child: const Text('لاحقًا')),
        ElevatedButton(
          onPressed: onCompleteNow,
          child: const Text('استكمال الآن'),
        ),
      ],
    );
  }
}
