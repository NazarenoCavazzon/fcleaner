import 'dart:io';

import 'package:fcleaner/cleanup/data/cleanup_service.dart';
import 'package:fcleaner/cleanup/data/macos_cleanup_datasource.dart';
import 'package:fcleaner/disk_analyzer/data/disk_analyzer_service.dart';
import 'package:fcleaner/disk_analyzer/data/macos_disk_datasource.dart';
import 'package:fcleaner/shared/exceptions/cleanup_exceptions.dart';
import 'package:fcleaner/shared/services/file_system_service.dart';
import 'package:fcleaner/shared/services/system_command_service.dart';
import 'package:fcleaner/shared/services/whitelist_service.dart';
import 'package:fcleaner/uninstall/data/macos_uninstall_datasource.dart';
import 'package:fcleaner/uninstall/data/uninstall_service.dart';

class ServiceProvider {
  factory ServiceProvider() => _instance;

  ServiceProvider._internal();

  static final ServiceProvider _instance = ServiceProvider._internal();

  late final FileSystemService fileSystemService;
  late final SystemCommandService systemCommandService;
  late final WhitelistService whitelistService;

  late final CleanupService cleanupService;
  late final UninstallService uninstallService;
  late final DiskAnalyzerService diskAnalyzerService;

  bool _initialized = false;

  void initialize() {
    if (_initialized) {
      return;
    }

    if (!Platform.isMacOS) {
      throw UnsupportedPlatformException(Platform.operatingSystem);
    }

    fileSystemService = FileSystemService();
    systemCommandService = SystemCommandService();
    whitelistService = WhitelistService();

    final cleanupDatasource = MacOSCleanupDatasource(
      fileSystemService,
      whitelistService,
      systemCommandService,
    );

    cleanupService = CleanupService(
      cleanupDatasource,
      whitelistService,
      systemCommandService,
    );

    final uninstallDatasource = MacOSUninstallDatasource(
      fileSystemService,
      systemCommandService,
    );

    uninstallService = UninstallService(uninstallDatasource);

    final diskDatasource = MacOSDiskDatasource(fileSystemService);

    diskAnalyzerService = DiskAnalyzerService(diskDatasource);

    _initialized = true;
  }

  void reset() {
    _initialized = false;
    initialize();
  }
}
