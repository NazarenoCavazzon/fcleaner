import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:fcleaner/cleanup/models/analysis_result.dart';
import 'package:fcleaner/cleanup/models/cleanup_preview.dart';
import 'package:fcleaner/uninstall/models/app_info.dart';

part 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit({
    required AnalysisResult cleanUpAnalysis,
    required CleanupPreview cleanupPreview,
    required List<AppInfo> uninstallAnalysis,
  }) : super(
         HomeState(
           cleanUpAnalysis: cleanUpAnalysis,
           cleanupPreview: cleanupPreview,
           uninstallAnalysis: uninstallAnalysis,
         ),
       );
}
