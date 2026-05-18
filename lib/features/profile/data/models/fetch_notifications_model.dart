class FetchNotificationsModelDataItem {
  const FetchNotificationsModelDataItem({
    this.id,
    this.title,
    this.body,
    this.createdAt,
    required this.type,
    this.isRead,
    this.category,
    this.showTrailingAccent = false,
    this.module,
    this.icon,
    this.priority,
    this.canonicalType,
    this.data,
  });

  final String? id;
  final String? title;
  final String? body;
  final String? createdAt;
  final String type;
  final bool? isRead;
  final String? category;
  final bool showTrailingAccent;
  final String? module;
  final String? icon;
  final String? priority;
  final String? canonicalType;
  final Map<String, dynamic>? data;

  FetchNotificationsModelDataItem copyWith({
    String? id,
    String? title,
    String? body,
    String? createdAt,
    String? type,
    bool? isRead,
    String? category,
    bool? showTrailingAccent,
    String? module,
    String? icon,
    String? priority,
    String? canonicalType,
    Map<String, dynamic>? data,
  }) {
    return FetchNotificationsModelDataItem(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      category: category ?? this.category,
      showTrailingAccent: showTrailingAccent ?? this.showTrailingAccent,
      module: module ?? this.module,
      icon: icon ?? this.icon,
      priority: priority ?? this.priority,
      canonicalType: canonicalType ?? this.canonicalType,
      data: data ?? this.data,
    );
  }
}
