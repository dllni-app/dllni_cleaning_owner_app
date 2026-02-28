import 'package:injectable/injectable.dart';
import 'package:common_package/helpers/error_handler.dart';

import '../../domain/repository/main_repo.dart';

@LazySingleton(as: MainRepo)
class MainRepoImpl with HandlingException implements MainRepo {}

