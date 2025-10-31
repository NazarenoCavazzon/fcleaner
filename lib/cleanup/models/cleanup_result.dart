class CleanupResult {
  const CleanupResult({
    required this.success,
    required this.bytesFreed,
    required this.itemsCleaned,
    required this.duration,
    required this.errors,
  });

  factory CleanupResult.failure(String error) {
    return CleanupResult(
      success: false,
      bytesFreed: 0,
      itemsCleaned: 0,
      duration: Duration.zero,
      errors: [error],
    );
  }

  factory CleanupResult.empty() {
    return const CleanupResult(
      success: true,
      bytesFreed: 0,
      itemsCleaned: 0,
      duration: Duration.zero,
      errors: [],
    );
  }
  final bool success;
  final int bytesFreed;
  final int itemsCleaned;
  final Duration duration;
  final List<String> errors;

  bool get hasErrors => errors.isNotEmpty;

  bool get isPartialSuccess => itemsCleaned > 0 && hasErrors;

  CleanupResult copyWith({
    bool? success,
    int? bytesFreed,
    int? itemsCleaned,
    Duration? duration,
    List<String>? errors,
  }) {
    return CleanupResult(
      success: success ?? this.success,
      bytesFreed: bytesFreed ?? this.bytesFreed,
      itemsCleaned: itemsCleaned ?? this.itemsCleaned,
      duration: duration ?? this.duration,
      errors: errors ?? this.errors,
    );
  }
}
