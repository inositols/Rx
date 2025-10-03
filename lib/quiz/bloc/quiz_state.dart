import 'package:equatable/equatable.dart';
import 'package:monami/core/models/cbt_models.dart';

abstract class QuizState extends Equatable {
  const QuizState();

  @override
  List<Object?> get props => [];
}

class QuizInitial extends QuizState {}

class QuizLoading extends QuizState {}

// State when loading available tests
class TestsLoaded extends QuizState {
  final List<TestConfig> tests;

  const TestsLoaded({required this.tests});

  @override
  List<Object?> get props => [tests];
}

// State when test questions are loaded and ready to start
class TestReady extends QuizState {
  final TestConfig testConfig;
  final List<TestQuestion> questions;

  const TestReady({
    required this.testConfig,
    required this.questions,
  });

  @override
  List<Object?> get props => [testConfig, questions];
}

// State during an active test session
class TestInProgress extends QuizState {
  final TestSession session;
  final List<TestQuestion> questions;
  final int currentQuestionIndex;
  final Duration remainingTime;
  final Map<String, TestAnswer> answers;

  const TestInProgress({
    required this.session,
    required this.questions,
    required this.currentQuestionIndex,
    required this.remainingTime,
    required this.answers,
  });

  TestInProgress copyWith({
    TestSession? session,
    List<TestQuestion>? questions,
    int? currentQuestionIndex,
    Duration? remainingTime,
    Map<String, TestAnswer>? answers,
  }) {
    return TestInProgress(
      session: session ?? this.session,
      questions: questions ?? this.questions,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      remainingTime: remainingTime ?? this.remainingTime,
      answers: answers ?? this.answers,
    );
  }

  // Helper getters
  TestQuestion get currentQuestion => questions[currentQuestionIndex];

  bool get hasAnsweredCurrentQuestion =>
      answers.containsKey(currentQuestion.id);

  int get totalQuestions => questions.length;

  int get answeredCount => answers.length;

  bool get isLastQuestion => currentQuestionIndex == questions.length - 1;

  bool get isFirstQuestion => currentQuestionIndex == 0;

  @override
  List<Object?> get props => [
        session,
        questions,
        currentQuestionIndex,
        remainingTime,
        answers,
      ];
}

// State when test is completed
class TestCompleted extends QuizState {
  final TestSession completedSession;
  final List<TestQuestion> questions;
  final Map<String, TestAnswer> answers;

  const TestCompleted({
    required this.completedSession,
    required this.questions,
    required this.answers,
  });

  // Helper getters
  int get totalQuestions => questions.length;

  int get correctAnswers =>
      answers.values.where((answer) => answer.isCorrect).length;

  double get percentage => (correctAnswers / totalQuestions) * 100;

  bool get passed =>
      percentage >= (completedSession.testId.isNotEmpty ? 60.0 : 50.0);

  @override
  List<Object?> get props => [completedSession, questions, answers];
}

// State when viewing test history
class TestHistoryLoaded extends QuizState {
  final List<TestSession> sessions;

  const TestHistoryLoaded({required this.sessions});

  @override
  List<Object?> get props => [sessions];
}

// State when viewing a specific test session
class TestSessionLoaded extends QuizState {
  final TestSession session;
  final List<TestQuestion> questions;
  final Map<String, TestAnswer> answers;

  const TestSessionLoaded({
    required this.session,
    required this.questions,
    required this.answers,
  });

  @override
  List<Object?> get props => [session, questions, answers];
}

class QuizError extends QuizState {
  final String message;

  const QuizError({required this.message});

  @override
  List<Object?> get props => [message];
}
