import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import '../manager/bloc/profile_bloc.dart';

class WorkerDepositEligibilityHelper {
  WorkerDepositEligibilityHelper._();

  static bool? readIsEligibleForNewRequests(BuildContext context) {
    try {
      return context.read<ProfileBloc>().state.depositAccount?.isEligibleForNewRequests;
    } on ProviderNotFoundException {
      return null;
    }
  }

  static bool? watchIsEligibleForNewRequests(BuildContext context) {
    try {
      return context.watch<ProfileBloc>().state.depositAccount?.isEligibleForNewRequests;
    } on ProviderNotFoundException {
      return null;
    }
  }
}
