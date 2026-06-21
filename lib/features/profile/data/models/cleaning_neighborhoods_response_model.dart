import 'dart:convert';

import 'cleaning_neighborhood_model.dart';

Map<String, dynamic> _toMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, val) => MapEntry(key.toString(), val));
  }
  return <String, dynamic>{};
}

List<Map<String, dynamic>> _toMapList(dynamic value) {
  if (value is List) {
    return value.map((item) => _toMap(item)).toList(growable: false);
  }
  return const <Map<String, dynamic>>[];
}

CleaningNeighborhoodsResponseModel cleaningNeighborhoodsResponseModelFromJson(
  dynamic json,
) =>
    CleaningNeighborhoodsResponseModel.fromJson(_toMap(json));

String cleaningNeighborhoodsResponseModelToJson(
  CleaningNeighborhoodsResponseModel data,
) =>
    jsonEncode(data.toJson());

class CleaningNeighborhoodsResponseModel {
  final List<CleaningNeighborhoodModel> data;

  const CleaningNeighborhoodsResponseModel({this.data = const []});

  factory CleaningNeighborhoodsResponseModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return CleaningNeighborhoodsResponseModel(
      data: _toMapList(json['data'])
          .map(CleaningNeighborhoodModel.fromJson)
          .where((neighborhood) => neighborhood.isActive)
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() => {
        'data': data.map((e) => e.toJson()).toList(),
      };
}
