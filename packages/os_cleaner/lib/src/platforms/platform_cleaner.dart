import 'package:os_cleaner/src/models/models.dart';

abstract class PlatformCleaner {
  Future<AnalysisResult> analyze();
  CleanupResult clean({
    required AnalysisResult analysis,
    required List<String> categoryIds,
  });
  Future<void> uninstall();
}
