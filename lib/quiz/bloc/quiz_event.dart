import 'package:equatable/equatable.dart';
import '../../models/cbt_models.dart';

abstract class QuizEvent extends Equatable {
  const QuizEvent();

  @override
  List<Object?> get props => [];
}

// Load available tests
class LoadAvailableTests extends QuizEvent {}

// Load questions for a specific test
class LoadTestQuestions extends QuizEvent {
  final String testId;

  const LoadTestQuestions({required this.testId});

  @override
  List<Object?> get props => [testId];
}

// Start a new test session
class StartTestSession extends QuizEvent {
  final String userId;
  final TestConfig testConfig;
  final List<TestQuestion> questions;

  const StartTestSession({
    required this.userId,
    required this.testConfig,
    required this.questions,
  });

  @override
  List<Object?> get props => [userId, testConfig, questions];
}

// Answer a question
class AnswerQuestion extends QuizEvent {
  final String questionId;
  final int selectedAnswerIndex;
  final Duration timeSpent;

  const AnswerQuestion({
    required this.questionId,
    required this.selectedAnswerIndex,
    required this.timeSpent,
  });

  @override
  List<Object?> get props => [questionId, selectedAnswerIndex, timeSpent];
}

// Navigate to next question
class NextQuestion extends QuizEvent {}

// Navigate to previous question
class PreviousQuestion extends QuizEvent {}

// Jump to specific question
class JumpToQuestion extends QuizEvent {
  final int questionIndex;

  const JumpToQuestion({required this.questionIndex});

  @override
  List<Object?> get props => [questionIndex];
}

// Submit the test
class SubmitTest extends QuizEvent {}

// Update timer
class UpdateTimer extends QuizEvent {
  final Duration remainingTime;

  const UpdateTimer({required this.remainingTime});

  @override
  List<Object?> get props => [remainingTime];
}

// Load test history
class LoadTestHistory extends QuizEvent {
  final String userId;

  const LoadTestHistory({required this.userId});

  @override
  List<Object?> get props => [userId];
}

// Load specific test session
class LoadTestSession extends QuizEvent {
  final String sessionId;

  const LoadTestSession({required this.sessionId});

  @override
  List<Object?> get props => [sessionId];
}
