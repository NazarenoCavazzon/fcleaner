import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:os_cleaner/os_cleaner.dart';

part 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit({
    required AnalysisResult cleanUpAnalysis,
    required this.osCleaner,
  }) : super(
         HomeState(
           cleanUpAnalysis: cleanUpAnalysis,
         ),
       );

  void selectTab(HomeTab? tab) {
    emit(state.copyWith(selectedTab: tab));
  }

  void selectCategory(String categoryId) {
    emit(
      state.copyWith(
        selectedCategories: {
          ...state.selectedCategories,
          categoryId: !(state.selectedCategories[categoryId] ?? false),
        },
      ),
    );
  }

  void unselectCategory(String categoryId) {
    emit(
      state.copyWith(
        selectedCategories: {
          ...state.selectedCategories,
          categoryId: false,
        },
      ),
    );
  }

  void cleanUp() {
    final categories = state.cleanUpAnalysis.categories
        .where((category) => state.selectedCategories[category.id] ?? false)
        .toList();

    final result = osCleaner.clean(
      analysis: state.cleanUpAnalysis,
      categoryIds: categories.map((category) => category.id).toList(),
    );

    final newCleanUpAnalysis = state.cleanUpAnalysis.copyWith(
      categories: state.cleanUpAnalysis.categories
          .where(
            (category) => !categories
                .map((category) => category.id)
                .contains(category.id),
          )
          .toList(),
    );

    emit(
      state.copyWith(
        cleanUpResult: result,
        cleanUpAnalysis: newCleanUpAnalysis,
        selectedCategories: const {},
      ),
    );
  }

  final OSCleaner osCleaner;
}
