import 'dart:io';
import 'package:fcleaner/shared/services/file_system_service.dart';
import 'package:fcleaner/shared/services/system_command_service.dart';
import 'package:fcleaner/uninstall/models/app_info.dart';

class MacOSUninstallDatasource {
  MacOSUninstallDatasource(
    this._fileSystemService,
    this._systemCommandService,
  ) {
    _homeDir = Platform.environment['HOME'] ?? '';
  }

  final FileSystemService _fileSystemService;
  final SystemCommandService _systemCommandService;
  late final String _homeDir;

  Future<List<AppInfo>> scanInstalledApps() async {
    final apps = <AppInfo>[];
    final appLocations = [
      '/Applications',
      '$_homeDir/Applications',
    ];

    for (final location in appLocations) {
      try {
        final dir = Directory(location);
        if (!dir.existsSync()) continue;

        for (final entity in dir.listSync(followLinks: false)) {
          if (entity.path.endsWith('.app')) {
            final appInfo = await _getAppInfo(entity.path);
            if (appInfo != null) {
              apps.add(appInfo);
            }
          }
        }
      } catch (_) {}
    }

    apps.sort((a, b) => b.totalSize.compareTo(a.totalSize));

    return apps;
  }

  Future<AppInfo?> _getAppInfo(String appPath) async {
    try {
      final plistPath = '$appPath/Contents/Info.plist';
      final plistFile = File(plistPath);

      if (!plistFile.existsSync()) {
        return null;
      }

      final bundleIdResult = await _systemCommandService.run(
        'defaults',
        ['read', plistPath, 'CFBundleIdentifier'],
      );

      if (bundleIdResult.exitCode != 0) {
        return null;
      }

      final bundleId = bundleIdResult.stdout.toString().trim();
      if (bundleId.isEmpty) {
        return null;
      }

      final nameResult = await _systemCommandService.run(
        'defaults',
        ['read', plistPath, 'CFBundleName'],
      );

      final name = nameResult.exitCode == 0
          ? nameResult.stdout.toString().trim()
          : _fileSystemService.getFileName(appPath).replaceAll('.app', '');

      final relatedPaths = await findRelatedFiles(bundleId);

      final appSize = await _fileSystemService.calculateSize(appPath);
      var relatedSize = 0;
      for (final path in relatedPaths) {
        relatedSize += await _fileSystemService.calculateSize(path);
      }

      DateTime? installDate;
      try {
        final stat = File(appPath).statSync();
        installDate = stat.modified;
      } catch (_) {}

      return AppInfo(
        name: name,
        bundleId: bundleId,
        appPath: appPath,
        totalSize: appSize + relatedSize,
        installDate: installDate,
        relatedPaths: relatedPaths,
      );
    } catch (_) {
      return null;
    }
  }

  Future<List<String>> findRelatedFiles(String bundleId) async {
    final relatedPaths = <String>[];

    final searchLocations = [
      '$_homeDir/Library/Preferences',
      '$_homeDir/Library/Application Support',
      '$_homeDir/Library/Caches',
      '$_homeDir/Library/Logs',
      '$_homeDir/Library/WebKit',
      '$_homeDir/Library/HTTPStorages',
      '$_homeDir/Library/Cookies',
      '$_homeDir/Library/Saved Application State',
      '$_homeDir/Library/Containers',
      '$_homeDir/Library/Group Containers',
      '$_homeDir/Library/LaunchAgents',
      '$_homeDir/Library/Application Scripts',
      '$_homeDir/Library/Preferences/ByHost',
      '$_homeDir/Library/Internet Plug-Ins',
      '$_homeDir/Library/Services',
      '$_homeDir/Library/QuickLook',
      '$_homeDir/Library/Screen Savers',
      '$_homeDir/Library/Spotlight',
      '$_homeDir/Library/Mail/V*',
    ];

    for (final location in searchLocations) {
      try {
        final pattern = '$location/$bundleId*';
        final files = await _fileSystemService.findFiles(pattern);
        relatedPaths.addAll(files);
      } catch (_) {}
    }

    final plistPattern = '$_homeDir/Library/Preferences/$bundleId.plist';
    if (_fileSystemService.exists(plistPattern)) {
      relatedPaths.add(plistPattern);
    }

    return relatedPaths.toSet().toList();
  }

  Future<void> uninstallApp(
    AppInfo app, {
    void Function(String)? onProgress,
  }) async {
    onProgress?.call('Moving ${app.name} to Trash...');
    await _moveToTrash(app.appPath);

    for (final path in app.relatedPaths) {
      try {
        onProgress?.call('Removing ${_fileSystemService.getFileName(path)}...');
        await _fileSystemService.delete(path);
      } catch (_) {}
    }
  }

  Future<void> _moveToTrash(String path) async {
    try {
      final result = await _systemCommandService.run(
        'osascript',
        [
          '-e',
          'tell application "Finder" to move POSIX file "$path" to trash',
        ],
      );

      if (result.exitCode != 0) {
        final trashDir = Directory('$_homeDir/.Trash');
        if (!trashDir.existsSync()) {
          await trashDir.create();
        }

        final fileName = _fileSystemService.getFileName(path);
        final destination = '${trashDir.path}/$fileName';

        final entity = FileSystemEntity.typeSync(path);
        if (entity == FileSystemEntityType.file) {
          await File(path).rename(destination);
        } else if (entity == FileSystemEntityType.directory) {
          await Directory(path).rename(destination);
        }
      }
    } catch (_) {
      await _fileSystemService.delete(path);
    }
  }
}
