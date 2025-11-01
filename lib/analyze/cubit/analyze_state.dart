part of 'analyze_cubit.dart';

enum AnalyzeStatus {
  initial,
  analyzing,
  analyzed,
  error,
}

class AnalyzeState extends Equatable {
  const AnalyzeState({
    this.status = AnalyzeStatus.initial,
    this.cleanUpAnalysis,
    this.cleanupPreview,
    this.uninstallAnalysis = const [],
  });

  final AnalyzeStatus status;
  final AnalysisResult? cleanUpAnalysis;
  final CleanupPreview? cleanupPreview;
  final List<AppInfo> uninstallAnalysis;

  bool get isAnalyzing => status == AnalyzeStatus.analyzing;

  AnalyzeState copyWith({
    AnalyzeStatus? status,
    AnalysisResult? cleanUpAnalysis,
    CleanupPreview? cleanupPreview,
    List<AppInfo>? uninstallAnalysis,
  }) {
    return AnalyzeState(
      status: status ?? this.status,
      cleanUpAnalysis: cleanUpAnalysis ?? this.cleanUpAnalysis,
      cleanupPreview: cleanupPreview ?? this.cleanupPreview,
      uninstallAnalysis: uninstallAnalysis ?? this.uninstallAnalysis,
    );
  }

  @override
  List<Object?> get props => [
    status,
    cleanUpAnalysis,
    cleanupPreview,
    uninstallAnalysis,
  ];
}
