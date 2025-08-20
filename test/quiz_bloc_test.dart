// 🧪 QuizBloc unit tests (no widgets)
import 'package:english_quiz/core/prefs.dart';
import 'package:english_quiz/quiz/quiz_bloc.dart';
import 'package:english_quiz/quiz/quiz_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _flush() async => await Future<void>.delayed(const Duration(milliseconds: 10));

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({}); // reset storage for each test
  });

  test('Load round creates 10 questions and restores stage/selected', () async {
    final repo = QuizRepository();
    final bloc = QuizBloc(repo);

    bloc.add(LoadRound(1));
    await _flush();

    expect(bloc.state.loading, false);
    expect(bloc.state.round, 1);
    expect(bloc.state.questions.length, 10);
    expect(bloc.state.currentIndex, 0);
    expect(bloc.state.selected.isEmpty, true);
  });

  test('SelectOption persists, Next/Prev move stage, Submit computes ads', () async {
    final repo = QuizRepository();
    final bloc = QuizBloc(repo);

    bloc.add(LoadRound(1));
    await _flush();

    // ✅ Answer first 7 correctly, next 3 incorrectly
    for (int i = 0; i < 10; i++) {
      final correct = bloc.state.questions[i].correctIndex;
      final pick = i < 7 ? correct : (correct + 1) % 4; // wrong on purpose
      bloc.add(SelectOption(i, pick));
    }
    await _flush();

    // Move once
    expect(bloc.state.currentIndex, 0);
    bloc.add(NextQuestion());
    await _flush();
    expect(bloc.state.currentIndex, 1);

    // Go back
    bloc.add(PrevQuestion());
    await _flush();
    expect(bloc.state.currentIndex, 0);

    // Submit → 7 correct => 1 ad
    bloc.add(SubmitRound());
    await _flush();

    expect(bloc.state.submitted, true);
    expect(bloc.state.correctCount, 7);
    expect(bloc.state.adsToShow, 1);

    // Round should be recorded as completed
    final completed = await Prefs.getCompletedRounds();
    expect(completed.contains(1), true);
  });

  test('Submit with <7 correct shows 2 ads', () async {
    final repo = QuizRepository();
    final bloc = QuizBloc(repo);

    bloc.add(LoadRound(2));
    await _flush();

    // 5 correct
    for (int i = 0; i < 10; i++) {
      final correct = bloc.state.questions[i].correctIndex;
      final pick = i < 5 ? correct : (correct + 1) % 4;
      bloc.add(SelectOption(i, pick));
    }
    await _flush();

    bloc.add(SubmitRound());
    await _flush();

    expect(bloc.state.correctCount, 5);
    expect(bloc.state.adsToShow, 2);
  });
}
