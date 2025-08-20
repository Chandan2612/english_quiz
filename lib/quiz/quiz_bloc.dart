import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/prefs.dart';
import 'models.dart';
import 'quiz_repository.dart';

abstract class QuizEvent {}
class LoadRound extends QuizEvent { final int round; LoadRound(this.round); }
class SelectOption extends QuizEvent { final int questionIndex; final int optionIndex; SelectOption(this.questionIndex, this.optionIndex); }
class SubmitRound extends QuizEvent {}
class NextQuestion extends QuizEvent {}
class PrevQuestion extends QuizEvent {}
class ResetForNextRound extends QuizEvent { final int nextRound; ResetForNextRound(this.nextRound); }

class QuizState {
  final int round;
  final List<Question> questions;
  final Map<int, int> selected;
  final int currentIndex;
  final bool submitted;
  final int correctCount;
  final int selectionTick;
  final bool loading;
  final int adsToShow;

  const QuizState({
    required this.round,
    required this.questions,
    required this.selected,
    required this.currentIndex,
    required this.submitted,
    required this.correctCount,
    required this.selectionTick,
    required this.loading,
    required this.adsToShow,
  });

  QuizState copyWith({
    int? round,
    List<Question>? questions,
    Map<int, int>? selected,
    int? currentIndex,
    bool? submitted,
    int? correctCount,
    int? selectionTick,
    bool? loading,
    int? adsToShow,
  }) => QuizState(
    round: round ?? this.round,
    questions: questions ?? this.questions,
    selected: selected ?? this.selected,
    currentIndex: currentIndex ?? this.currentIndex,
    submitted: submitted ?? this.submitted,
    correctCount: correctCount ?? this.correctCount,
    selectionTick: selectionTick ?? this.selectionTick,
    loading: loading ?? this.loading,
    adsToShow: adsToShow ?? this.adsToShow,
  );

  static QuizState initial() => const QuizState(
    round: 1,
    questions: [],
    selected: {},
    currentIndex: 0,
    submitted: false,
    correctCount: 0,
    selectionTick: 0,
    loading: true,
    adsToShow: 0,
  );
}

class QuizBloc extends Bloc<QuizEvent, QuizState> {
  final QuizRepository repo;
  QuizBloc(this.repo) : super(QuizState.initial()) {
    on<LoadRound>(_onLoadRound);
    on<SelectOption>(_onSelect);
    on<NextQuestion>(_onNext);
    on<PrevQuestion>(_onPrev);
    on<SubmitRound>(_onSubmit);
    on<ResetForNextRound>(_onReset);
  }

  Future<void> _onLoadRound(LoadRound e, Emitter<QuizState> emit) async {
    emit(state.copyWith(loading: true));
    final round = e.round.clamp(1, 500);
    final qs = repo.getRoundQuestions(round);
    final stage = await Prefs.getStage(round);
    final selected = await Prefs.getSelectedMap(round);
    emit(state.copyWith(
      round: round,
      questions: qs,
      currentIndex: stage,
      selected: Map<int,int>.from(selected),
      submitted: false,
      correctCount: 0,
      selectionTick: 0,
      loading: false,
      adsToShow: 0,
    ));
  }

  Future<void> _onSelect(SelectOption e, Emitter<QuizState> emit) async {
    final m = Map<int,int>.from(state.selected);
    m[e.questionIndex] = e.optionIndex;
    emit(state.copyWith(selected: m, selectionTick: state.selectionTick + 1));
    await Prefs.setSelectedMap(state.round, m);
  }

  Future<void> _onNext(NextQuestion e, Emitter<QuizState> emit) async {
    final nextIdx = (state.currentIndex + 1).clamp(0, state.questions.length - 1);
    emit(state.copyWith(currentIndex: nextIdx));
    await Prefs.setStage(state.round, nextIdx);
  }

  Future<void> _onPrev(PrevQuestion e, Emitter<QuizState> emit) async {
    final prevIdx = (state.currentIndex - 1).clamp(0, state.questions.length - 1);
    emit(state.copyWith(currentIndex: prevIdx));
    await Prefs.setStage(state.round, prevIdx);
  }

  Future<void> _onSubmit(SubmitRound e, Emitter<QuizState> emit) async {
    int correct = 0;
    for (int i = 0; i < state.questions.length; i++) {
      final q = state.questions[i];
      final sel = state.selected[i];
      if (sel != null && sel == q.correctIndex) correct++;
    }
    final ads = correct >= 7 ? 1 : 2;
    emit(state.copyWith(submitted: true, correctCount: correct, adsToShow: ads));
    await Prefs.addCompletedRound(state.round);
  }

  Future<void> _onReset(ResetForNextRound e, Emitter<QuizState> emit) async {
    await Prefs.clearRoundState(state.round);
    await Prefs.setCurrentRound(e.nextRound);
    add(LoadRound(e.nextRound));
  }
}
