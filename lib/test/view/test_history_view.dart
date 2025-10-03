import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:monami/core/models/cbt_models.dart';
import 'package:monami/quiz/bloc/bloc.dart';
import 'package:monami/test/view/view.dart';

class TestHistoryView extends StatelessWidget {
  const TestHistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test History'),
      ),
      body: BlocBuilder<QuizBloc, QuizState>(
        builder: (context, state) {
          if (state is QuizLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is QuizError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${state.message}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Reload test history
                      Navigator.pop(context);
                    },
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          } else if (state is TestHistoryLoaded) {
            if (state.sessions.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No test history'),
                    Text('Take some tests to see your history here'),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.sessions.length,
              itemBuilder: (context, index) {
                final session = state.sessions[index];
                final percentage = session.percentage ?? 0.0;
                final passed = percentage >= 60.0;

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: passed ? Colors.green : Colors.red,
                      child: Icon(
                        passed ? Icons.check : Icons.close,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      session.testTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          'Score: ${percentage.toStringAsFixed(1)}% (${session.score}/${session.totalQuestions})',
                          style: TextStyle(
                            color: passed ? Colors.green : Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Date: ${DateFormat('MMM dd, yyyy - HH:mm').format(session.startTime)}',
                        ),
                        if (session.timeSpent != null)
                          Text(
                            'Duration: ${_formatDuration(session.timeSpent!)}',
                          ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: passed
                                ? Colors.green.shade100
                                : Colors.red.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            passed ? 'PASSED' : 'FAILED',
                            style: TextStyle(
                              color: passed
                                  ? Colors.green.shade700
                                  : Colors.red.shade700,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.visibility),
                      onPressed: () => _viewTestDetails(context, session),
                    ),
                    onTap: () => _viewTestDetails(context, session),
                  ),
                );
              },
            );
          }

          return const Center(
            child: Text('Loading test history...'),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pop(context);
        },
        child: const Icon(Icons.arrow_back),
      ),
    );
  }

  void _viewTestDetails(BuildContext context, TestSession session) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(session.testTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Test ID', session.testId),
              _buildDetailRow(
                'Start Time',
                DateFormat('MMM dd, yyyy - HH:mm').format(session.startTime),
              ),
              if (session.endTime != null)
                _buildDetailRow(
                  'End Time',
                  DateFormat('MMM dd, yyyy - HH:mm').format(session.endTime!),
                ),
              if (session.timeSpent != null)
                _buildDetailRow(
                  'Time Spent',
                  _formatDuration(session.timeSpent!),
                ),
              _buildDetailRow('Total Questions', '${session.totalQuestions}'),
              _buildDetailRow(
                  'Score', '${session.score ?? 0}/${session.totalQuestions}'),
              _buildDetailRow('Percentage',
                  '${(session.percentage ?? 0.0).toStringAsFixed(1)}%'),
              _buildDetailRow(
                'Status',
                (session.percentage ?? 0.0) >= 60.0 ? 'PASSED' : 'FAILED',
              ),
              _buildDetailRow('Completed', session.isCompleted ? 'Yes' : 'No'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
          if (session.isCompleted)
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                // Load detailed session view
                context
                    .read<QuizBloc>()
                    .add(LoadTestSession(sessionId: session.id));
                _showDetailedResults(context);
              },
              child: const Text('View Details'),
            ),
        ],
      ),
    );
  }

  void _showDetailedResults(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(16),
          child: BlocBuilder<QuizBloc, QuizState>(
            builder: (context, state) {
              if (state is QuizLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is TestSessionLoaded) {
                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Detailed Results',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const Divider(),
                    Expanded(
                      child: ListView.builder(
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
                            child: ExpansionTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    isCorrect ? Colors.green : Colors.red,
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(question.questionText),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      ...question.options
                                          .asMap()
                                          .entries
                                          .map((entry) {
                                        final optionIndex = entry.key;
                                        final option = entry.value;
                                        final isUserAnswer =
                                            answer?.selectedAnswerIndex ==
                                                optionIndex;
                                        final isCorrectAnswer =
                                            question.correctAnswerIndex ==
                                                optionIndex;

                                        return Container(
                                          margin:
                                              const EdgeInsets.only(bottom: 4),
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: isCorrectAnswer
                                                ? Colors.green.shade100
                                                : isUserAnswer &&
                                                        !isCorrectAnswer
                                                    ? Colors.red.shade100
                                                    : null,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Row(
                                            children: [
                                              if (isUserAnswer)
                                                Icon(
                                                  Icons.person,
                                                  size: 16,
                                                  color: isCorrectAnswer
                                                      ? Colors.green
                                                      : Colors.red,
                                                ),
                                              if (isCorrectAnswer)
                                                const Icon(
                                                  Icons.check,
                                                  size: 16,
                                                  color: Colors.green,
                                                ),
                                              const SizedBox(width: 8),
                                              Expanded(child: Text(option)),
                                            ],
                                          ),
                                        );
                                      }),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              }
              return const Center(
                  child: Text('Failed to load detailed results'));
            },
          ),
        ),
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
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
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
