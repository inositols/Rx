import 'package:equatable/equatable.dart';
import '../../models/cbt_models.dart';

abstract class QuestionEvent extends Equatable {
  const QuestionEvent();

  @override
  List<Object?> get props => [];
}

// Load questions from Firebase
class LoadQuestions extends QuestionEvent {
  final String? category;
  final int? limit;

  const LoadQuestions({
    this.category,
    this.limit,
  });

  @override
  List<Object?> get props => [category, limit];
}

// Upload questions from CSV
class UploadQuestionsFromCSV extends QuestionEvent {
  final String csvContent;
  final String category;

  const UploadQuestionsFromCSV({
    required this.csvContent,
    required this.category,
  });

  @override
  List<Object?> get props => [csvContent, category];
}

// Add a single question
class AddQuestion extends QuestionEvent {
  final TestQuestion question;

  const AddQuestion({required this.question});

  @override
  List<Object?> get props => [question];
}

// Update a question
class UpdateQuestion extends QuestionEvent {
  final TestQuestion question;

  const UpdateQuestion({required this.question});

  @override
  List<Object?> get props => [question];
}

// Delete a question
class DeleteQuestion extends QuestionEvent {
  final String questionId;

  const DeleteQuestion({required this.questionId});

  @override
  List<Object?> get props => [questionId];
}

// Load questions by IDs (for specific test)
class LoadQuestionsByIds extends QuestionEvent {
  final List<String> questionIds;

  const LoadQuestionsByIds({required this.questionIds});

  @override
  List<Object?> get props => [questionIds];
}

// Search questions
class SearchQuestions extends QuestionEvent {
  final String searchTerm;

  const SearchQuestions({required this.searchTerm});

  @override
  List<Object?> get props => [searchTerm];
}

// Load categories
class LoadCategories extends QuestionEvent {}

// Validate CSV format
class ValidateCSV extends QuestionEvent {
  final String csvContent;

  const ValidateCSV({required this.csvContent});

  @override
  List<Object?> get props => [csvContent];
}
