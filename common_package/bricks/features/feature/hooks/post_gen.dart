import 'dart:convert';
import 'dart:io';

import 'package:mason/mason.dart';

Future<void> run(HookContext context) async {
  final logger = context.logger;
  final featureName = context.vars['name'] as String;
  final usecases = _parseUsecases(context);

  logger
    ..info('post_gen: featureName = $featureName')
    ..info('post_gen: raw usecases var = ${context.vars['usecases']}')
    ..info('post_gen: parsed usecases = $usecases');

  if (usecases.isEmpty) {
    logger.info('No usecases provided, skipping domain/usecases generation.');
    return;
  }

  final root = Directory.current.path;
  final usecasesDirPath = '$root/lib/features/$featureName/domain/usecases';
  final usecasesDir = Directory(usecasesDirPath)..createSync(recursive: true);
  final modelsDir = Directory('$root/lib/features/$featureName/data/models')
    ..createSync(recursive: true);

  final usecaseSpecs = <_UsecaseSpec>[];

  for (final usecaseName in usecases) {
    var spec = _promptForUsecaseSpec(
      logger: logger,
      root: root,
      featureName: featureName,
      usecaseName: usecaseName,
    );

    if (spec.sampleJson != null) {
      _createModelFromJson(
        modelsDir: modelsDir,
        spec: spec,
        logger: logger,
      );
    }

    spec = _resolveUsecaseSpec(
      root: root,
      spec: spec,
      logger: logger,
    );
    spec = _ensureUniqueStateAlias(spec: spec, existingSpecs: usecaseSpecs);
    usecaseSpecs.add(spec);

    _createUsecaseFile(
      root: root,
      usecasesDir: usecasesDir,
      featureName: featureName,
      spec: spec,
      logger: logger,
    );
  }

  _updateRepoInterface(
    root: root,
    featureName: featureName,
    specs: usecaseSpecs,
    logger: logger,
  );
  _updateRemoteDataSource(
    root: root,
    featureName: featureName,
    specs: usecaseSpecs,
    logger: logger,
  );
  _updateRepoImplementation(
    root: root,
    featureName: featureName,
    specs: usecaseSpecs,
    logger: logger,
  );
  _updateBlocFiles(
    root: root,
    featureName: featureName,
    specs: usecaseSpecs,
    logger: logger,
  );
}

List<String> _parseUsecases(HookContext context) {
  final usecases = <String>[];
  final seen = <String>{};

  void addUsecase(String value) {
    final normalized = _toPascalCase(value.trim());
    if (normalized.isEmpty) return;
    final key = normalized.toLowerCase();
    if (seen.add(key)) {
      usecases.add(normalized);
    }
  }

  final fromPreGen = context.vars['usecase_names'];
  if (fromPreGen is List) {
    for (final usecase in fromPreGen) {
      addUsecase('$usecase');
    }
    return usecases;
  }

  final raw = context.vars['usecases'] as String? ?? '';
  for (final item in raw.split(',')) {
    addUsecase(item);
  }
  return usecases;
}

_UsecaseSpec _promptForUsecaseSpec({
  required Logger logger,
  required String root,
  required String featureName,
  required String usecaseName,
}) {
  final defaultModelClass = '${_toPascalCase(usecaseName)}Model';
  late final String modelClassName;
  late final String modelFileName;
  late final String modelLibPath;
  Map<String, dynamic>? sampleJson;

  while (true) {
    final input = logger
        .prompt(
          'Model for $usecaseName (class name or JSON object in one line)',
          defaultValue: defaultModelClass,
        )
        .trim();

    if (_looksLikeJson(input)) {
      try {
        final decoded = jsonDecode(input);
        final normalizedSampleJson = _normalizeJsonSample(decoded);
        if (normalizedSampleJson == null) {
          logger.err('JSON input for $usecaseName must be an object or array.');
          continue;
        }

        sampleJson = normalizedSampleJson;
        modelClassName = '${_toPascalCase(usecaseName)}Model';
        modelFileName = '${_toSnakeCase(usecaseName)}_model.dart';
        modelLibPath = 'features/$featureName/data/models/$modelFileName';
        break;
      } catch (error) {
        logger.err('Invalid JSON for $usecaseName: $error');
        continue;
      }
    }

    final sanitizedModelClassName = _sanitizeClassName(input);
    if (sanitizedModelClassName.isEmpty) {
      logger.err('Please enter a valid Dart class name or JSON.');
      continue;
    }

    sampleJson = null;
    modelClassName = sanitizedModelClassName;
    modelFileName = '${_toSnakeCase(sanitizedModelClassName)}.dart';
    modelLibPath = _resolveModelClassLocation(
      logger: logger,
      root: root,
      featureName: featureName,
      usecaseName: usecaseName,
      modelClassName: modelClassName,
      defaultModelFileName: modelFileName,
    );
    break;
  }

  final requestConfig = _promptForRequestConfig(
    logger: logger,
    featureName: featureName,
    usecaseName: usecaseName,
  );
  final responseKind = _promptForResponseKind(
    logger: logger,
    usecaseName: usecaseName,
  );

  return _UsecaseSpec(
    usecaseName: usecaseName,
    modelClassName: modelClassName,
    modelFileName: modelFileName,
    modelLibPath: modelLibPath,
    sampleJson: sampleJson,
    httpMethod: requestConfig.httpMethod,
    endpoint: requestConfig.endpoint,
    responseKind: responseKind,
    stateAlias: _deriveStateAlias(usecaseName),
  );
}

_UsecaseRequestConfig _promptForRequestConfig({
  required Logger logger,
  required String featureName,
  required String usecaseName,
}) {
  final defaultEndpoint = '/$featureName/${_toSnakeCase(usecaseName)}';

  late final _HttpMethod method;
  while (true) {
    final input = logger
        .prompt(
          'HTTP method for $usecaseName (GET, POST, PUT, PATCH, DELETE)',
          defaultValue: _HttpMethod.get.value,
        )
        .trim();
    final parsedMethod = _parseHttpMethod(input);
    if (parsedMethod == null) {
      logger.err(
        'Invalid HTTP method "$input". Allowed values: GET, POST, PUT, PATCH, DELETE.',
      );
      continue;
    }
    method = parsedMethod;
    break;
  }

  while (true) {
    final endpoint = logger
        .prompt('Endpoint for $usecaseName', defaultValue: defaultEndpoint)
        .trim();
    if (endpoint.isEmpty) {
      logger.err('Endpoint for $usecaseName cannot be empty.');
      continue;
    }
    return _UsecaseRequestConfig(httpMethod: method, endpoint: endpoint);
  }
}

_HttpMethod? _parseHttpMethod(String input) {
  switch (input.trim().toUpperCase()) {
    case 'GET':
      return _HttpMethod.get;
    case 'POST':
      return _HttpMethod.post;
    case 'PUT':
      return _HttpMethod.put;
    case 'PATCH':
      return _HttpMethod.patch;
    case 'DELETE':
      return _HttpMethod.delete;
    default:
      return null;
  }
}

_ResponseKind _promptForResponseKind({
  required Logger logger,
  required String usecaseName,
}) {
  while (true) {
    final input = logger
        .prompt(
          'Response type for $usecaseName (paginated or normal)',
          defaultValue: _ResponseKind.normal.value,
        )
        .trim();
    final parsedKind = _parseResponseKind(input);
    if (parsedKind == null) {
      logger.err(
        'Invalid response type "$input". Allowed values: paginated, normal.',
      );
      continue;
    }
    return parsedKind;
  }
}

_ResponseKind? _parseResponseKind(String input) {
  switch (input.trim().toLowerCase()) {
    case 'paginated':
      return _ResponseKind.paginated;
    case 'normal':
      return _ResponseKind.normal;
    default:
      return null;
  }
}

String _resolveModelClassLocation({
  required Logger logger,
  required String root,
  required String featureName,
  required String usecaseName,
  required String modelClassName,
  required String defaultModelFileName,
}) {
  final matches = _findModelClassMatches(
    root: root,
    modelClassName: modelClassName,
  );

  if (matches.length == 1) {
    logger.info('Detected $modelClassName in lib/${matches.first}.');
    return matches.first;
  }

  final defaultLibPath =
      'features/$featureName/data/models/$defaultModelFileName';
  if (matches.isEmpty) {
    logger.warn(
      'Could not find class $modelClassName in lib/. Please provide model file path.',
    );
    return _promptForModelLibPath(
      logger: logger,
      root: root,
      usecaseName: usecaseName,
      modelClassName: modelClassName,
      defaultLibPath: defaultLibPath,
    );
  }

  logger.warn('Multiple files contain class $modelClassName:');
  for (var i = 0; i < matches.length; i++) {
    logger.info('  ${i + 1}. lib/${matches[i]}');
  }

  while (true) {
    final input = logger
        .prompt(
          'Select model path for $usecaseName (enter number 1-${matches.length} or path under lib/)',
          defaultValue: '1',
        )
        .trim();

    final index = int.tryParse(input);
    if (index != null) {
      if (index < 1 || index > matches.length) {
        logger.err('Please enter a number between 1 and ${matches.length}.');
        continue;
      }
      final selectedPath = matches[index - 1];
      _warnIfSelectedModelFileDoesNotContainClass(
        logger: logger,
        root: root,
        modelClassName: modelClassName,
        modelLibPath: selectedPath,
      );
      return selectedPath;
    }

    final selectedPath = _validateAndNormalizeModelLibPathInput(
      logger: logger,
      root: root,
      input: input,
      modelClassName: modelClassName,
    );
    if (selectedPath == null) {
      continue;
    }
    return selectedPath;
  }
}

List<String> _findModelClassMatches({
  required String root,
  required String modelClassName,
}) {
  final libRootDirectory =
      Directory('${Directory(root).path}${Platform.pathSeparator}lib');
  if (!libRootDirectory.existsSync()) {
    return const [];
  }

  final classPattern = RegExp('class\\s+${RegExp.escape(modelClassName)}\\b');
  final matches = <String>[];

  for (final entity
      in libRootDirectory.listSync(recursive: true, followLinks: false)) {
    if (entity is! File) {
      continue;
    }

    final filePath = _toPosixPath(entity.path);
    if (!_isSearchableDartSourceFile(filePath)) {
      continue;
    }

    String content;
    try {
      content = entity.readAsStringSync();
    } catch (_) {
      continue;
    }

    if (!classPattern.hasMatch(content)) {
      continue;
    }

    final libRelativePath = _absoluteToLibRelativePath(
      root: root,
      absolutePath: entity.path,
    );
    if (libRelativePath != null) {
      matches.add(libRelativePath);
    }
  }

  matches.sort();
  return matches;
}

bool _isSearchableDartSourceFile(String path) {
  if (!path.endsWith('.dart')) {
    return false;
  }
  return !(path.endsWith('.g.dart') || path.endsWith('.freezed.dart'));
}

String _promptForModelLibPath({
  required Logger logger,
  required String root,
  required String usecaseName,
  required String modelClassName,
  required String defaultLibPath,
}) {
  while (true) {
    final input = logger
        .prompt(
          'Model file path under lib/ for $usecaseName ($modelClassName)',
          defaultValue: defaultLibPath,
        )
        .trim();

    final modelLibPath = _validateAndNormalizeModelLibPathInput(
      logger: logger,
      root: root,
      input: input,
      modelClassName: modelClassName,
    );
    if (modelLibPath != null) {
      return modelLibPath;
    }
  }
}

String? _validateAndNormalizeModelLibPathInput({
  required Logger logger,
  required String root,
  required String input,
  required String modelClassName,
}) {
  final normalized = _normalizeModelLibPathInput(input);
  if (normalized == null) {
    logger.err(
      'Please enter a valid Dart file path under lib/ (example: features/auth/data/models/login_model.dart).',
    );
    return null;
  }

  final absolutePath =
      _libRelativeToAbsolutePath(root: root, libRelativePath: normalized);
  final file = File(absolutePath);
  if (!file.existsSync()) {
    logger.err('File not found: lib/$normalized');
    return null;
  }

  _warnIfSelectedModelFileDoesNotContainClass(
    logger: logger,
    root: root,
    modelClassName: modelClassName,
    modelLibPath: normalized,
  );
  return normalized;
}

void _warnIfSelectedModelFileDoesNotContainClass({
  required Logger logger,
  required String root,
  required String modelClassName,
  required String modelLibPath,
}) {
  final absolutePath = _libRelativeToAbsolutePath(
    root: root,
    libRelativePath: modelLibPath,
  );
  if (!_fileContainsClassDeclaration(
    filePath: absolutePath,
    className: modelClassName,
  )) {
    logger.warn(
      'File lib/$modelLibPath does not contain class $modelClassName. Continuing with user-selected path.',
    );
  }
}

bool _fileContainsClassDeclaration({
  required String filePath,
  required String className,
}) {
  final file = File(filePath);
  if (!file.existsSync()) {
    return false;
  }

  String content;
  try {
    content = file.readAsStringSync();
  } catch (_) {
    return false;
  }
  final classPattern = RegExp('class\\s+${RegExp.escape(className)}\\b');
  return classPattern.hasMatch(content);
}

String? _normalizeModelLibPathInput(String input) {
  var normalized = _toPosixPath(input.trim());
  if (normalized.isEmpty) {
    return null;
  }
  if (normalized.startsWith('package:')) {
    return null;
  }
  if (normalized.startsWith('lib/')) {
    normalized = normalized.substring(4);
  }
  while (normalized.startsWith('/')) {
    normalized = normalized.substring(1);
  }
  while (normalized.startsWith('./')) {
    normalized = normalized.substring(2);
  }

  if (normalized.isEmpty || !normalized.endsWith('.dart')) {
    return null;
  }

  final segments = normalized.split('/');
  if (segments
      .any((segment) => segment.isEmpty || segment == '.' || segment == '..')) {
    return null;
  }
  return normalized;
}

String _libRelativeToAbsolutePath({
  required String root,
  required String libRelativePath,
}) {
  final rootPath = _toPosixPath(Directory(root).absolute.path);
  return '$rootPath/lib/${_toPosixPath(libRelativePath)}';
}

String? _absoluteToLibRelativePath({
  required String root,
  required String absolutePath,
}) {
  final rootPath = _toPosixPath(Directory(root).absolute.path);
  final absolute = _toPosixPath(File(absolutePath).absolute.path);
  final libPrefix = '$rootPath/lib/';
  if (!absolute.startsWith(libPrefix)) {
    return null;
  }
  return absolute.substring(libPrefix.length);
}

void _createModelFromJson({
  required Directory modelsDir,
  required _UsecaseSpec spec,
  required Logger logger,
}) {
  final sampleJson = spec.sampleJson;
  if (sampleJson == null) return;

  final modelFile = File('${modelsDir.path}/${spec.modelFileName}');
  if (modelFile.existsSync()) {
    logger.warn(
      'Model file already exists: ${modelFile.path}, skipping JSON model generation.',
    );
    return;
  }

  final content = _buildModelContentFromJson(
    rootClassName: spec.modelClassName,
    sampleJson: sampleJson,
  );
  modelFile.writeAsStringSync(content);
  logger.info('Created model: ${modelFile.path}');
}

void _createUsecaseFile({
  required String root,
  required Directory usecasesDir,
  required String featureName,
  required _UsecaseSpec spec,
  required Logger logger,
}) {
  final fileName = '${spec.usecaseSnake}_use_case.dart';
  final file = File('${usecasesDir.path}/$fileName');

  if (file.existsSync()) {
    logger.warn('Usecase file already exists: ${file.path}, skipping.');
    return;
  }

  file.writeAsStringSync(
    _usecaseTemplate(
      spec: spec,
      root: root,
      featureName: featureName,
      usecaseFilePath: file.path,
    ),
  );
  logger.info('Created usecase: ${file.path}');
}

Map<String, dynamic>? _normalizeJsonSample(dynamic decoded) {
  if (decoded is Map) {
    return decoded.map((key, value) => MapEntry('$key', value));
  }
  if (decoded is List) {
    return {'items': decoded};
  }
  return null;
}

bool _looksLikeJson(String input) {
  final trimmed = input.trimLeft();
  return trimmed.startsWith('{') || trimmed.startsWith('[');
}

String _sanitizeClassName(String input) {
  final className = _toPascalCase(input);
  if (className.isEmpty) return '';

  final startsWithNumber = RegExp(r'^\d').hasMatch(className);
  if (startsWithNumber) {
    return 'Model$className';
  }

  if (_dartReservedWords.contains(className.toLowerCase())) {
    return '${className}Model';
  }

  return className;
}

String _toSnakeCase(String input) {
  final withUnderscores = input
      .replaceAllMapped(
        RegExp(r'([a-z0-9])([A-Z])'),
        (match) => '${match.group(1)}_${match.group(2)}',
      )
      .replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')
      .replaceAll(RegExp(r'_+'), '_');
  return _trimUnderscores(withUnderscores).toLowerCase();
}

String _trimUnderscores(String input) {
  var result = input;
  while (result.startsWith('_')) {
    result = result.substring(1);
  }
  while (result.endsWith('_')) {
    result = result.substring(0, result.length - 1);
  }
  return result;
}

String _usecaseTemplate(
    {required _UsecaseSpec spec,
    required String root,
    required String featureName,
    required String usecaseFilePath}) {
  final usecaseBase = spec.usecasePascal;
  final usecaseClass = '${usecaseBase}UseCase';
  final paramsClass = spec.paramsClassName;
  final featurePascal = _toPascalCase(featureName);
  final featureRepoField = _lowerFirst(featurePascal);
  final methodName = spec.methodName;
  final modelImportPath = _buildRelativeImportPath(
    root: root,
    fromFilePath: usecaseFilePath,
    toLibPath: spec.modelLibPath,
  );

  return '''
import 'package:injectable/injectable.dart';
import 'package:common_package/helpers/typedef.dart';

import '../repository/${featureName}_repo.dart';
import '$modelImportPath';

@lazySingleton
class $usecaseClass implements UseCase<${spec.modelClassName}, $paramsClass> {

  final ${featurePascal}Repo $featureRepoField;

  $usecaseClass({required this.$featureRepoField});

  @override
  DataResponse<${spec.modelClassName}> call($paramsClass params) {
    return $featureRepoField.$methodName(params);
  }
}

class $paramsClass with Params{}
''';
}

String _toPascalCase(String input) {
  final parts = input
      .replaceAllMapped(
        RegExp(r'([a-z0-9])([A-Z])'),
        (match) => '${match.group(1)} ${match.group(2)}',
      )
      .replaceAll(RegExp(r'[^A-Za-z0-9]+'), ' ')
      .split(RegExp(r'\s+'))
      .where((e) => e.isNotEmpty)
      .toList();
  final buffer = StringBuffer();
  for (final part in parts) {
    if (part.isEmpty) continue;
    buffer
      ..write(part[0].toUpperCase())
      ..write(part.substring(1));
  }
  return buffer.toString();
}

_UsecaseSpec _resolveUsecaseSpec({
  required String root,
  required _UsecaseSpec spec,
  required Logger logger,
}) {
  if (spec.responseKind != _ResponseKind.paginated) {
    return spec;
  }

  final modelPath = _libRelativeToAbsolutePath(
    root: root,
    libRelativePath: spec.modelLibPath,
  );
  final itemType = _inferPaginatedItemType(
    modelPath: modelPath,
    usecaseName: spec.usecaseName,
    logger: logger,
  );
  return spec.copyWith(paginatedItemType: itemType);
}

_UsecaseSpec _ensureUniqueStateAlias({
  required _UsecaseSpec spec,
  required List<_UsecaseSpec> existingSpecs,
}) {
  final existingAliases = existingSpecs.map((e) => e.stateAlias).toSet();
  if (!existingAliases.contains(spec.stateAlias)) {
    return spec;
  }

  var index = 2;
  while (existingAliases.contains('${spec.stateAlias}$index')) {
    index++;
  }
  return spec.copyWith(stateAlias: '${spec.stateAlias}$index');
}

String _deriveStateAlias(String usecaseName) {
  final words = _toSnakeCase(usecaseName)
      .split('_')
      .where((word) => word.isNotEmpty)
      .toList();
  if (words.isEmpty) {
    return 'value';
  }

  final remainingWords = List<String>.from(words);
  while (remainingWords.isNotEmpty &&
      _stateAliasVerbPrefixes.contains(remainingWords.first.toLowerCase())) {
    remainingWords.removeAt(0);
  }

  final sourceWords = remainingWords.isEmpty ? words : remainingWords;
  final buffer = StringBuffer(sourceWords.first.toLowerCase());
  for (var i = 1; i < sourceWords.length; i++) {
    final word = sourceWords[i];
    if (word.isEmpty) continue;
    buffer
      ..write(word[0].toUpperCase())
      ..write(word.substring(1));
  }

  var alias = buffer.toString();
  if (alias.isEmpty) {
    alias = _lowerFirst(_toPascalCase(usecaseName));
  }

  if (RegExp(r'^\d').hasMatch(alias)) {
    alias = 'value$alias';
  }
  if (_dartReservedWords.contains(alias.toLowerCase())) {
    alias = '${alias}Value';
  }
  return alias;
}

String _inferPaginatedItemType({
  required String modelPath,
  required String usecaseName,
  required Logger logger,
}) {
  final modelFile = File(modelPath);
  if (!modelFile.existsSync()) {
    logger.warn(
      'Could not infer paginated item type for $usecaseName: model file not found at $modelPath. Falling back to dynamic.',
    );
    return 'dynamic';
  }

  final content = modelFile.readAsStringSync();
  final primaryDataPattern = RegExp(
    r'(?:final\s+)?List<\s*([^>\r\n]+)\s*>\s*\??\s+data\s*;',
    multiLine: true,
  );
  final secondaryListPattern = RegExp(
    r'(?:final\s+)?List<\s*([^>\r\n]+)\s*>\s*\??\s+[A-Za-z_][A-Za-z0-9_]*\s*;',
    multiLine: true,
  );

  final primaryMatch = primaryDataPattern.firstMatch(content);
  final secondaryMatch = secondaryListPattern.firstMatch(content);
  final rawType = primaryMatch?.group(1) ?? secondaryMatch?.group(1);
  if (rawType == null || rawType.trim().isEmpty) {
    logger.warn(
      'Could not infer paginated item type for $usecaseName from $modelPath. Falling back to dynamic.',
    );
    return 'dynamic';
  }

  final normalizedType = rawType.trim().replaceAll(RegExp(r'\s+'), '');
  if (normalizedType.isEmpty) {
    logger.warn(
      'Could not infer paginated item type for $usecaseName from $modelPath. Falling back to dynamic.',
    );
    return 'dynamic';
  }
  return normalizedType.endsWith('?')
      ? normalizedType.substring(0, normalizedType.length - 1)
      : normalizedType;
}

void _updateRepoInterface({
  required String root,
  required String featureName,
  required List<_UsecaseSpec> specs,
  required Logger logger,
}) {
  final repoPath =
      '$root/lib/features/$featureName/domain/repository/${featureName}_repo.dart';
  final repoFile = File(repoPath);
  if (!repoFile.existsSync()) {
    logger.warn('Repo file not found at $repoPath, skipping repo update.');
    return;
  }

  var content = repoFile.readAsStringSync();
  content = _ensureImport(
    content,
    "import 'package:common_package/helpers/typedef.dart';",
  );

  for (final spec in specs) {
    content = _ensureImport(
      content,
      "import '../usecases/${spec.usecaseSnake}_use_case.dart';",
    );
    final modelImportPath = _buildRelativeImportPath(
      root: root,
      fromFilePath: repoPath,
      toLibPath: spec.modelLibPath,
    );
    content = _ensureImportBySuffix(
      content: content,
      importLine: "import '$modelImportPath';",
      importPathSuffix: spec.modelImportSuffix,
    );

    final methodSignature =
        '  DataResponse<${spec.modelClassName}> ${spec.methodName}(${spec.paramsClassName} params);';
    if (!content.contains(methodSignature)) {
      content = _insertBeforeLastBrace(content, methodSignature);
    }
  }

  repoFile.writeAsStringSync(content);
  logger.info('Updated repo interface: $repoPath');
}

String _lowerFirst(String input) {
  if (input.isEmpty) return input;
  return input[0].toLowerCase() + input.substring(1);
}

String _buildRelativeImportPath({
  required String root,
  required String fromFilePath,
  required String toLibPath,
}) {
  final normalizedToLibPath =
      _normalizeModelLibPathInput(toLibPath) ?? toLibPath;
  final fromLibRelativePath =
      _absoluteToLibRelativePath(root: root, absolutePath: fromFilePath);
  if (fromLibRelativePath == null) {
    return normalizedToLibPath;
  }

  final fromDirSegments = _toPosixPath(fromLibRelativePath)
      .split('/')
      .where((segment) => segment.isNotEmpty)
      .toList();
  if (fromDirSegments.isNotEmpty) {
    fromDirSegments.removeLast();
  }

  final toSegments = _toPosixPath(normalizedToLibPath)
      .split('/')
      .where((segment) => segment.isNotEmpty)
      .toList();
  if (toSegments.isEmpty) {
    return normalizedToLibPath;
  }

  var commonIndex = 0;
  while (commonIndex < fromDirSegments.length &&
      commonIndex < toSegments.length &&
      fromDirSegments[commonIndex] == toSegments[commonIndex]) {
    commonIndex++;
  }

  final upward =
      List<String>.filled(fromDirSegments.length - commonIndex, '..');
  final downward = toSegments.sublist(commonIndex);
  final relativeSegments = <String>[...upward, ...downward];
  if (relativeSegments.isEmpty) {
    return toSegments.last;
  }
  return relativeSegments.join('/');
}

String _toPosixPath(String path) {
  return path.replaceAll('\\', '/');
}

void _updateRemoteDataSource({
  required String root,
  required String featureName,
  required List<_UsecaseSpec> specs,
  required Logger logger,
}) {
  final remoteDataSourcePath =
      '$root/lib/features/$featureName/data/source/${featureName}_remote_data_source.dart';
  final remoteDataSourceFile = File(remoteDataSourcePath);
  if (!remoteDataSourceFile.existsSync()) {
    logger.warn(
      'Remote data source file not found at $remoteDataSourcePath, skipping update.',
    );
    return;
  }

  var content = remoteDataSourceFile.readAsStringSync();
  content = _ensureImportBySuffix(
    content: content,
    importLine: "import 'package:injectable/injectable.dart';",
    importPathSuffix: 'injectable/injectable.dart',
  );
  content = _ensureImportBySuffix(
    content: content,
    importLine: "import 'package:common_package/helpers/api_handler.dart';",
    importPathSuffix: 'helpers/api_handler.dart',
  );
  content = _ensureImportBySuffix(
    content: content,
    importLine: "import '../../../../helpers/dio_network.dart';",
    importPathSuffix: 'helpers/dio_network.dart',
  );

  for (final spec in specs) {
    final modelImportPath = _buildRelativeImportPath(
      root: root,
      fromFilePath: remoteDataSourcePath,
      toLibPath: spec.modelLibPath,
    );
    content = _ensureImportBySuffix(
      content: content,
      importLine: "import '$modelImportPath';",
      importPathSuffix: spec.modelImportSuffix,
    );
    content = _ensureImportBySuffix(
      content: content,
      importLine:
          "import '../../domain/usecases/${spec.usecaseSnake}_use_case.dart';",
      importPathSuffix: 'domain/usecases/${spec.usecaseSnake}_use_case.dart',
    );
  }

  final featurePascal = _toPascalCase(featureName);
  final remoteDataSourceClassName = '${featurePascal}RemoteDataSource';
  final remoteDataSourceRegion =
      _findClassRegion(content, remoteDataSourceClassName);
  if (remoteDataSourceRegion == null) {
    logger.warn(
      'Remote data source class $remoteDataSourceClassName not found in $remoteDataSourcePath.',
    );
    return;
  }

  content = _ensureClassMember(
    content: content,
    className: remoteDataSourceClassName,
    memberDeclaration: 'final DioNetwork dioNetwork;',
  );
  content = _ensureClassMember(
    content: content,
    className: remoteDataSourceClassName,
    memberDeclaration:
        '$remoteDataSourceClassName({required this.dioNetwork});',
    afterMemberDeclaration: 'final DioNetwork dioNetwork;',
    withBlankLine: true,
  );

  for (final spec in specs) {
    final methodSignatureStart =
        'Future<${spec.modelClassName}> ${spec.methodName}(';
    if (content.contains(methodSignatureStart)) {
      continue;
    }

    content = _insertClassMemberBeforeClosingBrace(
      content: content,
      className: remoteDataSourceClassName,
      memberContent: _remoteDataSourceMethodTemplate(spec),
      withBlankLine: true,
    );
  }

  remoteDataSourceFile.writeAsStringSync(content);
  logger.info('Updated remote data source: $remoteDataSourcePath');
}

String _remoteDataSourceMethodTemplate(_UsecaseSpec spec) {
  return '''
  Future<${spec.modelClassName}> ${spec.methodName}(${spec.paramsClassName} params) {
    return wrapHandlingApi(
      tryCall: () => ${_buildRemoteTryCall(spec)},
      jsonConvert: ${spec.modelFromJsonFunction},
    );
  }''';
}

String _buildRemoteTryCall(_UsecaseSpec spec) {
  final endpoint = _escapeSingleQuote(spec.endpoint);
  switch (spec.httpMethod) {
    case _HttpMethod.get:
      return "dioNetwork.getData(endPoint: '$endpoint', params: params.getParams(), data: params.getBody().isEmpty ? null : params.getBody())";
    case _HttpMethod.post:
      return "dioNetwork.postData(endPoint: '$endpoint', data: params.getBody(), params: params.getParams())";
    case _HttpMethod.put:
      return "dioNetwork.putData(endPoint: '$endpoint', data: params.getBody(), params: params.getParams())";
    case _HttpMethod.patch:
      return "dioNetwork.patchData(endPoint: '$endpoint', data: params.getBody(), params: params.getParams())";
    case _HttpMethod.delete:
      return "dioNetwork.deleteData(endPoint: '$endpoint', params: params.getParams(), data: params.getBody().isEmpty ? null : params.getBody())";
  }
}

void _updateRepoImplementation({
  required String root,
  required String featureName,
  required List<_UsecaseSpec> specs,
  required Logger logger,
}) {
  final repoImplPath =
      '$root/lib/features/$featureName/data/repository/${featureName}_repo_impl.dart';
  final repoImplFile = File(repoImplPath);
  if (!repoImplFile.existsSync()) {
    logger.warn(
        'Repo implementation file not found at $repoImplPath, skipping update.');
    return;
  }

  var content = repoImplFile.readAsStringSync();
  content = _ensureImportBySuffix(
    content: content,
    importLine: "import 'package:common_package/helpers/typedef.dart';",
    importPathSuffix: 'helpers/typedef.dart',
  );
  content = _ensureImportBySuffix(
    content: content,
    importLine: "import '../source/${featureName}_remote_data_source.dart';",
    importPathSuffix: 'data/source/${featureName}_remote_data_source.dart',
  );

  for (final spec in specs) {
    content = _ensureImportBySuffix(
      content: content,
      importLine:
          "import '../../domain/usecases/${spec.usecaseSnake}_use_case.dart';",
      importPathSuffix: 'domain/usecases/${spec.usecaseSnake}_use_case.dart',
    );
    final modelImportPath = _buildRelativeImportPath(
      root: root,
      fromFilePath: repoImplPath,
      toLibPath: spec.modelLibPath,
    );
    content = _ensureImportBySuffix(
      content: content,
      importLine: "import '$modelImportPath';",
      importPathSuffix: spec.modelImportSuffix,
    );
  }

  final featurePascal = _toPascalCase(featureName);
  final repoImplClassName = '${featurePascal}RepoImpl';
  final remoteDataSourceClassName = '${featurePascal}RemoteDataSource';
  final remoteDataSourceFieldName = _lowerFirst(remoteDataSourceClassName);
  final remoteDataSourceField =
      'final $remoteDataSourceClassName $remoteDataSourceFieldName;';
  final constructorDeclaration =
      '$repoImplClassName({required this.$remoteDataSourceFieldName});';

  content = _ensureClassMember(
    content: content,
    className: repoImplClassName,
    memberDeclaration: remoteDataSourceField,
  );
  content = _ensureClassMember(
    content: content,
    className: repoImplClassName,
    memberDeclaration: constructorDeclaration,
    afterMemberDeclaration: remoteDataSourceField,
    withBlankLine: true,
  );

  for (final spec in specs) {
    final returnType = 'DataResponse<${spec.modelClassName}>';
    final methodImpl = _repoImplementationMethodTemplate(
      spec: spec,
      remoteDataSourceFieldName: remoteDataSourceFieldName,
    );

    final classRegion = _findClassRegion(content, repoImplClassName);
    if (classRegion == null) {
      logger.warn(
        'Repo implementation class $repoImplClassName not found in $repoImplPath.',
      );
      break;
    }

    final existingMethodRegion = _findMethodRegion(
      content: content,
      classRegion: classRegion,
      returnType: returnType,
      methodName: spec.methodName,
      paramsClassName: spec.paramsClassName,
    );

    if (existingMethodRegion == null) {
      content = _insertClassMemberBeforeClosingBrace(
        content: content,
        className: repoImplClassName,
        memberContent: methodImpl,
        withBlankLine: true,
      );
      continue;
    }

    final existingMethod = content.substring(
      existingMethodRegion.start,
      existingMethodRegion.end,
    );
    if (!existingMethod.contains('throw UnimplementedError()')) {
      continue;
    }

    content = content.replaceRange(
      existingMethodRegion.start,
      existingMethodRegion.end,
      '$methodImpl\n',
    );
  }

  repoImplFile.writeAsStringSync(content);
  logger.info('Updated repo implementation: $repoImplPath');
}

String _repoImplementationMethodTemplate({
  required _UsecaseSpec spec,
  required String remoteDataSourceFieldName,
}) {
  return '''
  @override
  DataResponse<${spec.modelClassName}> ${spec.methodName}(${spec.paramsClassName} params) {
    return wrapHandlingException(
      tryCall: () => $remoteDataSourceFieldName.${spec.methodName}(params),
    );
  }''';
}

void _updateBlocFiles({
  required String root,
  required String featureName,
  required List<_UsecaseSpec> specs,
  required Logger logger,
}) {
  if (specs.isEmpty) {
    return;
  }

  final blocDirPath = '$root/lib/features/$featureName/view/manager/bloc';
  final blocPath = '$blocDirPath/${featureName}_bloc.dart';
  final eventPath = '$blocDirPath/${featureName}_event.dart';
  final statePath = '$blocDirPath/${featureName}_state.dart';

  _updateBlocEventFile(
    eventPath: eventPath,
    featureName: featureName,
    specs: specs,
    logger: logger,
  );
  _updateBlocStateFile(
    statePath: statePath,
    featureName: featureName,
    specs: specs,
    logger: logger,
  );
  _updateBlocFile(
    root: root,
    blocPath: blocPath,
    featureName: featureName,
    specs: specs,
    logger: logger,
  );
}

void _updateBlocEventFile({
  required String eventPath,
  required String featureName,
  required List<_UsecaseSpec> specs,
  required Logger logger,
}) {
  final eventFile = File(eventPath);
  if (!eventFile.existsSync()) {
    logger.warn('Bloc event file not found at $eventPath, skipping update.');
    return;
  }

  var content = eventFile.readAsStringSync();
  final featureEventClass = '${_toPascalCase(featureName)}Event';

  for (final spec in specs) {
    final eventClassPattern = RegExp(
      'class\\s+${RegExp.escape(spec.eventClassName)}\\b',
    );
    if (eventClassPattern.hasMatch(content)) {
      continue;
    }

    final template = _buildBlocEventTemplate(
      featureEventClass: featureEventClass,
      spec: spec,
    );
    content = _appendTopLevelBlock(content, template);
  }

  eventFile.writeAsStringSync(content);
  logger.info('Updated bloc events: $eventPath');
}

String _buildBlocEventTemplate({
  required String featureEventClass,
  required _UsecaseSpec spec,
}) {
  if (spec.responseKind == _ResponseKind.paginated) {
    return '''
class ${spec.eventClassName} extends $featureEventClass with EventWithReload {
  final ${spec.paramsClassName} params;

  @override
  final bool isReload;

  ${spec.eventClassName}({required this.params, this.isReload = false});
}''';
  }

  return '''
class ${spec.eventClassName} extends $featureEventClass {
  final ${spec.paramsClassName} params;

  ${spec.eventClassName}({required this.params});
}''';
}

void _updateBlocStateFile({
  required String statePath,
  required String featureName,
  required List<_UsecaseSpec> specs,
  required Logger logger,
}) {
  final stateFile = File(statePath);
  if (!stateFile.existsSync()) {
    logger.warn('Bloc state file not found at $statePath, skipping update.');
    return;
  }

  final stateClassName = '${_toPascalCase(featureName)}State';
  var content = stateFile.readAsStringSync();
  final classRegion = _findClassRegion(content, stateClassName);
  if (classRegion == null) {
    logger.warn(
      'Bloc state class $stateClassName not found in $statePath, skipping update.',
    );
    return;
  }

  final members = _buildStateMemberSpecs(specs);

  for (final member in members) {
    if (_classHasField(
      content: content,
      className: stateClassName,
      fieldName: member.fieldName,
    )) {
      continue;
    }
    content = _ensureClassMember(
      content: content,
      className: stateClassName,
      memberDeclaration: member.fieldDeclaration,
    );
  }

  content = _ensureStateConstructor(
    content: content,
    stateClassName: stateClassName,
    members: members,
  );
  content = _ensureStateCopyWith(
    content: content,
    stateClassName: stateClassName,
    members: members,
  );

  stateFile.writeAsStringSync(content);
  logger.info('Updated bloc state: $statePath');
}

List<_StateMemberSpec> _buildStateMemberSpecs(List<_UsecaseSpec> specs) {
  final membersByFieldName = <String, _StateMemberSpec>{};

  void addMember(_StateMemberSpec member) {
    membersByFieldName.putIfAbsent(member.fieldName, () => member);
  }

  addMember(
    _StateMemberSpec(
      fieldName: 'errorMessage',
      fieldDeclaration: 'String? errorMessage;',
      constructorParameter: 'this.errorMessage,',
      copyWithParameter: 'String? errorMessage,',
      copyWithAssignment: 'errorMessage: errorMessage ?? this.errorMessage,',
    ),
  );

  for (final spec in specs) {
    if (spec.responseKind == _ResponseKind.paginated) {
      final itemType = spec.paginatedItemType ?? 'dynamic';
      addMember(
        _StateMemberSpec(
          fieldName: spec.stateAlias,
          fieldDeclaration:
              'PaginationStateModel<$itemType>? ${spec.stateAlias};',
          constructorParameter:
              'this.${spec.stateAlias} = const PaginationStateModel(perPage: 10),',
          copyWithParameter:
              'PaginationStateModel<$itemType>? ${spec.stateAlias},',
          copyWithAssignment:
              '${spec.stateAlias}: ${spec.stateAlias} ?? this.${spec.stateAlias},',
        ),
      );
      continue;
    }

    addMember(
      _StateMemberSpec(
        fieldName: spec.stateAlias,
        fieldDeclaration: '${spec.modelClassName}? ${spec.stateAlias};',
        constructorParameter: 'this.${spec.stateAlias},',
        copyWithParameter: '${spec.modelClassName}? ${spec.stateAlias},',
        copyWithAssignment:
            '${spec.stateAlias}: ${spec.stateAlias} ?? this.${spec.stateAlias},',
      ),
    );
    addMember(
      _StateMemberSpec(
        fieldName: spec.statusAlias,
        fieldDeclaration: 'BlocStatus? ${spec.statusAlias};',
        constructorParameter: 'this.${spec.statusAlias},',
        copyWithParameter: 'BlocStatus? ${spec.statusAlias},',
        copyWithAssignment:
            '${spec.statusAlias}: ${spec.statusAlias} ?? this.${spec.statusAlias},',
      ),
    );
  }

  return membersByFieldName.values.toList();
}

String _ensureStateConstructor({
  required String content,
  required String stateClassName,
  required List<_StateMemberSpec> members,
}) {
  final classRegion = _findClassRegion(content, stateClassName);
  if (classRegion == null) {
    return content;
  }

  var constructorRegion = _findConstructorRegion(
    content: content,
    classRegion: classRegion,
    className: stateClassName,
  );

  if (constructorRegion == null) {
    return _insertClassMemberBeforeClosingBrace(
      content: content,
      className: stateClassName,
      memberContent: _buildStateConstructorTemplate(
        stateClassName: stateClassName,
        members: members,
      ),
      withBlankLine: true,
    );
  }

  for (final member in members) {
    constructorRegion = _findConstructorRegion(
      content: content,
      classRegion: _findClassRegion(content, stateClassName)!,
      className: stateClassName,
    );
    if (constructorRegion == null) {
      break;
    }
    final paramsText = content.substring(
      constructorRegion.paramsStart,
      constructorRegion.paramsEnd,
    );
    if (paramsText.contains('this.${member.fieldName}')) {
      continue;
    }

    final updatedParams = _insertNamedParameter(
      paramsText: paramsText,
      parameterLine: member.constructorParameter,
    );
    content = content.replaceRange(
      constructorRegion.paramsStart,
      constructorRegion.paramsEnd,
      updatedParams,
    );
  }

  return content;
}

String _buildStateConstructorTemplate({
  required String stateClassName,
  required List<_StateMemberSpec> members,
}) {
  final constructorLines =
      members.map((member) => '    ${member.constructorParameter}').join('\n');

  return '''
  $stateClassName({
$constructorLines
  });''';
}

String _ensureStateCopyWith({
  required String content,
  required String stateClassName,
  required List<_StateMemberSpec> members,
}) {
  final classRegion = _findClassRegion(content, stateClassName);
  if (classRegion == null) {
    return content;
  }

  var copyWithRegion = _findCopyWithRegion(
    content: content,
    classRegion: classRegion,
  );

  if (copyWithRegion == null) {
    return _insertClassMemberBeforeClosingBrace(
      content: content,
      className: stateClassName,
      memberContent: _buildStateCopyWithTemplate(
        stateClassName: stateClassName,
        members: members,
      ),
      withBlankLine: true,
    );
  }

  for (final member in members) {
    copyWithRegion = _findCopyWithRegion(
      content: content,
      classRegion: _findClassRegion(content, stateClassName)!,
    );
    if (copyWithRegion == null) {
      break;
    }

    final paramsText = content.substring(
      copyWithRegion.paramsStart,
      copyWithRegion.paramsEnd,
    );
    if (_containsParameterName(paramsText, member.fieldName)) {
      continue;
    }

    final updatedParams = _insertNamedParameter(
      paramsText: paramsText,
      parameterLine: member.copyWithParameter,
    );
    content = content.replaceRange(
      copyWithRegion.paramsStart,
      copyWithRegion.paramsEnd,
      updatedParams,
    );
  }

  for (final member in members) {
    copyWithRegion = _findCopyWithRegion(
      content: content,
      classRegion: _findClassRegion(content, stateClassName)!,
    );
    if (copyWithRegion == null) {
      break;
    }
    content = _ensureCopyWithAssignment(
      content: content,
      copyWithRegion: copyWithRegion,
      stateClassName: stateClassName,
      fieldName: member.fieldName,
      assignmentLine: member.copyWithAssignment,
    );
  }

  return content;
}

String _buildStateCopyWithTemplate({
  required String stateClassName,
  required List<_StateMemberSpec> members,
}) {
  final parameterLines =
      members.map((member) => '    ${member.copyWithParameter}').join('\n');
  final assignmentLines = members
      .map((member) => '        ${member.copyWithAssignment}')
      .join('\n');

  return '''
  $stateClassName copyWith({
$parameterLines
  }) =>
      $stateClassName(
$assignmentLines
      );''';
}

String _insertNamedParameter({
  required String paramsText,
  required String parameterLine,
}) {
  final openBraceIndex = paramsText.indexOf('{');
  final closeBraceIndex = paramsText.lastIndexOf('}');
  if (openBraceIndex == -1 ||
      closeBraceIndex == -1 ||
      openBraceIndex > closeBraceIndex) {
    final trimmed = paramsText.trimRight();
    if (trimmed.isEmpty) {
      return '{\n    $parameterLine\n  }';
    }
    final trailingComma = trimmed.endsWith(',') ? '' : ',';
    return '$trimmed$trailingComma\n    $parameterLine';
  }

  final beforeClose = paramsText.substring(0, closeBraceIndex).trimRight();
  final afterClose = paramsText.substring(closeBraceIndex);
  return '$beforeClose\n    $parameterLine\n  $afterClose';
}

bool _containsParameterName(String paramsText, String parameterName) {
  final pattern = RegExp('(^|\\W)${RegExp.escape(parameterName)}(\\W|\\\$)');
  return pattern.hasMatch(paramsText);
}

String _ensureCopyWithAssignment({
  required String content,
  required _CallableRegion copyWithRegion,
  required String stateClassName,
  required String fieldName,
  required String assignmentLine,
}) {
  final copyWithBody = content.substring(
    copyWithRegion.bodyStart,
    copyWithRegion.bodyEnd,
  );
  if (copyWithBody.contains('$fieldName:')) {
    return content;
  }

  final constructorCallMatch = RegExp(
    '${RegExp.escape(stateClassName)}\\s*\\(',
  ).firstMatch(copyWithBody);
  if (constructorCallMatch == null) {
    return content;
  }

  final constructorCallStart =
      copyWithRegion.bodyStart + constructorCallMatch.start;
  final constructorOpenParenIndex = content.indexOf('(', constructorCallStart);
  if (constructorOpenParenIndex == -1 ||
      constructorOpenParenIndex >= copyWithRegion.bodyEnd) {
    return content;
  }

  final constructorCloseParenIndex =
      _findMatchingParenthesis(content, constructorOpenParenIndex);
  if (constructorCloseParenIndex == -1 ||
      constructorCloseParenIndex > copyWithRegion.bodyEnd) {
    return content;
  }

  final constructorArgs = content.substring(
    constructorOpenParenIndex + 1,
    constructorCloseParenIndex,
  );
  if (constructorArgs.contains('$fieldName:')) {
    return content;
  }

  final updatedArgs = _insertConstructorArgument(
    argsText: constructorArgs,
    argumentLine: assignmentLine,
  );
  return content.replaceRange(
    constructorOpenParenIndex + 1,
    constructorCloseParenIndex,
    updatedArgs,
  );
}

String _insertConstructorArgument({
  required String argsText,
  required String argumentLine,
}) {
  final trimmed = argsText.trimRight();
  if (trimmed.isEmpty) {
    return '\n        $argumentLine\n      ';
  }
  return '$trimmed\n        $argumentLine';
}

void _updateBlocFile({
  required String root,
  required String blocPath,
  required String featureName,
  required List<_UsecaseSpec> specs,
  required Logger logger,
}) {
  final blocFile = File(blocPath);
  if (!blocFile.existsSync()) {
    logger.warn('Bloc file not found at $blocPath, skipping update.');
    return;
  }

  var content = blocFile.readAsStringSync();
  final featurePascal = _toPascalCase(featureName);
  final blocClassName = '${featurePascal}Bloc';
  final stateClassName = '${featurePascal}State';
  final hasPaginatedUsecases =
      specs.any((spec) => spec.responseKind == _ResponseKind.paginated);

  content = _ensureImportBySuffix(
    content: content,
    importLine: "import 'dart:async';",
    importPathSuffix: 'dart:async',
  );
  content = _ensureImportBySuffix(
    content: content,
    importLine: "import 'package:flutter_bloc/flutter_bloc.dart';",
    importPathSuffix: 'flutter_bloc/flutter_bloc.dart',
  );
  content = _ensureImportBySuffix(
    content: content,
    importLine: "import 'package:injectable/injectable.dart';",
    importPathSuffix: 'injectable/injectable.dart',
  );
  content = _ensureImportBySuffix(
    content: content,
    importLine:
        "import 'package:common_package/helpers/pagination_helper.dart';",
    importPathSuffix: 'helpers/pagination_helper.dart',
  );
  if (hasPaginatedUsecases) {
    content = _ensureImportBySuffix(
      content: content,
      importLine:
          "import 'package:common_package/helpers/droppable_helper.dart';",
      importPathSuffix: 'helpers/droppable_helper.dart',
    );
  }

  for (final spec in specs) {
    content = _ensureImportBySuffix(
      content: content,
      importLine:
          "import '../../../domain/usecases/${spec.usecaseSnake}_use_case.dart';",
      importPathSuffix: 'domain/usecases/${spec.usecaseSnake}_use_case.dart',
    );
    final modelImportPath = _buildRelativeImportPath(
      root: root,
      fromFilePath: blocPath,
      toLibPath: spec.modelLibPath,
    );
    content = _ensureImportBySuffix(
      content: content,
      importLine: "import '$modelImportPath';",
      importPathSuffix: spec.modelImportSuffix,
    );
  }

  content = _removeDefaultBlocTemplateRegistration(
    content: content,
    featurePascal: featurePascal,
  );

  final classRegion = _findClassRegion(content, blocClassName);
  if (classRegion == null) {
    logger.warn('Bloc class $blocClassName not found in $blocPath, skipping.');
    return;
  }

  for (final spec in specs) {
    if (_classHasField(
      content: content,
      className: blocClassName,
      fieldName: spec.usecaseFieldName,
    )) {
      continue;
    }
    content = _ensureClassMember(
      content: content,
      className: blocClassName,
      memberDeclaration:
          'final ${spec.usecasePascal}UseCase ${spec.usecaseFieldName};',
    );
  }

  content = _ensureBlocConstructor(
    content: content,
    blocClassName: blocClassName,
    stateClassName: stateClassName,
    specs: specs,
  );

  if (hasPaginatedUsecases) {
    content = _ensureDroppableHelperMethod(
      content: content,
      blocClassName: blocClassName,
    );
  }

  for (final spec in specs) {
    final handlerSignature = 'FutureOr<void> ${spec.handlerMethodName}(';
    if (content.contains(handlerSignature)) {
      continue;
    }

    content = _insertClassMemberBeforeClosingBrace(
      content: content,
      className: blocClassName,
      memberContent: _buildBlocHandlerTemplate(
        spec: spec,
        stateClassName: stateClassName,
      ),
      withBlankLine: true,
    );
  }

  blocFile.writeAsStringSync(content);
  logger.info('Updated bloc: $blocPath');
}

String _removeDefaultBlocTemplateRegistration({
  required String content,
  required String featurePascal,
}) {
  final placeholderPattern = RegExp(
    'on<${RegExp.escape(featurePascal)}Event>\\s*\\(\\s*\\(event,\\s*emit\\)\\s*\\{\\s*// TODO: implement event handler\\s*\\}\\s*\\);',
    dotAll: true,
  );
  return content.replaceAll(placeholderPattern, '');
}

String _ensureBlocConstructor({
  required String content,
  required String blocClassName,
  required String stateClassName,
  required List<_UsecaseSpec> specs,
}) {
  final classRegion = _findClassRegion(content, blocClassName);
  if (classRegion == null) {
    return content;
  }

  var constructorRegion = _findConstructorRegion(
    content: content,
    classRegion: classRegion,
    className: blocClassName,
  );

  if (constructorRegion == null) {
    return _insertClassMemberBeforeClosingBrace(
      content: content,
      className: blocClassName,
      memberContent: _buildBlocConstructorTemplate(
        blocClassName: blocClassName,
        stateClassName: stateClassName,
        specs: specs,
      ),
      withBlankLine: true,
    );
  }

  for (final spec in specs) {
    constructorRegion = _findConstructorRegion(
      content: content,
      classRegion: _findClassRegion(content, blocClassName)!,
      className: blocClassName,
    );
    if (constructorRegion == null) {
      break;
    }

    final paramsText = content.substring(
      constructorRegion.paramsStart,
      constructorRegion.paramsEnd,
    );
    final token = 'this.${spec.usecaseFieldName}';
    if (paramsText.contains(token)) {
      continue;
    }

    final isNamed = paramsText.contains('{') && paramsText.contains('}');
    final parameterLine = isNamed ? 'required $token,' : '$token,';
    final updatedParams = isNamed
        ? _insertNamedParameter(
            paramsText: paramsText,
            parameterLine: parameterLine,
          )
        : _insertPositionalParameter(
            paramsText: paramsText,
            parameterLine: parameterLine,
          );

    content = content.replaceRange(
      constructorRegion.paramsStart,
      constructorRegion.paramsEnd,
      updatedParams,
    );
  }

  for (final spec in specs) {
    content = _ensureBlocOnRegistration(
      content: content,
      blocClassName: blocClassName,
      registrationLine: _buildBlocOnRegistrationLine(spec),
      eventClassName: spec.eventClassName,
    );
  }

  return content;
}

String _buildBlocConstructorTemplate({
  required String blocClassName,
  required String stateClassName,
  required List<_UsecaseSpec> specs,
}) {
  final constructorParams =
      specs.map((spec) => '    this.${spec.usecaseFieldName},').join('\n');
  final registrations = specs
      .map((spec) => '    ${_buildBlocOnRegistrationLine(spec)}')
      .join('\n');

  return '''
  $blocClassName(
$constructorParams
  ) : super($stateClassName()) {
$registrations
  }''';
}

String _buildBlocOnRegistrationLine(_UsecaseSpec spec) {
  if (spec.responseKind == _ResponseKind.paginated) {
    return 'on<${spec.eventClassName}>(${spec.handlerMethodName}, transformer: droppableProMax());';
  }
  return 'on<${spec.eventClassName}>(${spec.handlerMethodName});';
}

String _ensureBlocOnRegistration({
  required String content,
  required String blocClassName,
  required String registrationLine,
  required String eventClassName,
}) {
  final classRegion = _findClassRegion(content, blocClassName);
  if (classRegion == null) {
    return content;
  }
  final constructorRegion = _findConstructorRegion(
    content: content,
    classRegion: classRegion,
    className: blocClassName,
  );
  if (constructorRegion == null) {
    return content;
  }

  final constructorBody = content.substring(
    constructorRegion.bodyStart,
    constructorRegion.bodyEnd,
  );
  if (constructorBody.contains('on<$eventClassName>(')) {
    return content;
  }

  return content.replaceRange(
    constructorRegion.bodyEnd,
    constructorRegion.bodyEnd,
    '\n    $registrationLine',
  );
}

String _insertPositionalParameter({
  required String paramsText,
  required String parameterLine,
}) {
  final trimmed = paramsText.trimRight();
  if (trimmed.isEmpty) {
    return '\n    $parameterLine\n  ';
  }
  final trailingComma = trimmed.endsWith(',') ? '' : ',';
  return '$trimmed$trailingComma\n    $parameterLine';
}

String _ensureDroppableHelperMethod({
  required String content,
  required String blocClassName,
}) {
  const signature =
      'EventTransformer<T> droppableProMax<T extends EventWithReload>()';
  if (content.contains(signature)) {
    return content;
  }

  return _insertClassMemberBeforeClosingBrace(
    content: content,
    className: blocClassName,
    memberContent: '''
  EventTransformer<T> droppableProMax<T extends EventWithReload>() {
    return (events, mapper) {
      return events.transform(ExhaustMapStreamTransformer(mapper));
    };
  }''',
    withBlankLine: true,
  );
}

String _buildBlocHandlerTemplate({
  required _UsecaseSpec spec,
  required String stateClassName,
}) {
  if (spec.responseKind == _ResponseKind.paginated) {
    return '''
  FutureOr<void> ${spec.handlerMethodName}(${spec.eventClassName} event, Emitter<$stateClassName> emit) async {
    if (!state.${spec.stateAlias}!.isEndPage || event.isReload) {
      emit(state.copyWith(
        ${spec.stateAlias}: state.${spec.stateAlias}!.setLoading(isReload: event.isReload),
      ));
      final res = await ${spec.usecaseFieldName}(event.params);
      res.fold((l) {
        emit(state.copyWith(
          ${spec.stateAlias}: state.${spec.stateAlias}!.setFaild(errorMessage: l.message),
          errorMessage: l.message,
        ));
      }, (r) {
        emit(state.copyWith(
          ${spec.stateAlias}: state.${spec.stateAlias}!.setSuccess(data: r.data!),
        ));
      });
    }
  }''';
  }

  return '''
  FutureOr<void> ${spec.handlerMethodName}(${spec.eventClassName} event, Emitter<$stateClassName> emit) async {
    emit(state.copyWith(${spec.statusAlias}: BlocStatus.loading));
    final res = await ${spec.usecaseFieldName}(event.params);
    res.fold((l) {
      emit(state.copyWith(
        ${spec.statusAlias}: BlocStatus.failed,
        errorMessage: l.message,
      ));
    }, (r) {
      emit(state.copyWith(
        ${spec.statusAlias}: BlocStatus.success,
        ${spec.stateAlias}: r,
      ));
    });
  }''';
}

String _appendTopLevelBlock(String content, String block) {
  final trimmedContent = content.trimRight();
  if (trimmedContent.isEmpty) {
    return '${block.trimRight()}\n';
  }
  return '$trimmedContent\n\n${block.trimRight()}\n';
}

_CallableRegion? _findConstructorRegion({
  required String content,
  required _ClassRegion classRegion,
  required String className,
}) {
  var searchStart = classRegion.openBraceIndex + 1;
  while (searchStart < classRegion.closeBraceIndex) {
    final constructorStart = content.indexOf('$className(', searchStart);
    if (constructorStart == -1 ||
        constructorStart > classRegion.closeBraceIndex) {
      return null;
    }

    final openParenIndex = content.indexOf('(', constructorStart);
    if (openParenIndex == -1 || openParenIndex > classRegion.closeBraceIndex) {
      return null;
    }

    final closeParenIndex = _findMatchingParenthesis(content, openParenIndex);
    if (closeParenIndex == -1 ||
        closeParenIndex > classRegion.closeBraceIndex) {
      return null;
    }

    final nextTokenIndex = _skipWhitespace(content, closeParenIndex + 1);
    if (nextTokenIndex >= classRegion.closeBraceIndex) {
      return null;
    }
    final nextToken = content[nextTokenIndex];
    if (nextToken != ':' && nextToken != '{') {
      searchStart = constructorStart + className.length;
      continue;
    }

    final openBraceIndex = content.indexOf('{', nextTokenIndex);
    if (openBraceIndex == -1 || openBraceIndex > classRegion.closeBraceIndex) {
      return null;
    }

    final closeBraceIndex = _findMatchingBrace(content, openBraceIndex);
    if (closeBraceIndex == -1 ||
        closeBraceIndex > classRegion.closeBraceIndex) {
      return null;
    }

    return _CallableRegion(
      start: constructorStart,
      paramsStart: openParenIndex + 1,
      paramsEnd: closeParenIndex,
      bodyStart: openBraceIndex + 1,
      bodyEnd: closeBraceIndex,
      end: closeBraceIndex + 1,
    );
  }

  return null;
}

_CallableRegion? _findCopyWithRegion({
  required String content,
  required _ClassRegion classRegion,
}) {
  var searchStart = classRegion.openBraceIndex + 1;
  while (searchStart < classRegion.closeBraceIndex) {
    final copyWithStart = content.indexOf('copyWith(', searchStart);
    if (copyWithStart == -1 || copyWithStart > classRegion.closeBraceIndex) {
      return null;
    }

    final openParenIndex = content.indexOf('(', copyWithStart);
    if (openParenIndex == -1 || openParenIndex > classRegion.closeBraceIndex) {
      return null;
    }

    final closeParenIndex = _findMatchingParenthesis(content, openParenIndex);
    if (closeParenIndex == -1 ||
        closeParenIndex > classRegion.closeBraceIndex) {
      return null;
    }

    final nextTokenIndex = _skipWhitespace(content, closeParenIndex + 1);
    if (nextTokenIndex >= classRegion.closeBraceIndex) {
      return null;
    }

    if (content.startsWith('=>', nextTokenIndex)) {
      final bodyStart = _skipWhitespace(content, nextTokenIndex + 2);
      final semicolonIndex = content.indexOf(';', bodyStart);
      if (semicolonIndex == -1 ||
          semicolonIndex > classRegion.closeBraceIndex) {
        return null;
      }
      return _CallableRegion(
        start: copyWithStart,
        paramsStart: openParenIndex + 1,
        paramsEnd: closeParenIndex,
        bodyStart: bodyStart,
        bodyEnd: semicolonIndex,
        end: semicolonIndex + 1,
      );
    }

    if (content[nextTokenIndex] == '{') {
      final openBraceIndex = nextTokenIndex;
      final closeBraceIndex = _findMatchingBrace(content, openBraceIndex);
      if (closeBraceIndex == -1 ||
          closeBraceIndex > classRegion.closeBraceIndex) {
        return null;
      }
      return _CallableRegion(
        start: copyWithStart,
        paramsStart: openParenIndex + 1,
        paramsEnd: closeParenIndex,
        bodyStart: openBraceIndex + 1,
        bodyEnd: closeBraceIndex,
        end: closeBraceIndex + 1,
      );
    }

    searchStart = copyWithStart + 'copyWith'.length;
  }

  return null;
}

int _skipWhitespace(String content, int index) {
  var cursor = index;
  while (cursor < content.length) {
    final char = content[cursor];
    if (char != ' ' && char != '\t' && char != '\r' && char != '\n') {
      break;
    }
    cursor++;
  }
  return cursor;
}

int _findMatchingParenthesis(String content, int openParenIndex) {
  var depth = 0;
  for (var i = openParenIndex; i < content.length; i++) {
    final char = content[i];
    if (char == '(') {
      depth++;
    } else if (char == ')') {
      depth--;
      if (depth == 0) {
        return i;
      }
    }
  }
  return -1;
}

String _ensureImport(String content, String importLine) {
  if (content.contains(importLine)) {
    return content;
  }

  final importPattern = RegExp(r'''^import\s+['"].*['"];''', multiLine: true);
  final matches = importPattern.allMatches(content).toList();
  if (matches.isEmpty) {
    return '$importLine\n$content';
  }

  final lastImport = matches.last;
  return content.replaceRange(
    lastImport.end,
    lastImport.end,
    '\n$importLine',
  );
}

String _ensureImportBySuffix({
  required String content,
  required String importLine,
  required String importPathSuffix,
}) {
  final suffix = importPathSuffix.trim();
  if (suffix.isEmpty) {
    return _ensureImport(content, importLine);
  }
  final normalizedSuffix = _normalizeImportPathForComparison(suffix);

  final importPattern =
      RegExp(r'''^import\s+['"]([^'"]+)['"];''', multiLine: true);
  for (final match in importPattern.allMatches(content)) {
    final existingImportPath = match.group(1)?.trim();
    if (existingImportPath == null || existingImportPath.isEmpty) {
      continue;
    }
    final normalizedExisting = _normalizeImportPathForComparison(
      existingImportPath,
    );
    final isSamePath =
        existingImportPath == suffix || normalizedExisting == normalizedSuffix;
    final isSameBySuffix = normalizedExisting.isNotEmpty &&
        normalizedSuffix.isNotEmpty &&
        (normalizedExisting.endsWith(normalizedSuffix) ||
            normalizedSuffix.endsWith(normalizedExisting));
    if (isSamePath || isSameBySuffix) {
      return content;
    }
  }

  return _ensureImport(content, importLine);
}

String _normalizeImportPathForComparison(String path) {
  var normalized = _toPosixPath(path.trim());
  if (normalized.startsWith('package:')) {
    final slashIndex = normalized.indexOf('/');
    if (slashIndex != -1 && slashIndex + 1 < normalized.length) {
      normalized = normalized.substring(slashIndex + 1);
    }
  }
  if (normalized.startsWith('lib/')) {
    normalized = normalized.substring(4);
  }
  while (normalized.startsWith('./')) {
    normalized = normalized.substring(2);
  }
  while (normalized.startsWith('../')) {
    normalized = normalized.substring(3);
  }
  return normalized;
}

String _ensureClassMember({
  required String content,
  required String className,
  required String memberDeclaration,
  String? afterMemberDeclaration,
  bool withBlankLine = false,
}) {
  final classRegion = _findClassRegion(content, className);
  if (classRegion == null) {
    return content;
  }

  final classBody = content.substring(
    classRegion.openBraceIndex + 1,
    classRegion.closeBraceIndex,
  );
  if (classBody.contains(memberDeclaration)) {
    return content;
  }

  var insertAt = classRegion.openBraceIndex + 1;
  if (afterMemberDeclaration != null) {
    final existingMemberIndex = content.indexOf(
      afterMemberDeclaration,
      classRegion.openBraceIndex,
    );
    if (existingMemberIndex != -1 &&
        existingMemberIndex < classRegion.closeBraceIndex) {
      insertAt = existingMemberIndex + afterMemberDeclaration.length;
    }
  }

  final prefix = withBlankLine ? '\n\n  ' : '\n  ';
  return content.replaceRange(insertAt, insertAt, '$prefix$memberDeclaration');
}

String _insertClassMemberBeforeClosingBrace({
  required String content,
  required String className,
  required String memberContent,
  bool withBlankLine = false,
}) {
  final classRegion = _findClassRegion(content, className);
  if (classRegion == null) {
    return content;
  }

  final prefix = withBlankLine ? '\n\n' : '\n';
  return content.replaceRange(
    classRegion.closeBraceIndex,
    classRegion.closeBraceIndex,
    '$prefix$memberContent',
  );
}

bool _classHasField({
  required String content,
  required String className,
  required String fieldName,
}) {
  final classRegion = _findClassRegion(content, className);
  if (classRegion == null) {
    return false;
  }

  final classBody = content.substring(
    classRegion.openBraceIndex + 1,
    classRegion.closeBraceIndex,
  );
  final fieldPattern = RegExp('\\b${RegExp.escape(fieldName)}\\s*;');
  return fieldPattern.hasMatch(classBody);
}

_ClassRegion? _findClassRegion(String content, String className) {
  final classPattern = RegExp(
    'class\\s+${RegExp.escape(className)}\\b[^\\{]*\\{',
  );
  final classMatch = classPattern.firstMatch(content);
  if (classMatch == null) {
    return null;
  }

  final openBraceIndex = content.indexOf('{', classMatch.start);
  if (openBraceIndex == -1) {
    return null;
  }

  final closeBraceIndex = _findMatchingBrace(content, openBraceIndex);
  if (closeBraceIndex == -1) {
    return null;
  }

  return _ClassRegion(
    openBraceIndex: openBraceIndex,
    closeBraceIndex: closeBraceIndex,
  );
}

int _findMatchingBrace(String content, int openBraceIndex) {
  var depth = 0;
  for (var i = openBraceIndex; i < content.length; i++) {
    final char = content[i];
    if (char == '{') {
      depth++;
    } else if (char == '}') {
      depth--;
      if (depth == 0) {
        return i;
      }
    }
  }
  return -1;
}

_MethodRegion? _findMethodRegion({
  required String content,
  required _ClassRegion classRegion,
  required String returnType,
  required String methodName,
  required String paramsClassName,
}) {
  final classBody = content.substring(
    classRegion.openBraceIndex + 1,
    classRegion.closeBraceIndex,
  );
  final signaturePattern = RegExp(
    '${RegExp.escape(returnType)}\\s+${RegExp.escape(methodName)}\\s*\\(\\s*${RegExp.escape(paramsClassName)}\\s+params\\s*\\)\\s*\\{',
  );
  final signatureMatch = signaturePattern.firstMatch(classBody);
  if (signatureMatch == null) {
    return null;
  }

  var start = classRegion.openBraceIndex + 1 + signatureMatch.start;
  final overrideIndex = content.lastIndexOf('@override', start);
  if (overrideIndex != -1) {
    final between = content.substring(overrideIndex + 9, start);
    if (between.trim().isEmpty) {
      start = overrideIndex;
      while (start > 0 && content[start - 1] != '\n') {
        start--;
      }
    }
  } else {
    while (start > 0 && content[start - 1] != '\n') {
      start--;
    }
  }

  final methodOpenBraceIndex = content.indexOf(
    '{',
    classRegion.openBraceIndex + 1 + signatureMatch.start,
  );
  if (methodOpenBraceIndex == -1) {
    return null;
  }
  final methodCloseBraceIndex =
      _findMatchingBrace(content, methodOpenBraceIndex);
  if (methodCloseBraceIndex == -1 ||
      methodCloseBraceIndex > classRegion.closeBraceIndex) {
    return null;
  }

  var end = methodCloseBraceIndex + 1;
  if (end < content.length && content[end] == '\r') {
    end++;
  }
  if (end < content.length && content[end] == '\n') {
    end++;
  }

  return _MethodRegion(start: start, end: end);
}

String _insertBeforeLastBrace(String content, String insertion) {
  final insertIndex = content.lastIndexOf('}');
  if (insertIndex == -1) {
    return '$content\n$insertion\n';
  }
  return content.replaceRange(insertIndex, insertIndex, '\n$insertion\n');
}

String _buildModelContentFromJson({
  required String rootClassName,
  required Map<String, dynamic> sampleJson,
}) {
  final classes = <_GeneratedClass>[];
  final usedClassNames = <String>{};
  final resolvedRootClassName = _reserveClassName(
    preferredName: _sanitizeClassName(rootClassName),
    usedClassNames: usedClassNames,
  );

  _buildClassDefinition(
    className: resolvedRootClassName,
    sampleMaps: [sampleJson],
    classes: classes,
    usedClassNames: usedClassNames,
  );

  final orderedClasses = classes.reversed.toList();
  final buffer = StringBuffer()
    ..writeln("import 'dart:convert';")
    ..writeln()
    ..writeln(_renderCommonModelParsers())
    ..writeln();

  for (final generatedClass in orderedClasses) {
    buffer
      ..writeln(_renderModelHelpers(generatedClass.className))
      ..writeln();
  }

  buffer.write(orderedClasses.map(_renderClass).join('\n\n'));
  return buffer.toString().trimRight();
}

void _buildClassDefinition({
  required String className,
  required List<Map<String, dynamic>> sampleMaps,
  required List<_GeneratedClass> classes,
  required Set<String> usedClassNames,
}) {
  final fields = <_GeneratedField>[];
  final usedFieldNames = <String>{};
  final normalizedSampleMaps =
      sampleMaps.isEmpty ? <Map<String, dynamic>>[{}] : sampleMaps;
  final orderedKeys = <String>[];
  final seenKeys = <String>{};
  for (final map in normalizedSampleMaps) {
    for (final key in map.keys) {
      final normalizedKey = key.toString();
      if (seenKeys.add(normalizedKey)) {
        orderedKeys.add(normalizedKey);
      }
    }
  }

  for (final jsonKey in orderedKeys) {
    final baseFieldName = _toFieldName(jsonKey);
    final fieldName = _reserveFieldName(baseFieldName, usedFieldNames);
    final fieldPascal = _toPascalCase(fieldName);
    final jsonAccessor = "json['${_escapeSingleQuote(jsonKey)}']";
    final observedValues = <dynamic>[];

    for (final map in normalizedSampleMaps) {
      if (map.containsKey(jsonKey)) {
        observedValues.add(map[jsonKey]);
      }
    }

    if (observedValues.isEmpty) {
      observedValues.add(null);
    }

    final result = _buildFieldValue(
      parentClassName: className,
      fieldPascalName: fieldPascal,
      fieldName: fieldName,
      jsonAccessor: jsonAccessor,
      observedValues: observedValues,
      classes: classes,
      usedClassNames: usedClassNames,
    );

    fields.add(
      _GeneratedField(
        jsonKey: jsonKey,
        fieldName: fieldName,
        fieldType: result.fieldType,
        fromJsonValue: result.fromJsonValue,
        toJsonValue: result.toJsonValue,
      ),
    );
  }

  classes.add(_GeneratedClass(className: className, fields: fields));
}

_GeneratedFieldValue _buildFieldValue({
  required String parentClassName,
  required String fieldPascalName,
  required String fieldName,
  required String jsonAccessor,
  required List<dynamic> observedValues,
  required List<_GeneratedClass> classes,
  required Set<String> usedClassNames,
}) {
  final nonNullKinds = _collectObservedKinds(observedValues);

  if (nonNullKinds.isEmpty) {
    return _GeneratedFieldValue(
      fieldType: 'dynamic',
      fromJsonValue: '_asDynamic($jsonAccessor)',
      toJsonValue: fieldName,
    );
  }

  final hasOnlyMap =
      nonNullKinds.length == 1 && nonNullKinds.contains(_ObservedValueKind.map);
  if (hasOnlyMap) {
    final nestedSamples = <Map<String, dynamic>>[];
    for (final value in observedValues) {
      final map = _toStringDynamicMap(value);
      if (map != null) {
        nestedSamples.add(map);
      }
    }
    if (nestedSamples.isEmpty) {
      return _GeneratedFieldValue(
        fieldType: 'dynamic',
        fromJsonValue: '_asDynamic($jsonAccessor)',
        toJsonValue: fieldName,
      );
    }

    final nestedClassName = _reserveClassName(
      preferredName: '$parentClassName$fieldPascalName',
      usedClassNames: usedClassNames,
    );

    _buildClassDefinition(
      className: nestedClassName,
      sampleMaps: nestedSamples,
      classes: classes,
      usedClassNames: usedClassNames,
    );

    return _GeneratedFieldValue(
      fieldType: '$nestedClassName?',
      fromJsonValue:
          '$jsonAccessor is Map ? $nestedClassName.fromJson(Map<String, dynamic>.from($jsonAccessor as Map)) : null',
      toJsonValue: '$fieldName?.toJson()',
    );
  }

  final hasOnlyList = nonNullKinds.length == 1 &&
      nonNullKinds.contains(_ObservedValueKind.list);
  if (hasOnlyList) {
    final observedLists = observedValues.whereType<List>().toList();
    return _buildListFieldValue(
      parentClassName: parentClassName,
      fieldPascalName: fieldPascalName,
      fieldName: fieldName,
      jsonAccessor: jsonAccessor,
      observedLists: observedLists,
      classes: classes,
      usedClassNames: usedClassNames,
    );
  }

  final hasOnlyString = nonNullKinds.length == 1 &&
      nonNullKinds.contains(_ObservedValueKind.string);
  if (hasOnlyString) {
    return _GeneratedFieldValue(
      fieldType: 'String?',
      fromJsonValue: '_asString($jsonAccessor)',
      toJsonValue: fieldName,
    );
  }

  final hasOnlyInt =
      nonNullKinds.length == 1 && nonNullKinds.contains(_ObservedValueKind.int);
  if (hasOnlyInt) {
    return _GeneratedFieldValue(
      fieldType: 'int?',
      fromJsonValue: '_asInt($jsonAccessor)',
      toJsonValue: fieldName,
    );
  }

  final hasOnlyDouble = nonNullKinds.length == 1 &&
      nonNullKinds.contains(_ObservedValueKind.doubleType);
  if (hasOnlyDouble) {
    return _GeneratedFieldValue(
      fieldType: 'double?',
      fromJsonValue: '_asDouble($jsonAccessor)',
      toJsonValue: fieldName,
    );
  }

  final hasOnlyBool = nonNullKinds.length == 1 &&
      nonNullKinds.contains(_ObservedValueKind.boolType);
  if (hasOnlyBool) {
    return _GeneratedFieldValue(
      fieldType: 'bool?',
      fromJsonValue: '_asBool($jsonAccessor)',
      toJsonValue: fieldName,
    );
  }

  final hasOnlyNum =
      nonNullKinds.length == 1 && nonNullKinds.contains(_ObservedValueKind.num);
  if (hasOnlyNum) {
    return _GeneratedFieldValue(
      fieldType: 'num?',
      fromJsonValue: '_asNum($jsonAccessor)',
      toJsonValue: fieldName,
    );
  }

  final numericKinds = <_ObservedValueKind>{
    _ObservedValueKind.int,
    _ObservedValueKind.doubleType,
    _ObservedValueKind.num,
  };
  final hasOnlyNumericKinds = nonNullKinds.every(numericKinds.contains);
  if (hasOnlyNumericKinds) {
    return _GeneratedFieldValue(
      fieldType: 'num?',
      fromJsonValue: '_asNum($jsonAccessor)',
      toJsonValue: fieldName,
    );
  }

  return _GeneratedFieldValue(
    fieldType: 'dynamic',
    fromJsonValue: '_asDynamic($jsonAccessor)',
    toJsonValue: fieldName,
  );
}

_GeneratedFieldValue _buildListFieldValue({
  required String parentClassName,
  required String fieldPascalName,
  required String fieldName,
  required String jsonAccessor,
  required List<List<dynamic>> observedLists,
  required List<_GeneratedClass> classes,
  required Set<String> usedClassNames,
}) {
  if (observedLists.isEmpty) {
    return _GeneratedFieldValue(
      fieldType: 'List<dynamic>?',
      fromJsonValue: '_asDynamicList($jsonAccessor)',
      toJsonValue: fieldName,
    );
  }

  final flattenedValues = <dynamic>[];
  for (final list in observedLists) {
    flattenedValues.addAll(list);
  }
  final nonNullKinds = _collectObservedKinds(flattenedValues);

  if (nonNullKinds.isEmpty) {
    return _GeneratedFieldValue(
      fieldType: 'List<dynamic>?',
      fromJsonValue: '_asDynamicList($jsonAccessor)',
      toJsonValue: fieldName,
    );
  }

  final hasOnlyMap =
      nonNullKinds.length == 1 && nonNullKinds.contains(_ObservedValueKind.map);
  if (hasOnlyMap) {
    final nestedSamples = <Map<String, dynamic>>[];
    for (final value in flattenedValues) {
      final map = _toStringDynamicMap(value);
      if (map != null) {
        nestedSamples.add(map);
      }
    }
    if (nestedSamples.isEmpty) {
      return _GeneratedFieldValue(
        fieldType: 'List<dynamic>?',
        fromJsonValue: '_asDynamicList($jsonAccessor)',
        toJsonValue: fieldName,
      );
    }

    final nestedClassName = _reserveClassName(
      preferredName: '$parentClassName${fieldPascalName}Item',
      usedClassNames: usedClassNames,
    );

    _buildClassDefinition(
      className: nestedClassName,
      sampleMaps: nestedSamples,
      classes: classes,
      usedClassNames: usedClassNames,
    );

    return _GeneratedFieldValue(
      fieldType: 'List<$nestedClassName>?',
      fromJsonValue:
          '$jsonAccessor is List ? ($jsonAccessor as List).whereType<Map>().map((item) => $nestedClassName.fromJson(Map<String, dynamic>.from(item))).toList() : null',
      toJsonValue: '$fieldName?.map((item) => item.toJson()).toList()',
    );
  }

  final hasOnlyString = nonNullKinds.length == 1 &&
      nonNullKinds.contains(_ObservedValueKind.string);
  if (hasOnlyString) {
    return _GeneratedFieldValue(
      fieldType: 'List<String>?',
      fromJsonValue:
          '$jsonAccessor is List ? ($jsonAccessor as List).map((item) => _asString(item)).whereType<String>().toList() : null',
      toJsonValue: fieldName,
    );
  }

  final hasOnlyInt =
      nonNullKinds.length == 1 && nonNullKinds.contains(_ObservedValueKind.int);
  if (hasOnlyInt) {
    return _GeneratedFieldValue(
      fieldType: 'List<int>?',
      fromJsonValue:
          '$jsonAccessor is List ? ($jsonAccessor as List).map((item) => _asInt(item)).whereType<int>().toList() : null',
      toJsonValue: fieldName,
    );
  }

  final hasOnlyDouble = nonNullKinds.length == 1 &&
      nonNullKinds.contains(_ObservedValueKind.doubleType);
  if (hasOnlyDouble) {
    return _GeneratedFieldValue(
      fieldType: 'List<double>?',
      fromJsonValue:
          '$jsonAccessor is List ? ($jsonAccessor as List).map((item) => _asDouble(item)).whereType<double>().toList() : null',
      toJsonValue: fieldName,
    );
  }

  final hasOnlyBool = nonNullKinds.length == 1 &&
      nonNullKinds.contains(_ObservedValueKind.boolType);
  if (hasOnlyBool) {
    return _GeneratedFieldValue(
      fieldType: 'List<bool>?',
      fromJsonValue:
          '$jsonAccessor is List ? ($jsonAccessor as List).map((item) => _asBool(item)).whereType<bool>().toList() : null',
      toJsonValue: fieldName,
    );
  }

  final numericKinds = <_ObservedValueKind>{
    _ObservedValueKind.int,
    _ObservedValueKind.doubleType,
    _ObservedValueKind.num,
  };
  final hasOnlyNumericKinds = nonNullKinds.every(numericKinds.contains);
  if (hasOnlyNumericKinds) {
    return _GeneratedFieldValue(
      fieldType: 'List<num>?',
      fromJsonValue:
          '$jsonAccessor is List ? ($jsonAccessor as List).map((item) => _asNum(item)).whereType<num>().toList() : null',
      toJsonValue: fieldName,
    );
  }

  return _GeneratedFieldValue(
    fieldType: 'List<dynamic>?',
    fromJsonValue: '_asDynamicList($jsonAccessor)',
    toJsonValue: fieldName,
  );
}

Set<_ObservedValueKind> _collectObservedKinds(Iterable<dynamic> values) {
  final kinds = <_ObservedValueKind>{};
  for (final value in values) {
    if (value == null) continue;
    kinds.add(_detectObservedKind(value));
  }
  return kinds;
}

_ObservedValueKind _detectObservedKind(dynamic value) {
  if (value is Map) return _ObservedValueKind.map;
  if (value is List) return _ObservedValueKind.list;
  if (value is String) return _ObservedValueKind.string;
  if (value is bool) return _ObservedValueKind.boolType;
  if (value is int) return _ObservedValueKind.int;
  if (value is double) return _ObservedValueKind.doubleType;
  if (value is num) return _ObservedValueKind.num;
  return _ObservedValueKind.other;
}

Map<String, dynamic>? _toStringDynamicMap(dynamic value) {
  if (value is! Map) return null;
  return value.map((key, dynamic nestedValue) => MapEntry('$key', nestedValue));
}

String _renderClass(_GeneratedClass generatedClass) {
  final fields = generatedClass.fields;
  final buffer = StringBuffer();

  buffer.writeln('class ${generatedClass.className} {');
  for (final field in fields) {
    buffer.writeln('  ${field.fieldType} ${field.fieldName};');
  }
  buffer.writeln();

  if (fields.isEmpty) {
    buffer.writeln('  ${generatedClass.className}();');
  } else {
    buffer.writeln('  ${generatedClass.className}({');
    for (final field in fields) {
      buffer.writeln('    this.${field.fieldName},');
    }
    buffer.writeln('  });');
  }

  buffer.writeln();
  buffer.writeln(
    '  factory ${generatedClass.className}.fromJson(Map<String, dynamic> json) {',
  );
  if (fields.isEmpty) {
    buffer.writeln('    return ${generatedClass.className}();');
  } else {
    buffer.writeln('    return ${generatedClass.className}(');
    for (final field in fields) {
      buffer.writeln('      ${field.fieldName}: ${field.fromJsonValue},');
    }
    buffer.writeln('    );');
  }
  buffer.writeln('  }');

  buffer.writeln();
  buffer.writeln('  Map<String, dynamic> toJson() {');
  if (fields.isEmpty) {
    buffer.writeln('    return {};');
  } else {
    buffer.writeln('    return {');
    for (final field in fields) {
      buffer.writeln(
        "      '${_escapeSingleQuote(field.jsonKey)}': ${field.toJsonValue},",
      );
    }
    buffer.writeln('    };');
  }
  buffer.writeln('  }');
  buffer.writeln('}');

  return buffer.toString().trimRight();
}

String _renderCommonModelParsers() {
  return '''
String? _asString(dynamic value) {
  if (value == null) return null;
  if (value is String) return value;
  if (value is num || value is bool) return value.toString();
  return null;
}

int? _asInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) {
    return int.tryParse(value) ?? double.tryParse(value)?.toInt();
  }
  return null;
}

double? _asDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

num? _asNum(dynamic value) {
  if (value == null) return null;
  if (value is num) return value;
  if (value is String) return num.tryParse(value);
  return null;
}

bool? _asBool(dynamic value) {
  if (value == null) return null;
  if (value is bool) return value;
  if (value is num) {
    if (value == 1) return true;
    if (value == 0) return false;
  }
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true' || normalized == '1') return true;
    if (normalized == 'false' || normalized == '0') return false;
  }
  return null;
}

List<dynamic>? _asDynamicList(dynamic value) {
  if (value is! List) return null;
  return value.map(_asDynamic).toList();
}

dynamic _asDynamic(dynamic value) {
  if (value == null) return null;
  if (value is List) {
    return value.map(_asDynamic).toList();
  }
  if (value is Map) {
    final map = <String, dynamic>{};
    value.forEach((key, nestedValue) {
      map['\$key'] = _asDynamic(nestedValue);
    });
    return map;
  }
  if (value is String || value is num || value is bool) {
    return value;
  }
  return value.toString();
}''';
}

String _renderModelHelpers(String className) {
  final modelNameCamel = _lowerFirst(className);
  return '''
$className ${modelNameCamel}FromJson(str) => $className.fromJson(str);

String ${modelNameCamel}ToJson($className data) => json.encode(data.toJson());
''';
}

String _toFieldName(String input) {
  final parts = input
      .replaceAll(RegExp(r'[^A-Za-z0-9]+'), ' ')
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();

  if (parts.isEmpty) {
    return 'value';
  }

  final first = parts.first;
  final buffer = StringBuffer()
    ..write(first[0].toLowerCase())
    ..write(first.substring(1));

  for (var i = 1; i < parts.length; i++) {
    final part = parts[i];
    buffer
      ..write(part[0].toUpperCase())
      ..write(part.substring(1));
  }

  var value = buffer.toString();
  if (RegExp(r'^\d').hasMatch(value)) {
    value = 'field$value';
  }
  if (_dartReservedWords.contains(value)) {
    value = '${value}Value';
  }
  return value;
}

String _reserveFieldName(String baseName, Set<String> usedFieldNames) {
  if (!usedFieldNames.contains(baseName)) {
    usedFieldNames.add(baseName);
    return baseName;
  }

  var index = 2;
  while (usedFieldNames.contains('$baseName$index')) {
    index++;
  }
  final resolved = '$baseName$index';
  usedFieldNames.add(resolved);
  return resolved;
}

String _reserveClassName({
  required String preferredName,
  required Set<String> usedClassNames,
}) {
  final safePreferredName =
      preferredName.isEmpty ? 'GeneratedModel' : preferredName;
  if (!usedClassNames.contains(safePreferredName)) {
    usedClassNames.add(safePreferredName);
    return safePreferredName;
  }

  var index = 2;
  while (usedClassNames.contains('$safePreferredName$index')) {
    index++;
  }
  final resolved = '$safePreferredName$index';
  usedClassNames.add(resolved);
  return resolved;
}

String _escapeSingleQuote(String value) {
  return value.replaceAll(r'\', r'\\').replaceAll("'", r"\'");
}

enum _HttpMethod {
  get('GET'),
  post('POST'),
  put('PUT'),
  patch('PATCH'),
  delete('DELETE');

  const _HttpMethod(this.value);
  final String value;
}

enum _ResponseKind {
  paginated('paginated'),
  normal('normal');

  const _ResponseKind(this.value);
  final String value;
}

class _UsecaseRequestConfig {
  _UsecaseRequestConfig({
    required this.httpMethod,
    required this.endpoint,
  });

  final _HttpMethod httpMethod;
  final String endpoint;
}

class _UsecaseSpec {
  _UsecaseSpec({
    required this.usecaseName,
    required this.modelClassName,
    required this.modelFileName,
    required this.modelLibPath,
    required this.httpMethod,
    required this.endpoint,
    required this.responseKind,
    required this.stateAlias,
    this.paginatedItemType,
    this.sampleJson,
  });

  final String usecaseName;
  final String modelClassName;
  final String modelFileName;
  final String modelLibPath;
  final _HttpMethod httpMethod;
  final String endpoint;
  final _ResponseKind responseKind;
  final String stateAlias;
  final String? paginatedItemType;
  final Map<String, dynamic>? sampleJson;

  String get usecasePascal => _toPascalCase(usecaseName);
  String get usecaseSnake => _toSnakeCase(usecaseName);
  String get methodName => _lowerFirst(usecasePascal);
  String get paramsClassName => '${usecasePascal}Params';
  String get modelFromJsonFunction => '${_lowerFirst(modelClassName)}FromJson';
  String get modelImportSuffix => modelLibPath;
  String get usecaseFieldName => '${methodName}UseCase';
  String get eventClassName => '${usecasePascal}Event';
  String get handlerMethodName => '_$methodName';
  String get statusAlias => '${stateAlias}Status';

  _UsecaseSpec copyWith({
    String? usecaseName,
    String? modelClassName,
    String? modelFileName,
    String? modelLibPath,
    _HttpMethod? httpMethod,
    String? endpoint,
    _ResponseKind? responseKind,
    String? stateAlias,
    String? paginatedItemType,
    Map<String, dynamic>? sampleJson,
  }) {
    return _UsecaseSpec(
      usecaseName: usecaseName ?? this.usecaseName,
      modelClassName: modelClassName ?? this.modelClassName,
      modelFileName: modelFileName ?? this.modelFileName,
      modelLibPath: modelLibPath ?? this.modelLibPath,
      httpMethod: httpMethod ?? this.httpMethod,
      endpoint: endpoint ?? this.endpoint,
      responseKind: responseKind ?? this.responseKind,
      stateAlias: stateAlias ?? this.stateAlias,
      paginatedItemType: paginatedItemType ?? this.paginatedItemType,
      sampleJson: sampleJson ?? this.sampleJson,
    );
  }
}

class _ClassRegion {
  _ClassRegion({
    required this.openBraceIndex,
    required this.closeBraceIndex,
  });

  final int openBraceIndex;
  final int closeBraceIndex;
}

class _MethodRegion {
  _MethodRegion({
    required this.start,
    required this.end,
  });

  final int start;
  final int end;
}

class _CallableRegion {
  _CallableRegion({
    required this.start,
    required this.paramsStart,
    required this.paramsEnd,
    required this.bodyStart,
    required this.bodyEnd,
    required this.end,
  });

  final int start;
  final int paramsStart;
  final int paramsEnd;
  final int bodyStart;
  final int bodyEnd;
  final int end;
}

class _StateMemberSpec {
  _StateMemberSpec({
    required this.fieldName,
    required this.fieldDeclaration,
    required this.constructorParameter,
    required this.copyWithParameter,
    required this.copyWithAssignment,
  });

  final String fieldName;
  final String fieldDeclaration;
  final String constructorParameter;
  final String copyWithParameter;
  final String copyWithAssignment;
}

class _GeneratedClass {
  _GeneratedClass({
    required this.className,
    required this.fields,
  });

  final String className;
  final List<_GeneratedField> fields;
}

class _GeneratedField {
  _GeneratedField({
    required this.jsonKey,
    required this.fieldName,
    required this.fieldType,
    required this.fromJsonValue,
    required this.toJsonValue,
  });

  final String jsonKey;
  final String fieldName;
  final String fieldType;
  final String fromJsonValue;
  final String toJsonValue;
}

class _GeneratedFieldValue {
  _GeneratedFieldValue({
    required this.fieldType,
    required this.fromJsonValue,
    required this.toJsonValue,
  });

  final String fieldType;
  final String fromJsonValue;
  final String toJsonValue;
}

enum _ObservedValueKind {
  map,
  list,
  string,
  int,
  doubleType,
  boolType,
  num,
  other,
}

const _dartReservedWords = <String>{
  'abstract',
  'as',
  'assert',
  'async',
  'await',
  'break',
  'case',
  'catch',
  'class',
  'const',
  'continue',
  'covariant',
  'default',
  'deferred',
  'do',
  'dynamic',
  'else',
  'enum',
  'export',
  'extends',
  'extension',
  'external',
  'factory',
  'false',
  'final',
  'finally',
  'for',
  'Function',
  'get',
  'hide',
  'if',
  'implements',
  'import',
  'in',
  'interface',
  'is',
  'late',
  'library',
  'mixin',
  'new',
  'null',
  'on',
  'operator',
  'part',
  'required',
  'rethrow',
  'return',
  'set',
  'show',
  'static',
  'super',
  'switch',
  'sync',
  'this',
  'throw',
  'true',
  'try',
  'typedef',
  'var',
  'void',
  'while',
  'with',
  'yield',
};

const _stateAliasVerbPrefixes = <String>{
  'fetch',
  'get',
  'load',
  'read',
  'create',
  'update',
  'delete',
  'post',
};
