class SystemInfo {
  const SystemInfo({
    required this.osVersion,
    required this.architecture,
    required this.homeDirectory,
    required this.totalDiskSpace,
    required this.freeDiskSpace,
  });

  final String osVersion;
  final String architecture;
  final String homeDirectory;
  final int totalDiskSpace;
  final int freeDiskSpace;

  double get diskUsagePercentage => totalDiskSpace > 0
      ? (totalDiskSpace - freeDiskSpace) / totalDiskSpace
      : 0;

  bool get isAppleSilicon => architecture == 'arm64';
}
