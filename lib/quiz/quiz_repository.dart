// // import 'models.dart';

// // class QuizRepository {
// //   List<Question> getRoundQuestions(int round) {
// //     final qs = <Question>[];
// //     for (int i = 0; i < 10; i++) {
// //       final a = (round * 3 + i) % 20 + 1;
// //       final b = (round * 7 + i * 2) % 20 + 1;
// //       final answer = a + b;
// //       final distractor1 = answer + 1;
// //       final distractor2 = answer - 1;
// //       final distractor3 = answer + 2;
// //       final opts = [answer, distractor1, distractor2, distractor3].map((e) => e.toString()).toList();
// //       final correctIndex = (round + i) % 4;
// //       final rotated = List<String>.from(opts);
// //       final correctVal = rotated[0];
// //       rotated[0] = rotated[correctIndex];
// //       rotated[correctIndex] = correctVal;
// //       qs.add(Question(
// //         text: 'What is $a + $b?',
// //         options: rotated,
// //         correctIndex: correctIndex,
// //       ));
// //     }
// //     return qs;
// //   }
// // }

// import 'models.dart';

// /// 🔧 Single source of truth for how many questions are in a round.
// const int kQuestionsPerRound = 7;

// class QuizRepository {
//   List<Question> getRoundQuestions(int round) {
//     final qs = <Question>[];

//     // Generate exactly 7 questions per round.
//     for (int i = 0; i < kQuestionsPerRound; i++) {
//       final a = (round * 3 + i) % 20 + 1;
//       final b = (round * 7 + i * 2) % 20 + 1;

//       final answer = a + b;
//       final distractor1 = answer + 1;
//       final distractor2 = answer - 1;
//       final distractor3 = answer + 2;

//       final opts = [answer, distractor1, distractor2, distractor3].map((e) => e.toString()).toList();

//       // Rotate so the correct index isn’t always 0
//       final correctIndex = (round + i) % 4;
//       final rotated = List<String>.from(opts);
//       final correctVal = rotated[0];
//       rotated[0] = rotated[correctIndex];
//       rotated[correctIndex] = correctVal;

//       qs.add(Question(
//         text: 'What is $a + $b?',
//         options: rotated,
//         correctIndex: correctIndex,
//       ));
//     }

//     return qs;
//   }
// }
// lib/quiz/quiz_repository.dart
import 'dart:math';
import 'models.dart';

class QuizRepository {
  static const int _kQuestionsPerRound = 7;

  // We’ll cycle operations deterministically by round+index.
  // 0: +, 1: -, 2: ×, 3: ÷, 4: %
  List<Question> getRoundQuestions(int round) {
    final qs = <Question>[];
    final rng = Random(round); // deterministic per round

    for (int i = 0; i < _kQuestionsPerRound; i++) {
      final opIndex = (round + i) % 5;

      late int a, b, answer;
      late String symbol;
      late String text;

      switch (opIndex) {
        case 0: // Addition
          symbol = '+';
          a = 10 + ((round * 3 + i) % 90);
          b = 1 + ((round * 7 + i * 2) % 90);
          answer = a + b;
          text = 'What is $a $symbol $b?';
          break;

        case 1: // Subtraction (non-negative)
          symbol = '−';
          a = 20 + ((round * 5 + i * 3) % 100);
          b = (round * 2 + i * 5) % (a + 1);
          if (b > a) b = a; // clamp
          answer = a - b;
          text = 'What is $a $symbol $b?';
          break;

        case 2: // Multiplication (keep numbers readable)
          symbol = '×';
          a = 2 + ((round * 3 + i) % 11);  // 2..12
          b = 2 + ((round * 5 + i * 2) % 11); // 2..12
          answer = a * b;
          text = 'What is $a $symbol $b?';
          break;

        case 3: // Division (whole-number)
          symbol = '÷';
          final divisor = 2 + ((round + i * 3) % 11); // 2..12
          final quotient = 2 + ((round * 4 + i) % 11); // 2..12
          a = divisor * quotient; // dividend
          b = divisor;
          answer = quotient;
          text = 'What is $a $symbol $b?';
          break;

        default: // 4: Modulus
          symbol = '%';
          b = 2 + ((round * 6 + i) % 11); // 2..12
          final q = (round + i * 7) % 13; // 0..12
          final r = (round * 3 + i * 5) % b; // 0..b-1
          a = b * q + r;
          answer = r;
          text = 'What is $a $symbol $b?';
          break;
      }

      // Build answer options: correct + 3 distractors
      final optsInts = _makeDistractors(answer, rng);
      final opts = optsInts.map((e) => e.toString()).toList();

      // Deterministic “shuffle”: put correct at a rotating index (round+i)%4
      final correctIndex = (round + i) % 4;
      // ensure correct is present at index 0 now, then rotate into position
      if (opts[0] != answer.toString()) {
        final ci = opts.indexOf(answer.toString());
        if (ci != -1) {
          final tmp = opts[0];
          opts[0] = opts[ci];
          opts[ci] = tmp;
        } else {
          // Shouldn’t happen, but if it does, force-insert correct
          opts[0] = answer.toString();
        }
      }
      // swap 0 with correctIndex
      final tmp = opts[correctIndex];
      opts[correctIndex] = opts[0];
      opts[0] = tmp;

      qs.add(Question(text: text, options: opts, correctIndex: correctIndex));
    }

    return qs;
  }

  /// Create 1 correct + 3 unique, plausible distractors.
  /// Keeps values >= 0 and avoids duplicates.
  List<int> _makeDistractors(int correct, Random rng) {
    final set = <int>{correct};

    // Nearby values first (common wrong picks)
    final nearby = <int>[
      correct + 1,
      correct - 1,
      correct + 2,
      correct - 2,
      correct + 3,
      correct - 3,
    ].where((v) => v >= 0);

    for (final v in nearby) {
      set.add(v);
      if (set.length >= 4) break;
    }

    // If still not enough, add random positives around the correct answer.
    while (set.length < 4) {
      final delta = 1 + rng.nextInt(6); // 1..6
      final sign = rng.nextBool() ? 1 : -1;
      int v = correct + sign * delta;
      if (v < 0) v = correct + delta;
      set.add(v);
    }

    // Return first 4 as a list (correct will be at index 0 initially)
    final list = set.toList();

    // Ensure correct is at 0 so we can place it later at rotating index
    final ci = list.indexOf(correct);
    if (ci != 0) {
      final tmp = list[0];
      list[0] = list[ci];
      list[ci] = tmp;
    }

    return list.take(4).toList();
  }
}
