class UninstallResult {
  const UninstallResult({
    required this.appName,
    required this.success,
    required this.bytesFreed,
    required this.filesRemoved,
    required this.errors,
  });

  factory UninstallResult.failure(String appName, String error) {
    return UninstallResult(
      appName: appName,
      success: false,
      bytesFreed: 0,
      filesRemoved: 0,
      errors: [error],
    );
  }

  final String appName;
  final bool success;
  final int bytesFreed;
  final int filesRemoved;
  final List<String> errors;

  bool get hasErrors => errors.isNotEmpty;

  bool get isPartialSuccess => filesRemoved > 0 && hasErrors;

  UninstallResult copyWith({
    String? appName,
    bool? success,
    int? bytesFreed,
    int? filesRemoved,
    List<String>? errors,
  }) {
    return UninstallResult(
      appName: appName ?? this.appName,
      success: success ?? this.success,
      bytesFreed: bytesFreed ?? this.bytesFreed,
      filesRemoved: filesRemoved ?? this.filesRemoved,
      errors: errors ?? this.errors,
    );
  }
}
