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
  });

  final AnalyzeStatus status;
  final AnalysisResult? cleanUpAnalysis;

  bool get isAnalyzing => status == AnalyzeStatus.analyzing;

  AnalyzeState copyWith({
    AnalyzeStatus? status,
    AnalysisResult? cleanUpAnalysis,
  }) {
    return AnalyzeState(
      status: status ?? this.status,
      cleanUpAnalysis: cleanUpAnalysis ?? this.cleanUpAnalysis,
    );
  }

  @override
  List<Object?> get props => [
    status,
    cleanUpAnalysis,
  ];
}
