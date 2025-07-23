// lib/widgets/question_card.dart
import 'package:flutter/material.dart';

class QuestionCard extends StatelessWidget {
  final String questionText;
  final List<String> options;
  final List<String> labels;
  final int? selectedIndex;
  final int correctIndex;
  final bool showFeedback;
  final Function(int) onSelected;

  const QuestionCard({
    required this.questionText,
    required this.options,
    required this.labels,
    required this.selectedIndex,
    required this.correctIndex,
    required this.showFeedback,
    required this.onSelected,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(questionText, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 24),
        ...List.generate(options.length, (index) {
          // ignore: unused_local_variable
          Color btnColor = Colors.blue;
          if (showFeedback) {
            if (index == selectedIndex) {
              btnColor = (index == correctIndex) ? Colors.green : Colors.red;
            } else if (index == correctIndex) {
              btnColor = Colors.green;
            }
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TextButton(
              onPressed: showFeedback ? null : () => onSelected(index),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                alignment: Alignment.centerLeft,
              ),
              child: Text(
                '${labels[index]}. ${options[index]}',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          );
        }),
      ],
    );
  }
}
