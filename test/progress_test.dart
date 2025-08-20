// test/progress_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:english_quiz/quiz/quiz_bloc.dart';
import 'package:english_quiz/quiz/quiz_repository.dart';
import 'package:english_quiz/core/prefs.dart';

Future<void> _flush() async => Future<void>.delayed(const Duration(milliseconds: 5));

void main() {
  setUp(() async {
    // Fresh prefs for every test
    SharedPreferences.setMockInitialValues({});
  });

  test('Round progress reaches 100% after all 10 answers', () async {
    final repo = QuizRepository();
    final bloc = QuizBloc(repo);

    // Load Round 1
    bloc.add(LoadRound(1));
    await _flush();
    expect(bloc.state.questions.length, 10);

    // Before answering, progress should be 0%
    double progress() => (bloc.state.selected.length / 10.0).clamp(0.0, 1.0);
    expect(progress(), 0.0);

    // Answer all 10 (choose the correct option; not required for this check)
    for (int i = 0; i < 10; i++) {
      final correct = bloc.state.questions[i].correctIndex;
      bloc.add(SelectOption(i, correct));
      await _flush();
      // Progress should monotonically increase by 0.1
      expect(progress(), (i + 1) / 10.0);
    }

    // Submit → should mark round as completed
    bloc.add(SubmitRound());
    await _flush();
    expect(bloc.state.submitted, true);

    // With all 10 selected, round progress is 100%
    expect(progress(), 1.0);
  });

  test('Overall completion progress increases per round and can reach 100%', () async {
    // Start empty
    SharedPreferences.setMockInitialValues({});
    expect((await Prefs.getCompletedRounds()).length, 0);

    // Complete 3 rounds
    await Prefs.addCompletedRound(1);
    await Prefs.addCompletedRound(2);
    await Prefs.addCompletedRound(3);

    var completed = await Prefs.getCompletedRounds();
    expect(completed.length, 3);

    double overallProgress() => (completed.length / 500.0).clamp(0.0, 1.0);

    // Should be 3/500 after three rounds
    expect(overallProgress(), 3 / 500.0);

    // Simulate all 500 done (fast path: set the list directly)
    final prefs = await SharedPreferences.getInstance();
    final all = List<String>.generate(500, (i) => '${i + 1}');
    await prefs.setStringList('completed_rounds', all);

    completed = await Prefs.getCompletedRounds();
    expect(completed.length, 500);
    expect(overallProgress(), 1.0); // 100%
  });
}
