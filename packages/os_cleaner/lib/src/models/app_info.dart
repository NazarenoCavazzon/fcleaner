import 'package:os_cleaner/src/core/core.dart';

class AppInfo {
  const AppInfo({
    required this.name,
    required this.bundleId,
    required this.appPath,
    required this.totalSize,
    required this.relatedPaths,
    this.installDate,
  });

  final String name;
  final String bundleId;
  final String appPath;
  final int totalSize;
  final DateTime? installDate;
  final List<String> relatedPaths;

  String get displaySize => ByteFormatter.format(totalSize);

  int get relatedFilesCount => relatedPaths.length;

  bool get hasRelatedFiles => relatedPaths.isNotEmpty;

  AppInfo copyWith({
    String? name,
    String? bundleId,
    String? appPath,
    int? totalSize,
    DateTime? installDate,
    List<String>? relatedPaths,
  }) {
    return AppInfo(
      name: name ?? this.name,
      bundleId: bundleId ?? this.bundleId,
      appPath: appPath ?? this.appPath,
      totalSize: totalSize ?? this.totalSize,
      installDate: installDate ?? this.installDate,
      relatedPaths: relatedPaths ?? this.relatedPaths,
    );
  }
}
