class ApiQueryResult {
  final List<String> errors;
  final DateTime? timestamp;
  final String? code;

  ApiQueryResult(String errorMessage)
      : errors = _extractErrors(errorMessage),
        timestamp = _extractTimestamp(errorMessage),
        code = _extractCode(errorMessage);

  static List<String> _extractErrors(String errorMessage) {
    final matches = RegExp(r'errors: \[(.*?)\]').firstMatch(errorMessage);
    final errorString = matches?.group(1) ?? '';
    return RegExp(r'message: (.*?),').allMatches(errorString).map((m) => m.group(1) ?? '').toList();
  }

  static DateTime? _extractTimestamp(String errorMessage) {
    final pattern = RegExp(r'timestamp: (\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}.\d{3})');
    final match = pattern.firstMatch(errorMessage);
    if (match == null) {
      return null;
    }
    return DateTime.parse(match.group(1)!);
  }

  static String? _extractCode(String errorMessage) {
    final pattern = RegExp(r'code: (\w+)');
    final match = pattern.firstMatch(errorMessage);
    if (match == null) {
      return null;
    }
    return match.group(1);
  }
}
