import 'package:injectable/injectable.dart';
import 'package:common_package/helpers/error_handler.dart';

import '../../domain/repository/{{name}}_repo.dart';

@LazySingleton(as: {{name.pascalCase()}}Repo)
class {{name.pascalCase()}}RepoImpl with HandlingException implements {{name.pascalCase()}}Repo {}

