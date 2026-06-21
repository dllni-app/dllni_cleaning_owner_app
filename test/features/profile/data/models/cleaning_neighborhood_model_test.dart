import 'package:dllni_cleaninig_owner_app/features/profile/data/models/cleaning_neighborhood_model.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/data/models/cleaning_neighborhoods_response_model.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/data/models/worker_work_areas_model.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/domain/usecases/update_worker_work_areas_use_case.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CleaningNeighborhoodModel.fromJson', () {
    test('parses camelCase payload', () {
      final model = CleaningNeighborhoodModel.fromJson(<String, dynamic>{
        'id': 38,
        'cityName': 'حلب',
        'nameAr': 'بستان الباشا',
        'nameEn': 'Bustan al-Pasha',
        'displayName': 'بستان الباشا',
        'aliases': ['Bustan al-Pasha district'],
        'isActive': true,
      });

      expect(model.id, 38);
      expect(model.cityName, 'حلب');
      expect(model.nameAr, 'بستان الباشا');
      expect(model.nameEn, 'Bustan al-Pasha');
      expect(model.displayName, 'بستان الباشا');
      expect(model.aliases, ['Bustan al-Pasha district']);
      expect(model.isActive, isTrue);
    });

    test('parses snake_case payload', () {
      final model = CleaningNeighborhoodModel.fromJson(<String, dynamic>{
        'id': '39',
        'city_name': 'حلب',
        'name_ar': 'الجميلية',
        'name_en': 'Al-Jamiliyah',
        'display_name': 'الجميلية',
        'aliases': <String>[],
        'is_active': 1,
      });

      expect(model.id, 39);
      expect(model.cityName, 'حلب');
      expect(model.displayName, 'الجميلية');
      expect(model.isActive, isTrue);
    });
  });

  group('CleaningNeighborhoodsResponseModel.fromJson', () {
    test('filters inactive neighborhoods', () {
      final model = cleaningNeighborhoodsResponseModelFromJson(<String, dynamic>{
        'data': [
          {
            'id': 1,
            'cityName': 'حلب',
            'nameAr': 'حي 1',
            'displayName': 'حي 1',
            'isActive': true,
          },
          {
            'id': 2,
            'cityName': 'حلب',
            'nameAr': 'حي 2',
            'displayName': 'حي 2',
            'isActive': false,
          },
        ],
      });

      expect(model.data, hasLength(1));
      expect(model.data.first.id, 1);
    });
  });

  group('WorkerWorkAreaZone.fromJson', () {
    test('parses neighborhoodId in camelCase and snake_case', () {
      final camelCase = WorkerWorkAreaZone.fromJson(<String, dynamic>{
        'id': 10,
        'neighborhoodId': 38,
        'name': 'بستان الباشا',
        'isActive': true,
      });
      final snakeCase = WorkerWorkAreaZone.fromJson(<String, dynamic>{
        'id': 11,
        'neighborhood_id': 39,
        'name': 'الجميلية',
        'is_active': true,
      });

      expect(camelCase.neighborhoodId, 38);
      expect(snakeCase.neighborhoodId, 39);
    });
  });

  group('WorkAreaZoneUpdateItem.toJson', () {
    test('includes neighborhoodId in payload', () {
      const item = WorkAreaZoneUpdateItem(
        neighborhoodId: 38,
        name: 'بستان الباشا',
        isActive: true,
      );

      expect(item.toJson(), {
        'neighborhoodId': 38,
        'name': 'بستان الباشا',
        'isActive': true,
      });
    });
  });
}
