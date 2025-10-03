import 'package:equatable/equatable.dart';
import 'package:monami/core/models/cbt_models.dart';

abstract class QuestionState extends Equatable {
  const QuestionState();

  @override
  List<Object?> get props => [];
}

class QuestionInitial extends QuestionState {}

class QuestionLoading extends QuestionState {}

// State when questions are successfully loaded
class QuestionsLoaded extends QuestionState {
  final List<TestQuestion> questions;
  final int totalCount;
  final String? category;

  const QuestionsLoaded({
    required this.questions,
    required this.totalCount,
    this.category,
  });

  @override
  List<Object?> get props => [questions, totalCount, category];
}

// State during CSV upload
class QuestionUploadInProgress extends QuestionState {
  final int uploaded;
  final int total;
  final String currentStatus;

  const QuestionUploadInProgress({
    required this.uploaded,
    required this.total,
    required this.currentStatus,
  });

  double get progress => total > 0 ? uploaded / total : 0.0;

  @override
  List<Object?> get props => [uploaded, total, currentStatus];
}

// State when upload is completed
class QuestionUploadCompleted extends QuestionState {
  final int totalUploaded;
  final String message;

  const QuestionUploadCompleted({
    required this.totalUploaded,
    required this.message,
  });

  @override
  List<Object?> get props => [totalUploaded, message];
}

// State when CSV is validated
class CSVValidated extends QuestionState {
  final List<Map<String, dynamic>> validQuestions;
  final List<String> errors;
  final int totalRows;

  const CSVValidated({
    required this.validQuestions,
    required this.errors,
    required this.totalRows,
  });

  bool get hasErrors => errors.isNotEmpty;
  bool get isValid => errors.isEmpty && validQuestions.isNotEmpty;

  @override
  List<Object?> get props => [validQuestions, errors, totalRows];
}

// State when categories are loaded
class CategoriesLoaded extends QuestionState {
  final List<String> categories;

  const CategoriesLoaded({required this.categories});

  @override
  List<Object?> get props => [categories];
}

// State when a single question operation is completed
class QuestionOperationCompleted extends QuestionState {
  final String message;
  final QuestionOperationType operationType;

  const QuestionOperationCompleted({
    required this.message,
    required this.operationType,
  });

  @override
  List<Object?> get props => [message, operationType];
}

// State when search results are available
class QuestionSearchResults extends QuestionState {
  final List<TestQuestion> results;
  final String searchTerm;

  const QuestionSearchResults({
    required this.results,
    required this.searchTerm,
  });

  @override
  List<Object?> get props => [results, searchTerm];
}

class QuestionError extends QuestionState {
  final String message;
  final QuestionErrorType errorType;

  const QuestionError({
    required this.message,
    this.errorType = QuestionErrorType.general,
  });

  @override
  List<Object?> get props => [message, errorType];
}

enum QuestionOperationType {
  add,
  update,
  delete,
  upload,
}

enum QuestionErrorType {
  general,
  network,
  validation,
  permission,
  csvFormat,
}
