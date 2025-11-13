import 'package:os_cleaner/src/models/models.dart';

abstract class PlatformAnalyzer {
  static Future<AnalysisResult> analyze() async {
    throw UnimplementedError();
  }
}
