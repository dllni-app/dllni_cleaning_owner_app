
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

bool? _asBool(dynamic value) {
  if (value == null) return null;
  if (value is bool) return value;
  if (value is num) return value == 1;
  if (value is String) {
    final v = value.toLowerCase();
    return v == 'true' || v == '1';
  }
  return null;
}

FetchDisputeDetailsUsecaseModel fetchDisputeDetailsUsecaseModelFromJson(str) => FetchDisputeDetailsUsecaseModel.fromJson(str);

class FetchDisputeDetailsUsecaseModel {
  FetchDisputeDetailsUsecaseModelData? data;

  FetchDisputeDetailsUsecaseModel({this.data});

  factory FetchDisputeDetailsUsecaseModel.fromJson(Map<String, dynamic> json) {
    return FetchDisputeDetailsUsecaseModel(
      data: json['data'] is Map ? FetchDisputeDetailsUsecaseModelData.fromJson(Map<String, dynamic>.from(json['data'])) : null,
    );
  }

  Map<String, dynamic> toJson() => {"data": data?.toJson()};
}

class FetchDisputeDetailsUsecaseModelData {
  int? id;
  int? bookingId;
  String? bookingType;
  String? ticketNumber;
  String? category;
  String? status;
  String? resolution;
  FetchDisputeBooking? booking;
  List<DisputeMessage>? messages;
  String? createdAt;
  String? updatedAt;

  FetchDisputeDetailsUsecaseModelData({
    this.id,
    this.bookingId,
    this.bookingType,
    this.ticketNumber,
    this.category,
    this.status,
    this.resolution,
    this.booking,
    this.messages,
    this.createdAt,
    this.updatedAt,
  });

  factory FetchDisputeDetailsUsecaseModelData.fromJson(Map<String, dynamic> json) {
    return FetchDisputeDetailsUsecaseModelData(
      id: _asInt(json['id']),
      bookingId: _asInt(json['bookingId']),
      bookingType: _asString(json['bookingType']),
      ticketNumber: _asString(json['ticketNumber']),
      category: _asString(json['category']),
      status: _asString(json['status']),
      resolution: _asString(json['resolution']),
      booking: json['booking'] is Map ? FetchDisputeBooking.fromJson(Map<String, dynamic>.from(json['booking'])) : null,
      messages: json['messages'] is List
          ? (json['messages'] as List).whereType<Map>().map((e) => DisputeMessage.fromJson(Map<String, dynamic>.from(e))).toList()
          : null,
      createdAt: _asString(json['createdAt']),
      updatedAt: _asString(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "bookingId": bookingId,
    "bookingType": bookingType,
    "ticketNumber": ticketNumber,
    "category": category,
    "status": status,
    "resolution": resolution,
    "booking": booking?.toJson(),
    "messages": messages?.map((e) => e.toJson()).toList(),
    "createdAt": createdAt,
    "updatedAt": updatedAt,
  };
}

class FetchDisputeBooking {
  int? id;
  String? bookingNumber;
  String? status;
  String? propertyType;
  double? totalPrice;
  PropertyDetails? propertyDetails;

  FetchDisputeBooking({this.id, this.bookingNumber, this.status, this.propertyType, this.totalPrice, this.propertyDetails});

  factory FetchDisputeBooking.fromJson(Map<String, dynamic> json) {
    return FetchDisputeBooking(
      id: _asInt(json['id']),
      bookingNumber: _asString(json['booking_number']),
      status: _asString(json['status']),
      propertyType: _asString(json['property_type']),
      totalPrice: _asDouble(json['total_price']),
      propertyDetails: json['property_details'] is Map ? PropertyDetails.fromJson(Map<String, dynamic>.from(json['property_details'])) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "booking_number": bookingNumber,
    "status": status,
    "property_type": propertyType,
    "total_price": totalPrice,
    "property_details": propertyDetails?.toJson(),
  };
}

class PropertyDetails {
  String? locationName;
  String? address;
  int? bedrooms;
  int? rooms;
  int? bathrooms;
  bool? kitchenIncluded;

  PropertyDetails({this.locationName, this.address, this.bedrooms, this.rooms, this.bathrooms, this.kitchenIncluded});

  factory PropertyDetails.fromJson(Map<String, dynamic> json) {
    return PropertyDetails(
      locationName: _asString(json['location_name']),
      address: _asString(json['address']),
      bedrooms: _asInt(json['bedrooms']),
      rooms: _asInt(json['rooms']),
      bathrooms: _asInt(json['bathrooms']),
      kitchenIncluded: _asBool(json['kitchen_included']),
    );
  }

  Map<String, dynamic> toJson() => {
    "location_name": locationName,
    "address": address,
    "bedrooms": bedrooms,
    "rooms": rooms,
    "bathrooms": bathrooms,
    "kitchen_included": kitchenIncluded,
  };
}

class DisputeMessage {
  int? id;
  int? disputeId;
  int? senderId;
  String? senderType;
  String? body;
  String? createdAt;
  String? updatedAt;

  DisputeMessage({this.id, this.disputeId, this.senderId, this.senderType, this.body, this.createdAt, this.updatedAt});

  factory DisputeMessage.fromJson(Map<String, dynamic> json) {
    return DisputeMessage(
      id: _asInt(json['id']),
      disputeId: _asInt(json['dispute_id']),
      senderId: _asInt(json['sender_id']),
      senderType: _asString(json['sender_type']),
      body: _asString(json['body']),
      createdAt: _asString(json['created_at']),
      updatedAt: _asString(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "dispute_id": disputeId,
    "sender_id": senderId,
    "sender_type": senderType,
    "body": body,
    "created_at": createdAt,
    "updated_at": updatedAt,
  };
}
