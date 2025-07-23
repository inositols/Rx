import 'package:flutter/material.dart';
import 'package:monami/data/question_json.dart';
import 'package:monami/widgets/quiz_box.dart';

class QuizScreen extends StatefulWidget {
  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int currentQuestion = 0;
  int score = 0;
  int? selectedIndex;
  bool showFeedback = false;
  bool isLoading = false;

  final labels = ['A', 'B', 'C', 'D'];
  List<int?> answers = List.filled(sampleQuestions.length, null);

  void checkAnswer(int index) {
    setState(() {
      selectedIndex = index;
      showFeedback = true;
      answers[currentQuestion] = index;
    });

    Future.delayed(Duration(seconds: 2), () {
      setState(() {
        isLoading = true;
      });

      Future.delayed(Duration(seconds: 1), () {
        if (index == sampleQuestions[currentQuestion].correctIndex) {
          score++;
        }

        setState(() {
          selectedIndex = null;
          showFeedback = false;
          isLoading = false;

          // Optional: auto-advance to next unanswered question
          int nextIndex = answers.indexWhere((element) => element == null);
          if (nextIndex != -1) {
            currentQuestion = nextIndex;
          }
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (currentQuestion >= sampleQuestions.length ||
        answers.every((a) => a != null)) {
      return Scaffold(
        body: Center(
          child: AnimatedSwitcher(
            duration: Duration(seconds: 1),
            child: Text(
              '🎉 Quiz Completed!\nYour Score: $score',
              key: ValueKey(score),
              style: TextStyle(fontSize: 24),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final question = sampleQuestions[currentQuestion];

    return Scaffold(
      // appBar: AppBar(title: const Text('Multiple Choice Quiz')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${currentQuestion + 1}/${sampleQuestions.length}',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            QuestionCard(
              questionText: question.text,
              options: question.options,
              labels: labels,
              selectedIndex: selectedIndex,
              correctIndex: question.correctIndex,
              showFeedback: showFeedback,
              onSelected: (index) => checkAnswer(index),
            ),
            const SizedBox(height: 24),
            const Text(
              '📦 Questions Overview',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: List.generate(sampleQuestions.length, (index) {
                bool isAnswered = answers[index] != null;
                bool isSelected = index == currentQuestion;

                return GestureDetector(
                  onTap: () {
                    if (!isLoading) {
                      setState(() {
                        currentQuestion = index;
                        selectedIndex = answers[index];
                        showFeedback = selectedIndex != null;
                      });
                    }
                  },
                  child: Container(
                    width: 60,
                    height: 60,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isAnswered
                          ? Colors.green
                          : isSelected
                              ? Colors.orange
                              : Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontSize: 16,
                        color: isAnswered || isSelected
                            ? Colors.white
                            : Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
