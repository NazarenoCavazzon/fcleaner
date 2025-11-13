import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:os_cleaner/os_cleaner.dart';

part 'analyze_state.dart';

class AnalyzeCubit extends Cubit<AnalyzeState> {
  AnalyzeCubit(this.osCleaner) : super(const AnalyzeState());

  Future<void> analyze() async {
    emit(state.copyWith(status: AnalyzeStatus.analyzing));

    try {
      final analysis = await osCleaner.analyze();

      emit(
        state.copyWith(
          status: AnalyzeStatus.analyzed,
          cleanUpAnalysis: analysis,
        ),
      );
    } catch (e) {
      emit(state.copyWith(status: AnalyzeStatus.error));
    }
  }

  final OSCleaner osCleaner;
}
