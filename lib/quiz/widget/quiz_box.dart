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
  final String? imageUrl;

  const QuestionCard({
    required this.questionText,
    required this.options,
    required this.labels,
    required this.selectedIndex,
    required this.correctIndex,
    required this.showFeedback,
    required this.onSelected,
    this.imageUrl,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(questionText, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 16),
        
        // Display image if available
        if (imageUrl != null && imageUrl!.isNotEmpty) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              imageUrl!,
              height: 200,
              width: double.infinity,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('Image not available', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                );
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(child: CircularProgressIndicator()),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
        
        const SizedBox(height: 8),
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
