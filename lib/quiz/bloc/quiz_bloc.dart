import 'dart:async';
import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:monami/quiz/bloc/bloc.dart';
import 'package:monami/core/models/cbt_models.dart';
import 'package:monami/core/data/question_json.dart' as question_data;

class QuizBloc extends Bloc<QuizEvent, QuizState> {
  final FirebaseFirestore _firestore;
  Timer? _timer;

  QuizBloc({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        super(QuizInitial()) {
    on<LoadAvailableTests>(_onLoadAvailableTests);
    on<LoadTestQuestions>(_onLoadTestQuestions);
    on<StartTestSession>(_onStartTestSession);
    on<AnswerQuestion>(_onAnswerQuestion);
    on<NextQuestion>(_onNextQuestion);
    on<PreviousQuestion>(_onPreviousQuestion);
    on<JumpToQuestion>(_onJumpToQuestion);
    on<SubmitTest>(_onSubmitTest);
    on<UpdateTimer>(_onUpdateTimer);
    on<LoadTestHistory>(_onLoadTestHistory);
    on<LoadTestSession>(_onLoadTestSession);
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }

  Future<void> _onLoadAvailableTests(
    LoadAvailableTests event,
    Emitter<QuizState> emit,
  ) async {
    emit(QuizLoading());
    try {
      // Load test configurations from Firestore
      final querySnapshot = await _firestore
          .collection('test_configs')
          .where('isPublished', isEqualTo: true)
          .get();

      final tests = querySnapshot.docs
          .map((doc) => TestConfig.fromFirestore(doc))
          .toList();

      // If no tests in Firestore, create a default test
      if (tests.isEmpty) {
        final defaultTest = TestConfig(
          id: 'default_test',
          title: 'Sample Quiz',
          description: 'A sample computer-based test',
          category: 'General',
          questionCount: 10,
          timeLimit: const Duration(minutes: 10),
          createdAt: DateTime.now(),
          createdBy: 'system',
          isPublished: true,
        );
        tests.add(defaultTest);
      }

      emit(TestsLoaded(tests: tests));
    } catch (e) {
      emit(QuizError(message: 'Failed to load tests: ${e.toString()}'));
    }
  }

  Future<void> _onLoadTestQuestions(
    LoadTestQuestions event,
    Emitter<QuizState> emit,
  ) async {
    emit(QuizLoading());
    try {
      List<TestQuestion> questions = [];

      if (event.testId == 'default_test') {
        // Load questions from the existing question_json.dart file
        questions = _loadDefaultQuestions();
      } else {
        // Load questions from Firestore
        final querySnapshot = await _firestore
            .collection('questions')
            .where('testId', isEqualTo: event.testId)
            .get();

        questions = querySnapshot.docs
            .map((doc) => TestQuestion.fromFirestore(doc))
            .toList();
      }

      if (questions.isEmpty) {
        emit(const QuizError(message: 'No questions found for this test'));
        return;
      }

      // Get test config
      TestConfig? testConfig;
      if (event.testId == 'default_test') {
        testConfig = TestConfig(
          id: 'default_test',
          title: 'Sample Quiz',
          description: 'A sample computer-based test',
          category: 'General',
          questionCount: questions.length,
          timeLimit: const Duration(minutes: 10),
          createdAt: DateTime.now(),
          createdBy: 'system',
          isPublished: true,
        );
      } else {
        final doc =
            await _firestore.collection('test_configs').doc(event.testId).get();
        if (doc.exists) {
          testConfig = TestConfig.fromFirestore(doc);
        }
      }

      if (testConfig == null) {
        emit(const QuizError(message: 'Test configuration not found'));
        return;
      }

      emit(TestReady(testConfig: testConfig, questions: questions));
    } catch (e) {
      emit(QuizError(message: 'Failed to load questions: ${e.toString()}'));
    }
  }

  Future<void> _onStartTestSession(
    StartTestSession event,
    Emitter<QuizState> emit,
  ) async {
    try {
      // Shuffle questions if required
      List<TestQuestion> questions = List.from(event.questions);
      if (event.testConfig.shuffleQuestions) {
        questions.shuffle(Random());
      }

      // Limit questions if needed
      if (event.testConfig.questionCount > 0 &&
          questions.length > event.testConfig.questionCount) {
        questions = questions.take(event.testConfig.questionCount).toList();
      }

      // Normalize userId (registration number) for consistent storage
      final normalizedUserId = _normalizeRegistrationNumber(event.userId);

      // Create test session
      final session = TestSession(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: normalizedUserId, // Store normalized version
        testId: event.testConfig.id,
        testTitle: event.testConfig.title,
        startTime: DateTime.now(),
        totalQuestions: questions.length,
        timeLimit: event.testConfig.timeLimit,
      );

      // Save session to Firestore
      await _firestore
          .collection('test_sessions')
          .doc(session.id)
          .set(session.toFirestore());

      // Start timer
      _startTimer(event.testConfig.timeLimit);

      emit(TestInProgress(
        session: session,
        questions: questions,
        currentQuestionIndex: 0,
        remainingTime: event.testConfig.timeLimit,
        answers: {},
      ));
    } catch (e) {
      emit(QuizError(message: 'Failed to start test: ${e.toString()}'));
    }
  }

  Future<void> _onAnswerQuestion(
    AnswerQuestion event,
    Emitter<QuizState> emit,
  ) async {
    if (state is! TestInProgress) return;

    final currentState = state as TestInProgress;
    final question = currentState.questions.firstWhere(
      (q) => q.id == event.questionId,
    );

    final answer = TestAnswer(
      questionId: event.questionId,
      selectedAnswerIndex: event.selectedAnswerIndex,
      isCorrect: event.selectedAnswerIndex == question.correctAnswerIndex,
      answeredAt: DateTime.now(),
      timeSpent: event.timeSpent,
    );

    final updatedAnswers = Map<String, TestAnswer>.from(currentState.answers);
    updatedAnswers[event.questionId] = answer;

    // Update session in Firestore
    final updatedSession = currentState.session.copyWith(
      answers: updatedAnswers.values.toList(),
    );

    try {
      await _firestore
          .collection('test_sessions')
          .doc(currentState.session.id)
          .update(updatedSession.toFirestore());

      emit(currentState.copyWith(
        session: updatedSession,
        answers: updatedAnswers,
      ));
    } catch (e) {
      emit(QuizError(message: 'Failed to save answer: ${e.toString()}'));
    }
  }

  void _onNextQuestion(NextQuestion event, Emitter<QuizState> emit) {
    if (state is! TestInProgress) return;

    final currentState = state as TestInProgress;
    if (!currentState.isLastQuestion) {
      emit(currentState.copyWith(
        currentQuestionIndex: currentState.currentQuestionIndex + 1,
      ));
    }
  }

  void _onPreviousQuestion(PreviousQuestion event, Emitter<QuizState> emit) {
    if (state is! TestInProgress) return;

    final currentState = state as TestInProgress;
    if (!currentState.isFirstQuestion) {
      emit(currentState.copyWith(
        currentQuestionIndex: currentState.currentQuestionIndex - 1,
      ));
    }
  }

  void _onJumpToQuestion(JumpToQuestion event, Emitter<QuizState> emit) {
    if (state is! TestInProgress) return;

    final currentState = state as TestInProgress;
    if (event.questionIndex >= 0 &&
        event.questionIndex < currentState.questions.length) {
      emit(currentState.copyWith(
        currentQuestionIndex: event.questionIndex,
      ));
    }
  }

  Future<void> _onSubmitTest(SubmitTest event, Emitter<QuizState> emit) async {
    if (state is! TestInProgress) return;

    final currentState = state as TestInProgress;
    _timer?.cancel();

    try {
      // Calculate final score
      final totalQuestions = currentState.questions.length;
      final correctAnswers = currentState.answers.values
          .where((answer) => answer.isCorrect)
          .length;
      final percentage = (correctAnswers / totalQuestions) * 100;

      // Update session with final results
      final completedSession = currentState.session.copyWith(
        endTime: DateTime.now(),
        isCompleted: true,
        score: correctAnswers,
        percentage: percentage,
        timeSpent: currentState.session.timeLimit! - currentState.remainingTime,
        answers: currentState.answers.values.toList(),
      );

      // Save final session to Firestore
      await _firestore
          .collection('test_sessions')
          .doc(currentState.session.id)
          .update(completedSession.toFirestore());

      emit(TestCompleted(
        completedSession: completedSession,
        questions: currentState.questions,
        answers: currentState.answers,
      ));
    } catch (e) {
      emit(QuizError(message: 'Failed to submit test: ${e.toString()}'));
    }
  }

  void _onUpdateTimer(UpdateTimer event, Emitter<QuizState> emit) {
    if (state is TestInProgress) {
      final currentState = state as TestInProgress;

      if (event.remainingTime.inSeconds <= 0) {
        // Time's up, auto-submit
        add(SubmitTest());
      } else {
        emit(currentState.copyWith(remainingTime: event.remainingTime));
      }
    }
  }

  Future<void> _onLoadTestHistory(
    LoadTestHistory event,
    Emitter<QuizState> emit,
  ) async {
    emit(QuizLoading());
    try {
      // Normalize the userId (registration number) for consistent querying
      final normalizedUserId = _normalizeRegistrationNumber(event.userId);

      final querySnapshot = await _firestore
          .collection('test_sessions')
          .where('userId', isEqualTo: normalizedUserId)
          .where('isCompleted', isEqualTo: true)
          .orderBy('startTime', descending: true)
          .get();

      final sessions = querySnapshot.docs
          .map((doc) => TestSession.fromFirestore(doc))
          .toList();

      emit(TestHistoryLoaded(sessions: sessions));
    } catch (e) {
      emit(QuizError(message: 'Failed to load test history: ${e.toString()}'));
    }
  }

  Future<void> _onLoadTestSession(
    LoadTestSession event,
    Emitter<QuizState> emit,
  ) async {
    emit(QuizLoading());
    try {
      final doc = await _firestore
          .collection('test_sessions')
          .doc(event.sessionId)
          .get();

      if (!doc.exists) {
        emit(const QuizError(message: 'Test session not found'));
        return;
      }

      final session = TestSession.fromFirestore(doc);

      // Load questions (simplified for demo)
      final questions = _loadDefaultQuestions();

      // Create answers map
      final answers = <String, TestAnswer>{};
      for (final answer in session.answers) {
        answers[answer.questionId] = answer;
      }

      emit(TestSessionLoaded(
        session: session,
        questions: questions,
        answers: answers,
      ));
    } catch (e) {
      emit(QuizError(message: 'Failed to load test session: ${e.toString()}'));
    }
  }

  void _startTimer(Duration duration) {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = duration - Duration(seconds: timer.tick);
      add(UpdateTimer(remainingTime: remaining));
    });
  }

  List<TestQuestion> _loadDefaultQuestions() {
    // Convert existing questions from question_json.dart
    final List<Map<String, dynamic>> rawQuestions = question_data.questions;
    return rawQuestions.asMap().entries.map((entry) {
      final index = entry.key;
      final question = entry.value;

      return TestQuestion(
        id: 'q_$index',
        questionText: question['question'] ?? '',
        options: List<String>.from(question['options'] ?? []),
        correctAnswerIndex: question['correctIndex'] ?? 0,
        category: 'General',
        points: 1,
      );
    }).toList();
  }

  // Helper method for registration number normalization
  String _normalizeRegistrationNumber(String regNo) {
    // Convert format like "2019/240045" to "2019_240045" for document IDs
    return regNo.replaceAll('/', '_');
  }
}
