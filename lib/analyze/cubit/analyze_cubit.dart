import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:fcleaner/shared/services/service_provider.dart';
import 'package:fcleaner/cleanup/models/analysis_result.dart';
import 'package:fcleaner/cleanup/models/cleanup_preview.dart';
import 'package:fcleaner/uninstall/models/app_info.dart';

part 'analyze_state.dart';

class AnalyzeCubit extends Cubit<AnalyzeState> {
  AnalyzeCubit(this.serviceProvider) : super(const AnalyzeState());

  Future<void> analyze() async {
    emit(state.copyWith(status: AnalyzeStatus.analyzing));

    try {
      final results = await Future.wait([
        serviceProvider.cleanupService.analyzeSystem(),
        serviceProvider.uninstallService.getInstalledApps(),
      ]);
      final cleanUpAnalysis = results[0] as AnalysisResult;
      final cleanupPreview = cleanUpAnalysis.getPreview(
        cleanUpAnalysis.categories.map((e) => e.id).toList(),
      );
      final uninstallAnalysis = results[1] as List<AppInfo>;

      emit(
        state.copyWith(
          status: AnalyzeStatus.analyzed,
          cleanUpAnalysis: cleanUpAnalysis,
          cleanupPreview: cleanupPreview,
          uninstallAnalysis: uninstallAnalysis,
        ),
      );
    } catch (e) {
      emit(state.copyWith(status: AnalyzeStatus.error));
    }
  }

  final ServiceProvider serviceProvider;
}
