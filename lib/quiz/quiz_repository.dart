import 'models.dart';

class QuizRepository {
  List<Question> getRoundQuestions(int round) {
    final qs = <Question>[];
    for (int i = 0; i < 10; i++) {
      final a = (round * 3 + i) % 20 + 1;
      final b = (round * 7 + i * 2) % 20 + 1;
      final answer = a + b;
      final distractor1 = answer + 1;
      final distractor2 = answer - 1;
      final distractor3 = answer + 2;
      final opts = [answer, distractor1, distractor2, distractor3].map((e) => e.toString()).toList();
      final correctIndex = (round + i) % 4;
      final rotated = List<String>.from(opts);
      final correctVal = rotated[0];
      rotated[0] = rotated[correctIndex];
      rotated[correctIndex] = correctVal;
      qs.add(Question(
        text: 'What is $a + $b?',
        options: rotated,
        correctIndex: correctIndex,
      ));
    }
    return qs;
  }
}
