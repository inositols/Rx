import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:monami/core/models/cbt_models.dart';
import 'package:monami/quiz/widget/quiz_box.dart';
import '../../question/bloc/bloc.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int currentQuestion = 0;
  int score = 0;
  int? selectedIndex;
  bool showFeedback = false;
  bool isLoading = false;

  final labels = ['A', 'B', 'C', 'D'];
  List<TestQuestion> questions = [];
  List<int?> answers = [];

  late Timer quizTimer;
  Duration remainingTime = const Duration(minutes: 10);

  @override
  void initState() {
    super.initState();
    context.read<QuestionBloc>().add(const LoadQuestions());
    startCountdownTimer();
  }

  @override
  void dispose() {
    quizTimer.cancel();
    super.dispose();
  }

  void startCountdownTimer() {
    quizTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingTime.inSeconds <= 1) {
        timer.cancel();
        setState(() {
          remainingTime = Duration.zero;
          currentQuestion = questions.length; // End quiz
        });
      } else {
        setState(() {
          remainingTime -= const Duration(seconds: 1);
        });
      }
    });
  }

  void _handleQuestionState(QuestionState state) {
    if (state is QuestionsLoaded) {
      setState(() {
        questions = state.questions;
        answers = List.filled(questions.length, null);
        isLoading = false;
      });
    } else if (state is QuestionLoading) {
      setState(() => isLoading = true);
    } else if (state is QuestionError) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${state.message}')),
      );
    }
  }

  void checkAnswer(int index) {
    setState(() {
      selectedIndex = index;
      showFeedback = true;
      answers[currentQuestion] = index;
    });

    Future.delayed(const Duration(seconds: 2), () {
      setState(() => isLoading = true);

      Future.delayed(const Duration(seconds: 1), () {
        if (index == questions[currentQuestion].correctAnswerIndex) {
          score++;
        }

        setState(() {
          selectedIndex = null;
          showFeedback = false;
          isLoading = false;

          int nextIndex = answers.indexWhere((element) => element == null);
          if (nextIndex != -1) {
            currentQuestion = nextIndex;
          }
        });
      });
    });
  }

  String _formatElapsedTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<QuestionBloc, QuestionState>(
      listener: (context, state) => _handleQuestionState(state),
      child: BlocBuilder<QuestionBloc, QuestionState>(
        builder: (context, state) {
          if (isLoading && questions.isEmpty) {
            return const Scaffold(
                body: Center(child: CircularProgressIndicator()));
          }

          if (questions.isEmpty) {
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('No questions found.'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.read<QuestionBloc>().add(const LoadQuestions());
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (currentQuestion >= questions.length ||
              answers.every((a) => a != null) ||
              remainingTime.inSeconds == 0) {
            return Scaffold(
              body: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(seconds: 1),
                  child: Text(
                    '🎉 Quiz Completed!\nYour Score: $score',
                    key: ValueKey(score),
                    style: const TextStyle(fontSize: 24),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          }

          final question = questions[currentQuestion];

          return Scaffold(
            body: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.all(24),
                  width: 300,
                  color: Colors.grey[100],
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(""),
                      const CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.blueAccent,
                        child:
                            Icon(Icons.person, size: 48, color: Colors.white),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'User Name',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Time Left: ${_formatElapsedTime(remainingTime)}',
                        style: const TextStyle(fontSize: 16, color: Colors.red),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
                // Quiz Card
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 40, top: 10),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              '${currentQuestion + 1}/${questions.length}',
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        QuestionCard(
                          questionText: question.questionText,
                          options: question.options,
                          labels: labels,
                          selectedIndex: selectedIndex,
                          correctIndex: question.correctAnswerIndex,
                          showFeedback: showFeedback,
                          onSelected: (index) => checkAnswer(index),
                          imageUrl: question.imageUrl,
                        ),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: List.generate(questions.length, (index) {
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
                                width: 70,
                                height: 70,
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
                                    fontSize: 14,
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
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
