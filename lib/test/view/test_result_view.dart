import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../quiz/quiz/quiz_bloc.dart';
import '../quiz/quiz/quiz_state.dart';
import '../models/cbt_models.dart';
import '../utils/responsive_utils.dart';
import 'cbt_dashboard_view.dart';

class TestResultView extends StatelessWidget {
  const TestResultView({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const CBTDashboardView()),
            (route) => false,
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Test Results'),
          leading: IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                    builder: (context) => const CBTDashboardView()),
                (route) => false,
              );
            },
          ),
        ),
        body: BlocBuilder<QuizBloc, QuizState>(
          builder: (context, state) {
            if (state is TestCompleted) {
              return _buildResultsContent(context, state);
            } else if (state is QuizLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return const Center(
              child: Text('No test results available'),
            );
          },
        ),
      ),
    );
  }

  Widget _buildResultsContent(BuildContext context, TestCompleted state) {
    final session = state.completedSession;
    final percentage = state.percentage;
    final passed = state.passed;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Overall result card
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    passed ? Icons.check_circle : Icons.cancel,
                    size: 64,
                    color: passed ? Colors.green : Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    passed ? 'Congratulations!' : 'Keep Trying!',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: passed ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    passed
                        ? 'You have passed the test'
                        : 'You need more practice',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),

                  // Score display
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: passed ? Colors.green.shade50 : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: passed
                            ? Colors.green.shade200
                            : Colors.red.shade200,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${percentage.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: passed
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          '${state.correctAnswers}/${state.totalQuestions}',
                          style: TextStyle(
                            fontSize: 18,
                            color: passed
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Test details
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Test Details',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow('Test Title', session.testTitle),
                  _buildDetailRow(
                    'Started At',
                    DateFormat('MMM dd, yyyy - HH:mm')
                        .format(session.startTime),
                  ),
                  if (session.endTime != null)
                    _buildDetailRow(
                      'Completed At',
                      DateFormat('MMM dd, yyyy - HH:mm')
                          .format(session.endTime!),
                    ),
                  if (session.timeSpent != null)
                    _buildDetailRow(
                      'Time Spent',
                      _formatDuration(session.timeSpent!),
                    ),
                  _buildDetailRow('Total Questions', '${state.totalQuestions}'),
                  _buildDetailRow('Correct Answers', '${state.correctAnswers}'),
                  _buildDetailRow('Incorrect Answers',
                      '${state.totalQuestions - state.correctAnswers}'),
                  _buildDetailRow('Score', '${percentage.toStringAsFixed(1)}%'),
                  _buildDetailRow('Status', passed ? 'PASSED' : 'FAILED'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Question breakdown
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Question Breakdown',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: state.questions.length,
                    itemBuilder: (context, index) {
                      final question = state.questions[index];
                      final answer = state.answers[question.id];
                      final isCorrect = answer?.isCorrect ?? false;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        color: isCorrect
                            ? Colors.green.shade50
                            : Colors.red.shade50,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                isCorrect ? Colors.green : Colors.red,
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(
                            question.questionText,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (answer != null) ...[
                                Text(
                                    'Your answer: ${question.options[answer.selectedAnswerIndex]}'),
                                if (!isCorrect)
                                  Text(
                                    'Correct answer: ${question.options[question.correctAnswerIndex]}',
                                    style:
                                        TextStyle(color: Colors.green.shade700),
                                  ),
                              ] else
                                const Text('Not answered'),
                            ],
                          ),
                          trailing: Icon(
                            isCorrect ? Icons.check_circle : Icons.cancel,
                            color: isCorrect ? Colors.green : Colors.red,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                          builder: (context) => const CBTDashboardView()),
                      (route) => false,
                    );
                  },
                  icon: const Icon(Icons.home),
                  label: const Text('Back to Dashboard'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Navigate back to test list for retake
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                          builder: (context) => const CBTDashboardView()),
                      (route) => false,
                    );
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Take Another Test'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else {
      return '${minutes}m ${seconds}s';
    }
  }
}
