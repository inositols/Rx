import 'package:monami/model/quiz.dart';

final sampleQuestions = List.generate(100, (index) {
  return Question(
    text: "Sample question #${index + 1}",
    options: ["Option A", "Option B", "Option C", "Option D"],
    correctIndex: index % 4,
  );
});
