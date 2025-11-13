import 'package:os_cleaner/src/models/models.dart';
import 'package:os_cleaner/src/platforms/macos/macos.dart';
import 'package:os_cleaner/src/platforms/platform_cleaner.dart';

class MacOSCleaner implements PlatformCleaner {
  @override
  Future<AnalysisResult> analyze() async {
    return MacOSAnalyzer.analyze();
  }

  @override
  CleanupResult clean({
    required AnalysisResult analysis,
    required List<String> categoryIds,
  }) {
    return MacOSAnalyzer.performCleanupSync(
      analysis: analysis,
      categoryIds: categoryIds,
    );
  }

  @override
  Future<void> uninstall() {
    // TODO: implement uninstall
    throw UnimplementedError();
  }
}
