import 'dart:convert';

String? _asString(dynamic value) {
  if (value == null) return null;
  if (value is String) return value;
  if (value is num || value is bool) return value.toString();
  return null;
}

int? _asInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) {
    return int.tryParse(value) ?? double.tryParse(value)?.toInt();
  }
  return null;
}

double? _asDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

num? _asNum(dynamic value) {
  if (value == null) return null;
  if (value is num) return value;
  if (value is String) return num.tryParse(value);
  return null;
}

bool? _asBool(dynamic value) {
  if (value == null) return null;
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
  return null;
}

FetchWorkerProfileUsecaseModel fetchWorkerProfileUsecaseModelFromJson(str) => FetchWorkerProfileUsecaseModel.fromJson(str);

String fetchWorkerProfileUsecaseModelToJson(FetchWorkerProfileUsecaseModel data) => json.encode(data.toJson());

class FetchWorkerProfileUsecaseModel {
  FetchWorkerProfileUsecaseModelData? data;

  FetchWorkerProfileUsecaseModel({this.data});

  factory FetchWorkerProfileUsecaseModel.fromJson(Map<String, dynamic> json) {
    return FetchWorkerProfileUsecaseModel(
      data: json['data'] is Map ? FetchWorkerProfileUsecaseModelData.fromJson(Map<String, dynamic>.from(json['data'])) : null,
    );
  }

  Map<String, dynamic> toJson() => {'data': data?.toJson()};
}

class FetchWorkerProfileUsecaseModelData {
  int? id;
  int? userId;
  String? firstName;
  Avatar? avatar;
  String? bio;
  double? averageRating;
  int? totalCompletedJobs;
  int? trustScore;
  double? acceptanceRate;
  double? cancellationRate;
  int? openDisputesCount;
  bool? isActive;
  bool? isSuspended;
  String? suspendedUntil;
  String? homeAddress;
  double? homeLatitude;
  double? homeLongitude;
  FetchWorkerProfileUsecaseModelDataDefaultWorkingHours? defaultWorkingHours;
  FetchWorkerProfileUsecaseModelDataUser? user;
  List<Zone>? zones;
  List<Availability>? availability;
  String? preferredWorkType;
  String? createdAt;
  String? updatedAt;

  FetchWorkerProfileUsecaseModelData({
    this.id,
    this.userId,
    this.firstName,
    this.avatar,
    this.bio,
    this.averageRating,
    this.totalCompletedJobs,
    this.trustScore,
    this.acceptanceRate,
    this.cancellationRate,
    this.openDisputesCount,
    this.isActive,
    this.isSuspended,
    this.suspendedUntil,
    this.homeAddress,
    this.homeLatitude,
    this.homeLongitude,
    this.defaultWorkingHours,
    this.user,
    this.zones,
    this.availability,
    this.preferredWorkType,
    this.createdAt,
    this.updatedAt,
  });

  factory FetchWorkerProfileUsecaseModelData.fromJson(Map<String, dynamic> json) {
    return FetchWorkerProfileUsecaseModelData(
      id: _asInt(json['id']),
      userId: _asInt(json['userId']),
      firstName: _asString(json['firstName']),
      avatar: json['avatar'] is Map ? Avatar.fromJson(Map<String, dynamic>.from(json['avatar'])) : null,
      bio: _asString(json['bio']),
      averageRating: _asDouble(json['averageRating']),
      totalCompletedJobs: _asInt(json['totalCompletedJobs']),
      trustScore: _asInt(json['trustScore']),
      acceptanceRate: _asDouble(json['acceptanceRate']),
      cancellationRate: _asDouble(json['cancellationRate']),
      openDisputesCount: _asInt(json['openDisputesCount']),
      isActive: _asBool(json['isActive']),
      isSuspended: _asBool(json['isSuspended']),
      suspendedUntil: _asString(json['suspendedUntil']),
      homeAddress: _asString(json['homeAddress']),
      homeLatitude: _asDouble(json['homeLatitude']),
      homeLongitude: _asDouble(json['homeLongitude']),
      defaultWorkingHours: json['defaultWorkingHours'] is Map
          ? FetchWorkerProfileUsecaseModelDataDefaultWorkingHours.fromJson(Map<String, dynamic>.from(json['defaultWorkingHours']))
          : null,
      user: json['user'] is Map ? FetchWorkerProfileUsecaseModelDataUser.fromJson(Map<String, dynamic>.from(json['user'])) : null,
      zones: json['zones'] is List ? (json['zones'] as List).whereType<Map>().map((e) => Zone.fromJson(Map<String, dynamic>.from(e))).toList() : null,
      availability: json['availability'] is List
          ? (json['availability'] as List).whereType<Map>().map((e) => Availability.fromJson(Map<String, dynamic>.from(e))).toList()
          : null,
      preferredWorkType: _asString(
        json['preferred_work_type'] ?? json['preferredWorkType'],
      ),
      createdAt: _asString(json['createdAt']),
      updatedAt: _asString(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'firstName': firstName,
    'avatar': avatar?.toJson(),
    'bio': bio,
    'averageRating': averageRating,
    'totalCompletedJobs': totalCompletedJobs,
    'trustScore': trustScore,
    'acceptanceRate': acceptanceRate,
    'cancellationRate': cancellationRate,
    'openDisputesCount': openDisputesCount,
    'isActive': isActive,
    'isSuspended': isSuspended,
    'suspendedUntil': suspendedUntil,
    'homeAddress': homeAddress,
    'homeLatitude': homeLatitude,
    'homeLongitude': homeLongitude,
    'defaultWorkingHours': defaultWorkingHours?.toJson(),
    'user': user?.toJson(),
    'zones': zones?.map((e) => e.toJson()).toList(),
    'availability': availability?.map((e) => e.toJson()).toList(),
    'preferred_work_type': preferredWorkType,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };
}

class Avatar {
  int? id;
  String? url;

  Avatar({this.id, this.url});

  factory Avatar.fromJson(Map<String, dynamic> json) => Avatar(
    id: _asInt(json['id']),
    url: _asString(json['url']),
  );

  Map<String, dynamic> toJson() => {'id': id, 'url': url};
}

class WorkingDayItem {
  String? from;
  String? to;

  WorkingDayItem({this.from, this.to});
}

class WorkingDay {
  final bool isWorking;
  final List<WorkingDayItem> hours;

  WorkingDay({required this.isWorking, required this.hours});

  factory WorkingDay.fromJson(dynamic value) {
    if (value is Map) {
      final available = _asBool(value['available']) ?? false;
      final data = value['data'];

      final hours = <WorkingDayItem>[];

      if (data is List) {
        for (final item in data.whereType<Map>()) {
          item.forEach((key, val) {
            hours.add(WorkingDayItem(from: key.toString(), to: val.toString()));
          });
        }
      }

      return WorkingDay(isWorking: available, hours: hours);
    }

    return WorkingDay(isWorking: false, hours: []);
  }

  dynamic toJson() {
    return {
      "available": isWorking,
      "data": hours.map((e) => {e.from: e.to}).toList(),
    };
  }
}

class FetchWorkerProfileUsecaseModelDataDefaultWorkingHours {
  WorkingDay? sunday;
  WorkingDay? monday;
  WorkingDay? tuesday;
  WorkingDay? wednesday;
  WorkingDay? thursday;
  WorkingDay? friday;
  WorkingDay? saturday;

  FetchWorkerProfileUsecaseModelDataDefaultWorkingHours({
    this.sunday,
    this.monday,
    this.tuesday,
    this.wednesday,
    this.thursday,
    this.friday,
    this.saturday,
  });

  factory FetchWorkerProfileUsecaseModelDataDefaultWorkingHours.fromJson(Map<String, dynamic> json) {
    return FetchWorkerProfileUsecaseModelDataDefaultWorkingHours(
      sunday: WorkingDay.fromJson(json['sunday']),
      monday: WorkingDay.fromJson(json['monday']),
      tuesday: WorkingDay.fromJson(json['tuesday']),
      wednesday: WorkingDay.fromJson(json['wednesday']),
      thursday: WorkingDay.fromJson(json['thursday']),
      friday: WorkingDay.fromJson(json['friday']),
      saturday: WorkingDay.fromJson(json['saturday']),
    );
  }

  Map<String, dynamic> toJson() => {
    'sunday': sunday?.toJson(),
    'monday': monday?.toJson(),
    'tuesday': tuesday?.toJson(),
    'wednesday': wednesday?.toJson(),
    'thursday': thursday?.toJson(),
    'friday': friday?.toJson(),
    'saturday': saturday?.toJson(),
  };
}

class FetchWorkerProfileUsecaseModelDataUser {
  int? id;
  String? name;
  String? email;
  String? phone;

  FetchWorkerProfileUsecaseModelDataUser({this.id, this.name, this.email, this.phone});

  factory FetchWorkerProfileUsecaseModelDataUser.fromJson(Map<String, dynamic> json) => FetchWorkerProfileUsecaseModelDataUser(
    id: _asInt(json['id']),
    name: _asString(json['name']),
    email: _asString(json['email']),
    phone: _asString(json['phone']),
  );

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'email': email, 'phone': phone};
}

class Zone {
  int? id;
  int? workerId;
  int? neighborhoodId;
  String? name;
  List<ZonePoint>? polygon;
  bool? isActive;
  String? createdAt;
  String? updatedAt;

  Zone({
    this.id,
    this.workerId,
    this.neighborhoodId,
    this.name,
    this.polygon,
    this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory Zone.fromJson(Map<String, dynamic> json) => Zone(
    id: _asInt(json['id']),
    workerId: _asInt(json['workerId'] ?? json['worker_id']),
    neighborhoodId: _asInt(json['neighborhoodId'] ?? json['neighborhood_id']),
    name: _asString(json['name']),
    polygon: json['polygon'] is List
        ? (json['polygon'] as List).whereType<Map>().map((e) => ZonePoint.fromJson(Map<String, dynamic>.from(e))).toList()
        : null,
    isActive: _asBool(json['isActive'] ?? json['is_active']),
    createdAt: _asString(json['createdAt'] ?? json['created_at']),
    updatedAt: _asString(json['updatedAt'] ?? json['updated_at']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'worker_id': workerId,
    'neighborhood_id': neighborhoodId,
    'name': name,
    'polygon': polygon?.map((e) => e.toJson()).toList(),
    'is_active': isActive,
    'created_at': createdAt,
    'updated_at': updatedAt,
  };
}

class ZonePoint {
  double? lat;
  double? lng;

  ZonePoint({this.lat, this.lng});

  factory ZonePoint.fromJson(Map<String, dynamic> json) => ZonePoint(lat: _asDouble(json['lat']), lng: _asDouble(json['lng']));

  Map<String, dynamic> toJson() => {'lat': lat, 'lng': lng};
}

class Availability {
  int? id;
  int? workerId;
  String? availabilityDate;
  String? availabilityType;
  String? startTime;
  String? endTime;
  String? createdAt;
  String? updatedAt;

  Availability({this.id, this.workerId, this.availabilityDate, this.availabilityType, this.startTime, this.endTime, this.createdAt, this.updatedAt});

  factory Availability.fromJson(Map<String, dynamic> json) => Availability(
    id: _asInt(json['id']),
    workerId: _asInt(json['worker_id']),
    availabilityDate: _asString(json['availability_date']),
    availabilityType: _asString(json['availability_type']),
    startTime: _asString(json['start_time']),
    endTime: _asString(json['end_time']),
    createdAt: _asString(json['created_at']),
    updatedAt: _asString(json['updated_at']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'worker_id': workerId,
    'availability_date': availabilityDate,
    'availability_type': availabilityType,
    'start_time': startTime,
    'end_time': endTime,
    'created_at': createdAt,
    'updated_at': updatedAt,
  };
}
