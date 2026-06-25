import 'package:injectable/injectable.dart';
import 'package:common_package/helpers/typedef.dart';

import '../repository/profile_repo.dart';
import '../../data/models/cleaning_neighborhoods_response_model.dart';

@lazySingleton
class FetchCleaningNeighborhoodsUseCase
    implements
        UseCase<CleaningNeighborhoodsResponseModel,
            FetchCleaningNeighborhoodsParams> {
  final ProfileRepo profile;

  FetchCleaningNeighborhoodsUseCase({required this.profile});

  @override
  DataResponse<CleaningNeighborhoodsResponseModel> call(
    FetchCleaningNeighborhoodsParams params,
  ) {
    return profile.fetchCleaningNeighborhoods(params);
  }
}

class FetchCleaningNeighborhoodsParams with Params {
  final String? search;
  final String city;

  FetchCleaningNeighborhoodsParams({this.search, this.city = 'حلب'});

  @override
  QueryParams getParams() => {
        'city': city,
        if (search != null && search!.trim().isNotEmpty)
          'search': search!.trim(),
      };
}
