int? _asInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) {
    return int.tryParse(value) ?? double.tryParse(value)?.toInt();
  }
  return null;
}

String _asString(dynamic value, {String fallback = ''}) {
  if (value == null) return fallback;
  if (value is String) return value;
  if (value is num || value is bool) return value.toString();
  return fallback;
}

bool _asBool(dynamic value, {bool fallback = false}) {
  if (value == null) return fallback;
  if (value is bool) return value;
  if (value is num) {
    if (value == 1) return true;
    if (value == 0) return false;
  }
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true' || normalized == '1') return true;
    if (normalized == 'false' || normalized == '0') return false;
  }
  return fallback;
}

List<String> _asStringList(dynamic value) {
  if (value is! List) return const [];
  return value
      .map((item) => item?.toString() ?? '')
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}

class CleaningNeighborhoodModel {
  final int id;
  final String cityName;
  final String nameAr;
  final String? nameEn;
  final String displayName;
  final List<String> aliases;
  final bool isActive;

  const CleaningNeighborhoodModel({
    required this.id,
    required this.cityName,
    required this.nameAr,
    this.nameEn,
    required this.displayName,
    this.aliases = const [],
    this.isActive = true,
  });

  factory CleaningNeighborhoodModel.fromJson(Map<String, dynamic> json) {
    return CleaningNeighborhoodModel(
      id: _asInt(json['id']) ?? 0,
      cityName: _asString(json['cityName'] ?? json['city_name']),
      nameAr: _asString(json['nameAr'] ?? json['name_ar']),
      nameEn: _asString(json['nameEn'] ?? json['name_en']).isEmpty
          ? null
          : _asString(json['nameEn'] ?? json['name_en']),
      displayName: _asString(
        json['displayName'] ?? json['display_name'] ?? json['nameAr'] ?? json['name_ar'],
      ),
      aliases: _asStringList(json['aliases']),
      isActive: _asBool(json['isActive'] ?? json['is_active'], fallback: true),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'cityName': cityName,
        'nameAr': nameAr,
        'nameEn': nameEn,
        'displayName': displayName,
        'aliases': aliases,
        'isActive': isActive,
      };
}
