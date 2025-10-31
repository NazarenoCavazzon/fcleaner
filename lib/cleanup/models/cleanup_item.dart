class CleanupItem {
  const CleanupItem({
    required this.path,
    required this.name,
    required this.sizeBytes,
    required this.lastModified,
    required this.isWhitelisted,
  });

  final String path;
  final String name;
  final int sizeBytes;
  final DateTime lastModified;
  final bool isWhitelisted;

  CleanupItem copyWith({
    String? path,
    String? name,
    int? sizeBytes,
    DateTime? lastModified,
    bool? isWhitelisted,
  }) {
    return CleanupItem(
      path: path ?? this.path,
      name: name ?? this.name,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      lastModified: lastModified ?? this.lastModified,
      isWhitelisted: isWhitelisted ?? this.isWhitelisted,
    );
  }
}
