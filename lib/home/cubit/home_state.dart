part of 'home_cubit.dart';

enum HomeTab {
  overview,
  cleanup,
  uninstall,
}

class HomeState extends Equatable {
  const HomeState({
    required this.cleanUpAnalysis,
    this.selectedTab = HomeTab.overview,
    this.selectedCategories = const {},
    this.cleanUpResult,
  });

  final HomeTab selectedTab;
  final AnalysisResult cleanUpAnalysis;
  final Map<String, bool> selectedCategories;
  final CleanupResult? cleanUpResult;

  HomeState copyWith({
    HomeTab? selectedTab,
    AnalysisResult? cleanUpAnalysis,
    Map<String, bool>? selectedCategories,
    CleanupResult? cleanUpResult,
  }) {
    return HomeState(
      selectedTab: selectedTab ?? this.selectedTab,
      cleanUpAnalysis: cleanUpAnalysis ?? this.cleanUpAnalysis,
      selectedCategories: selectedCategories ?? this.selectedCategories,
      cleanUpResult: cleanUpResult ?? this.cleanUpResult,
    );
  }

  @override
  List<Object?> get props => [
    selectedTab,
    cleanUpAnalysis,
    selectedCategories,
    cleanUpResult,
  ];
}
