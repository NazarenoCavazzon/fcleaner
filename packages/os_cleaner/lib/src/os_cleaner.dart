import 'package:os_cleaner/src/models/models.dart';
import 'package:os_cleaner/src/platforms/platforms.dart';

class OSCleaner {
  OSCleaner(PlatformCleaner platformCleaner)
    : _platformCleaner = platformCleaner;

  final PlatformCleaner _platformCleaner;

  Future<AnalysisResult> analyze() async => _platformCleaner.analyze();

  CleanupResult clean({
    required AnalysisResult analysis,
    required List<String> categoryIds,
  }) => _platformCleaner.clean(
    analysis: analysis,
    categoryIds: categoryIds,
  );
  Future<void> uninstall() async => _platformCleaner.uninstall();
}
