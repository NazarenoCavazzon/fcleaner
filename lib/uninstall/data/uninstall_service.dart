import 'package:fcleaner/uninstall/data/macos_uninstall_datasource.dart';
import 'package:fcleaner/uninstall/models/app_info.dart';
import 'package:fcleaner/uninstall/models/uninstall_result.dart';

class UninstallService {
  UninstallService(this._datasource);

  final MacOSUninstallDatasource _datasource;

  Future<List<AppInfo>> getInstalledApps() async {
    return _datasource.scanInstalledApps();
  }

  Stream<UninstallProgress> uninstallApp(AppInfo app) async* {
    final totalItems = 1 + app.relatedPaths.length;
    var processedItems = 0;

    yield UninstallProgress(
      appName: app.name,
      currentItem: 'Moving to Trash...',
      itemsProcessed: processedItems,
      totalItems: totalItems,
    );

    try {
      await _datasource.uninstallApp(
        app,
        onProgress: (item) {
          processedItems++;
        },
      );

      processedItems = totalItems;
      yield UninstallProgress(
        appName: app.name,
        currentItem: 'Completed',
        itemsProcessed: processedItems,
        totalItems: totalItems,
      );
    } catch (e) {
      yield UninstallProgress(
        appName: app.name,
        currentItem: 'Error: $e',
        itemsProcessed: processedItems,
        totalItems: totalItems,
      );
    }
  }

  Future<UninstallResult> uninstallAppSync(AppInfo app) async {
    final errors = <String>[];
    var filesRemoved = 0;
    var bytesFreed = 0;

    try {
      await _datasource.uninstallApp(app);
      filesRemoved = 1 + app.relatedPaths.length;
      bytesFreed = app.totalSize;

      return UninstallResult(
        appName: app.name,
        success: true,
        bytesFreed: bytesFreed,
        filesRemoved: filesRemoved,
        errors: errors,
      );
    } catch (e) {
      return UninstallResult.failure(app.name, e.toString());
    }
  }
}

class UninstallProgress {
  const UninstallProgress({
    required this.appName,
    required this.currentItem,
    required this.itemsProcessed,
    required this.totalItems,
  });

  final String appName;
  final String currentItem;
  final int itemsProcessed;
  final int totalItems;

  double get progress => totalItems > 0 ? itemsProcessed / totalItems : 0;

  double get progressPercentage => progress * 100;
}
