import 'dart:convert';

BookingLocationOkModel bookingLocationOkModelFromJson(dynamic str) {
  final map = str is String ? json.decode(str) as Map<String, dynamic> : Map<String, dynamic>.from(str as Map);
  return BookingLocationOkModel.fromJson(map);
}

class BookingLocationOkModel {
  BookingLocationOkModel({this.ok});

  final bool? ok;

  factory BookingLocationOkModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    return BookingLocationOkModel(ok: data is Map ? data['ok'] == true : null);
  }
}
