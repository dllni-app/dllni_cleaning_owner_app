import 'dart:io';

import 'package:common_package/helpers/typedef.dart';
import 'package:injectable/injectable.dart';
import '../repository/profile_repo.dart';
import '../../data/models/update_worker_profile_model.dart';

@lazySingleton
class UpdateWorkerProfileUseCase
    implements UseCase<UpdateWorkerProfileModel, UpdateWorkerProfileParams> {
  final ProfileRepo profile;

  UpdateWorkerProfileUseCase({required this.profile});

  @override
  DataResponse<UpdateWorkerProfileModel> call(
    UpdateWorkerProfileParams params,
  ) {
    return profile.updateWorkerProfile(params);
  }
}

class UpdateWorkerProfileParams with Params {
  final String? name;
  final String? phone;
  final File? avatar;
  final int? isActive;
  final String? email;
  final String? city;
  final String? gender;
  final String? birthday;
  final String? bio;
  final double? homeLatitude;
  final double? homeLongitude;
  final String? homeAddress;
  final String? preferredWorkType;

  UpdateWorkerProfileParams({
    this.name,
    this.phone,
    this.avatar,
    this.isActive,
    this.email,
    this.city,
    this.gender,
    this.birthday,
    this.bio,
    this.homeLatitude,
    this.homeLongitude,
    this.homeAddress,
    this.preferredWorkType,
  });

  @override
  Map<String, dynamic> getBody() => {
    'name': name,
    'phone': phone,
    'avatar': avatar,
    'isActive': isActive,
    'email': email,
    'city': city,
    'gender': gender,
    'birthday': birthday,
    'bio': bio,
    'homeLatitude': homeLatitude,
    'homeLongitude': homeLongitude,
    'homeAddress': homeAddress,
    'preferred_work_type': preferredWorkType,
  }..removeWhere((key, val) => val == null);
}
