extension StringExtensions on String {
  String toUpper() => toUpperCase();

  String toLower() => toLowerCase();

  String toCamelCase() {
    return split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  String toPascalCase() {
    return split(RegExp(r'[\s_-]+')).map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join('');
  }

  String toSnakeCase() {
    return replaceAll(RegExp(r'\s+'), '_').toLowerCase();
  }

  String toKebabCase() {
    return replaceAll(RegExp(r'\s+'), '-').toLowerCase();
  }

  String toSentenceCase() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1).toLowerCase();
  }

  bool containsNumbers() {
    return contains(RegExp(r'\d'));
  }
}