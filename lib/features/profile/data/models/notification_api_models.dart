int? _asInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('$value');
}

String? _asString(dynamic value) {
  if (value == null) return null;
  return '$value';
}

String? _firstNonEmptyString(Map<String, dynamic> json, List<String> keys) {
  for (final k in keys) {
    final s = _asString(json[k]);
    if (s != null && s.trim().isNotEmpty) return s;
  }
  return null;
}

Map<String, dynamic>? _asStringKeyMap(dynamic value) {
  if (value is! Map) return null;
  final out = <String, dynamic>{};
  for (final e in value.entries) {
    out['${e.key}'] = e.value;
  }
  return out;
}

FetchNotificationsPageModel fetchNotificationsPageModelFromJson(dynamic json) =>
    FetchNotificationsPageModel.fromJson(Map<String, dynamic>.from(json as Map));

ActionResultModel actionResultModelFromJson(dynamic json) {
  if (json is Map) {
    return ActionResultModel.fromJson(Map<String, dynamic>.from(json));
  }
  return const ActionResultModel();
}

class NotificationResourceModel {
  final String? id;
  final String? type;
  final String? title;
  final String? body;
  final String? readAt;
  final String? createdAt;
  final String? module;
  final String? icon;
  final String? canonicalType;
  final String? category;
  final String? priority;
  final Map<String, dynamic>? data;

  const NotificationResourceModel({
    this.id,
    this.type,
    this.title,
    this.body,
    this.readAt,
    this.createdAt,
    this.module,
    this.icon,
    this.canonicalType,
    this.category,
    this.priority,
    this.data,
  });

  factory NotificationResourceModel.fromJson(Map<String, dynamic> json) {
    return NotificationResourceModel(
      id: _asString(json['id']),
      type: _asString(json['type']),
      title: _asString(json['title']),
      body: _asString(json['body']),
      readAt: _firstNonEmptyString(json, const ['readAt', 'read_at']),
      createdAt: _firstNonEmptyString(json, const ['createdAt', 'created_at']),
      module: _asString(json['module']),
      icon: _asString(json['icon']),
      canonicalType: _firstNonEmptyString(json, const ['canonicalType', 'canonical_type']),
      category: _asString(json['category']),
      priority: _asString(json['priority']),
      data: _asStringKeyMap(json['data']),
    );
  }
}

class PaginationMetaModel {
  final int? currentPage;
  final int? perPage;
  final int? total;
  final int? countUnread;

  const PaginationMetaModel({
    this.currentPage,
    this.perPage,
    this.total,
    this.countUnread,
  });

  factory PaginationMetaModel.fromJson(Map<String, dynamic> json) {
    return PaginationMetaModel(
      currentPage: _asInt(json['current_page']),
      perPage: _asInt(json['per_page']),
      total: _asInt(json['total']),
      countUnread: _asInt(json['countUnread']),
    );
  }
}

class FetchNotificationsPageModel {
  final List<NotificationResourceModel>? data;
  final PaginationMetaModel? meta;
  final int? countUnread;

  const FetchNotificationsPageModel({this.data, this.meta, this.countUnread});

  int? get resolvedCountUnread => countUnread ?? meta?.countUnread;

  factory FetchNotificationsPageModel.fromJson(Map<String, dynamic> json) {
    final meta = json['meta'] is Map
        ? PaginationMetaModel.fromJson(
            Map<String, dynamic>.from(json['meta'] as Map),
          )
        : null;

    return FetchNotificationsPageModel(
      data: json['data'] is List
          ? (json['data'] as List)
                .whereType<Map>()
                .map(
                  (e) => NotificationResourceModel.fromJson(
                    Map<String, dynamic>.from(e),
                  ),
                )
                .toList()
          : null,
      meta: meta,
      countUnread: _asInt(json['countUnread']) ?? meta?.countUnread,
    );
  }
}

class ActionResultModel {
  final String? message;

  const ActionResultModel({this.message});

  factory ActionResultModel.fromJson(Map<String, dynamic> json) {
    return ActionResultModel(message: _asString(json['message']));
  }
}
