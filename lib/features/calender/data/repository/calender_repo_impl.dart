import 'package:injectable/injectable.dart';
import 'package:common_package/helpers/error_handler.dart';

import '../../domain/repository/calender_repo.dart';

@LazySingleton(as: CalenderRepo)
class CalenderRepoImpl with HandlingException implements CalenderRepo {}

