class AnalyzerException implements Exception {
  AnalyzerException(
    this.message, {
    this.originalError,
    this.stackTrace,
  });

  final String message;
  final dynamic originalError;
  final StackTrace? stackTrace;

  @override
  String toString() => 'AnalyzerException: $message';
}
