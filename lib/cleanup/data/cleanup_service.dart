import 'package:fcleaner/cleanup/data/macos_cleanup_datasource.dart';
import 'package:fcleaner/cleanup/models/analysis_result.dart';
import 'package:fcleaner/cleanup/models/cleanup_category.dart';
import 'package:fcleaner/cleanup/models/cleanup_result.dart';
import 'package:fcleaner/shared/models/cleanup_progress.dart';
import 'package:fcleaner/shared/models/system_info.dart';
import 'package:fcleaner/shared/services/system_command_service.dart';
import 'package:fcleaner/shared/services/whitelist_service.dart';

class CleanupService {
  CleanupService(
    this._datasource,
    this._whitelistService,
    this._systemCommandService,
  );

  final MacOSCleanupDatasource _datasource;
  final WhitelistService _whitelistService;
  final SystemCommandService _systemCommandService;

  Future<AnalysisResult> analyzeSystem() async {
    await _whitelistService.loadWhitelist();

    final results = await Future.wait([
      _datasource.scanAllCategories(),
      _systemCommandService.getSystemInfo(),
    ]);

    final categories = results[0] as List<CleanupCategory>;
    final systemInfo = results[1] as SystemInfo;

    return AnalysisResult(
      categories: categories,
      analyzedAt: DateTime.now(),
      systemInfo: systemInfo,
    );
  }

  Stream<CleanupProgress> performCleanup({
    required AnalysisResult analysis,
    required List<String> categoryIds,
    bool dryRun = false,
  }) async* {
    final itemsToDelete = analysis.getItemsToDelete(categoryIds);

    if (itemsToDelete.isEmpty) {
      return;
    }

    final totalItems = itemsToDelete.length;
    var processedItems = 0;
    var bytesFreed = 0;

    final categoryMap = {
      for (final cat in analysis.categories) cat.id: cat,
    };

    for (final item in itemsToDelete) {
      final category = categoryMap.values.firstWhere(
        (cat) => cat.items.any((i) => i.path == item.path),
      );

      try {
        if (!dryRun) {
          await _datasource.cleanupCategory(
            CleanupCategory(
              id: category.id,
              name: category.name,
              description: category.description,
              items: [item],
              requiresSudo: category.requiresSudo,
            ),
          );
        }

        processedItems++;
        bytesFreed += item.sizeBytes;

        yield CleanupProgress(
          currentCategory: category.name,
          currentItem: item.name,
          itemsProcessed: processedItems,
          totalItems: totalItems,
          bytesFreed: bytesFreed,
        );
      } catch (_) {
        processedItems++;
      }
    }
  }

  Future<CleanupResult> performCleanupSync({
    required AnalysisResult analysis,
    required List<String> categoryIds,
    bool dryRun = false,
  }) async {
    final startTime = DateTime.now();
    final errors = <String>[];
    var itemsCleaned = 0;
    var bytesFreed = 0;

    final itemsToDelete = analysis.getItemsToDelete(categoryIds);
    final categoryMap = {
      for (final cat in analysis.categories) cat.id: cat,
    };

    for (final item in itemsToDelete) {
      final category = categoryMap.values.firstWhere(
        (cat) => cat.items.any((i) => i.path == item.path),
      );

      try {
        if (!dryRun) {
          await _datasource.cleanupCategory(
            CleanupCategory(
              id: category.id,
              name: category.name,
              description: category.description,
              items: [item],
              requiresSudo: category.requiresSudo,
            ),
          );
        }

        itemsCleaned++;
        bytesFreed += item.sizeBytes;
      } catch (e) {
        errors.add('Failed to clean ${item.name}: $e');
      }
    }

    final duration = DateTime.now().difference(startTime);

    return CleanupResult(
      success: errors.isEmpty,
      bytesFreed: bytesFreed,
      itemsCleaned: itemsCleaned,
      duration: duration,
      errors: errors,
    );
  }

  Future<bool> requestSudoIfNeeded(
    AnalysisResult analysis,
    List<String> categoryIds,
  ) async {
    final needsSudo = analysis.categories
        .where((cat) => categoryIds.contains(cat.id))
        .any((cat) => cat.requiresSudo);

    if (needsSudo) {
      return _systemCommandService.requestSudo();
    }

    return true;
  }
}
