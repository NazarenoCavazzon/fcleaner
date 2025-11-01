part of 'home_cubit.dart';

class HomeState extends Equatable {
  const HomeState({
    required this.cleanUpAnalysis,
    required this.cleanupPreview,
    required this.uninstallAnalysis,
  });

  final AnalysisResult cleanUpAnalysis;
  final CleanupPreview cleanupPreview;
  final List<AppInfo> uninstallAnalysis;

  @override
  List<Object> get props => [
    cleanUpAnalysis,
    cleanupPreview,
    uninstallAnalysis,
  ];
}
