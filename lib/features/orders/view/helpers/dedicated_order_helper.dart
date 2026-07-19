import 'dart:convert';

import 'package:common_package/helpers/shared_preferences_helper.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/data/models/fetch_worker_profile_usecase_model.dart';

class DedicatedOrderHelper {
  DedicatedOrderHelper._();

  static int? currentAccountId() {
    final rawProfile = SharedPreferencesHelper.getData(key: 'user');
    if (rawProfile == null) return null;

    try {
      final decodedProfile = rawProfile is String
          ? json.decode(rawProfile)
          : rawProfile;
      final profile = fetchWorkerProfileUsecaseModelFromJson(decodedProfile);
      return profile.data?.id ?? profile.data?.user?.id;
    } catch (_) {
      return null;
    }
  }

  static bool isDedicatedToCurrentUser(int? preferredWorkerId) {
    final currentAccountId = DedicatedOrderHelper.currentAccountId();
    return preferredWorkerId != null &&
        currentAccountId != null &&
        preferredWorkerId == currentAccountId;
  }
}
