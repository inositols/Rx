import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:monami/core/utils/responsive_utils.dart';
import '../../quiz/bloc/bloc.dart';
import 'test_result_view.dart';

class TestTakingView extends StatefulWidget {
  const TestTakingView({super.key});

  @override
  State<TestTakingView> createState() => _TestTakingViewState();
}

class _TestTakingViewState extends State<TestTakingView> {
  int? selectedAnswerIndex;
  DateTime? questionStartTime;

  @override
  void initState() {
    super.initState();
    questionStartTime = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          final shouldPop = await _showExitDialog(context);
          if (shouldPop && context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Test in Progress'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () async {
              if (await _showExitDialog(context)) {
                Navigator.of(context).pop();
              }
            },
          ),
          actions: [
            BlocBuilder<QuizBloc, QuizState>(
              builder: (context, state) {
                if (state is TestInProgress) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getTimerColor(state.remainingTime),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _formatTime(state.remainingTime),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        body: BlocListener<QuizBloc, QuizState>(
          listener: (context, state) {
            if (state is TestCompleted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const TestResultView(),
                ),
              );
            } else if (state is QuizError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            }
          },
          child: BlocBuilder<QuizBloc, QuizState>(
            builder: (context, state) {
              if (state is TestInProgress) {
                return _buildTestInterface(context, state);
              } else if (state is QuizLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              return const Center(
                child: Text('Test session not found'),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTestInterface(BuildContext context, TestInProgress state) {
    final question = state.currentQuestion;
    final hasAnswered = state.hasAnsweredCurrentQuestion;

    // Update selected answer if this question was already answered
    if (hasAnswered && selectedAnswerIndex == null) {
      selectedAnswerIndex = state.answers[question.id]?.selectedAnswerIndex;
    } else if (!hasAnswered) {
      selectedAnswerIndex = null;
    }

    return Column(
      children: [
        // Progress indicator
        LinearProgressIndicator(
          value: (state.currentQuestionIndex + 1) / state.totalQuestions,
          backgroundColor: Colors.grey[300],
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.teal),
        ),

        // Question info bar
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey[50],
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question ${state.currentQuestionIndex + 1} of ${state.totalQuestions}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'Answered: ${state.answeredCount}/${state.totalQuestions}',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),

        // Question content
        Expanded(
          child: SingleChildScrollView(
            padding: ResponsiveUtils.getResponsivePadding(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Question text with better formatting
                Card(
                  elevation: 2,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          question.questionText,
                          style: TextStyle(
                            fontSize: ResponsiveUtils.getResponsiveFontSize(
                              context,
                              mobile: 16,
                              tablet: 17,
                              desktop: 18,
                            ),
                            fontWeight: FontWeight.w500,
                            height: 1.5,
                            color: Colors.black87,
                          ),
                        ),
                        if (question.imageUrl != null) ...[
                          const SizedBox(height: 16),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              question.imageUrl!,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 200,
                                  color: Colors.grey[200],
                                  child: const Center(
                                    child: Text('Image not available'),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Answer options with better spacing and visibility
                ...question.options.asMap().entries.map((entry) {
                  final index = entry.key;
                  final option = entry.value;
                  final isSelected = selectedAnswerIndex == index;
                  final labels = ['A', 'B', 'C', 'D'];
                  final label = labels[index];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Material(
                      elevation: isSelected ? 4 : 1,
                      borderRadius: BorderRadius.circular(8),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            selectedAnswerIndex = index;
                          });
                          _answerQuestion(state, question.id, index);
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(minHeight: 60),
                          padding:
                              ResponsiveUtils.getResponsivePadding(context),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.teal[50] : Colors.white,
                            borderRadius: BorderRadius.circular(
                              ResponsiveUtils.getResponsiveValue(
                                context,
                                mobile: 8,
                                tablet: 10,
                                desktop: 12,
                              ),
                            ),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.teal
                                  : Colors.grey.shade300,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.teal
                                      : Colors.grey[200],
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    option,
                                    style: TextStyle(
                                      fontSize:
                                          ResponsiveUtils.getResponsiveFontSize(
                                        context,
                                        mobile: 14,
                                        tablet: 15,
                                        desktop: 16,
                                      ),
                                      color: isSelected
                                          ? Colors.teal[700]
                                          : Colors.black,
                                      fontWeight: isSelected
                                          ? FontWeight.w500
                                          : FontWeight.normal,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ),
                              if (isSelected)
                                const Padding(
                                  padding: EdgeInsets.only(top: 6),
                                  child: Icon(
                                    Icons.check_circle,
                                    color: Colors.teal,
                                    size: 24,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),

                // Extra bottom padding to ensure content is not blocked
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),

        // Navigation buttons
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            border: Border(top: BorderSide(color: Colors.grey[300]!)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Question navigator button
              ElevatedButton.icon(
                onPressed: () => _showQuestionNavigator(context, state),
                icon: const Icon(Icons.grid_view),
                label: const Text('Question Navigator'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),

              const SizedBox(width: 24),

              // Submit button (only show on last question or when user wants to submit)
              if (state.isLastQuestion ||
                  state.answeredCount == state.totalQuestions)
                ElevatedButton.icon(
                  onPressed: () => _showSubmitDialog(context),
                  icon: const Icon(Icons.check),
                  label: const Text('Submit Test'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  void _answerQuestion(
      TestInProgress state, String questionId, int answerIndex) {
    final timeSpent =
        DateTime.now().difference(questionStartTime ?? DateTime.now());

    context.read<QuizBloc>().add(
          AnswerQuestion(
            questionId: questionId,
            selectedAnswerIndex: answerIndex,
            timeSpent: timeSpent,
          ),
        );
  }

  void _showQuestionNavigator(BuildContext context, TestInProgress state) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Question Navigator'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: state.totalQuestions,
            itemBuilder: (context, index) {
              final isAnswered =
                  state.answers.containsKey(state.questions[index].id);
              final isCurrent = index == state.currentQuestionIndex;

              return GestureDetector(
                onTap: () {
                  Navigator.of(dialogContext).pop();
                  setState(() {
                    selectedAnswerIndex = null;
                    questionStartTime = DateTime.now();
                  });
                  context
                      .read<QuizBloc>()
                      .add(JumpToQuestion(questionIndex: index));
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? Colors.teal
                        : isAnswered
                            ? Colors.green
                            : Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                    border: isCurrent
                        ? Border.all(color: Colors.teal.shade700, width: 2)
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: (isCurrent || isAnswered)
                            ? Colors.white
                            : Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSubmitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Submit Test'),
        content: const Text(
          'Are you sure you want to submit your test? '
          'You won\'t be able to change your answers after submission.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<QuizBloc>().add(SubmitTest());
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  Future<bool> _showExitDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Exit Test'),
            content: const Text(
              'Are you sure you want to exit? Your progress will be saved, '
              'but you may not be able to resume this test session.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Stay'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Exit'),
              ),
            ],
          ),
        ) ??
        false;
  }

  String _formatTime(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }
  }

  Color _getTimerColor(Duration remaining) {
    final totalMinutes = remaining.inMinutes;
    if (totalMinutes <= 5) {
      return Colors.red;
    } else if (totalMinutes <= 10) {
      return Colors.orange;
    } else {
      return Colors.teal;
    }
  }
}
