import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Question model for computer-based tests
class TestQuestion extends Equatable {
  final String id;
  final String questionText;
  final List<String> options;
  final int correctAnswerIndex;
  final String category;
  final int points;
  final String? imageUrl;

  const TestQuestion({
    required this.id,
    required this.questionText,
    required this.options,
    required this.correctAnswerIndex,
    required this.category,
    this.points = 1,
    this.imageUrl,
  });

  factory TestQuestion.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TestQuestion(
      id: doc.id,
      questionText: data['questionText'] ?? '',
      options: List<String>.from(data['options'] ?? []),
      correctAnswerIndex: data['correctAnswerIndex'] ?? 0,
      category: data['category'] ?? '',
      points: data['points'] ?? 1,
      imageUrl: data['imageUrl'],
    );
  }

  factory TestQuestion.fromJson(Map<String, dynamic> json) {
    return TestQuestion(
      id: json['id'] ?? '',
      questionText: json['question'] ?? json['questionText'] ?? '',
      options: List<String>.from(json['options'] ?? []),
      correctAnswerIndex:
          json['correctIndex'] ?? json['correctAnswerIndex'] ?? 0,
      category: json['category'] ?? '',
      points: json['points'] ?? 1,
      imageUrl: json['imageUrl'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'questionText': questionText,
      'options': options,
      'correctAnswerIndex': correctAnswerIndex,
      'category': category,
      'points': points,
      'imageUrl': imageUrl,
    };
  }

  @override
  List<Object?> get props => [
        id,
        questionText,
        options,
        correctAnswerIndex,
        category,
        points,
        imageUrl,
      ];
}

// Test session model
class TestSession extends Equatable {
  final String id;
  final String userId;
  final String testId;
  final String testTitle;
  final DateTime startTime;
  final DateTime? endTime;
  final List<TestAnswer> answers;
  final bool isCompleted;
  final int totalQuestions;
  final int? score;
  final double? percentage;
  final Duration? timeSpent;
  final Duration? timeLimit;

  const TestSession({
    required this.id,
    required this.userId,
    required this.testId,
    required this.testTitle,
    required this.startTime,
    this.endTime,
    this.answers = const [],
    this.isCompleted = false,
    required this.totalQuestions,
    this.score,
    this.percentage,
    this.timeSpent,
    this.timeLimit,
  });

  factory TestSession.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TestSession(
      id: doc.id,
      userId: data['userId'] ?? '',
      testId: data['testId'] ?? '',
      testTitle: data['testTitle'] ?? '',
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: data['endTime'] != null
          ? (data['endTime'] as Timestamp).toDate()
          : null,
      answers: (data['answers'] as List<dynamic>?)
              ?.map((answer) =>
                  TestAnswer.fromMap(answer as Map<String, dynamic>))
              .toList() ??
          [],
      isCompleted: data['isCompleted'] ?? false,
      totalQuestions: data['totalQuestions'] ?? 0,
      score: data['score'],
      percentage: data['percentage']?.toDouble(),
      timeSpent: data['timeSpent'] != null
          ? Duration(seconds: data['timeSpent'])
          : null,
      timeLimit: data['timeLimit'] != null
          ? Duration(seconds: data['timeLimit'])
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'testId': testId,
      'testTitle': testTitle,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'answers': answers.map((answer) => answer.toMap()).toList(),
      'isCompleted': isCompleted,
      'totalQuestions': totalQuestions,
      'score': score,
      'percentage': percentage,
      'timeSpent': timeSpent?.inSeconds,
      'timeLimit': timeLimit?.inSeconds,
    };
  }

  TestSession copyWith({
    String? id,
    String? userId,
    String? testId,
    String? testTitle,
    DateTime? startTime,
    DateTime? endTime,
    List<TestAnswer>? answers,
    bool? isCompleted,
    int? totalQuestions,
    int? score,
    double? percentage,
    Duration? timeSpent,
    Duration? timeLimit,
  }) {
    return TestSession(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      testId: testId ?? this.testId,
      testTitle: testTitle ?? this.testTitle,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      answers: answers ?? this.answers,
      isCompleted: isCompleted ?? this.isCompleted,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      score: score ?? this.score,
      percentage: percentage ?? this.percentage,
      timeSpent: timeSpent ?? this.timeSpent,
      timeLimit: timeLimit ?? this.timeLimit,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        testId,
        testTitle,
        startTime,
        endTime,
        answers,
        isCompleted,
        totalQuestions,
        score,
        percentage,
        timeSpent,
        timeLimit,
      ];
}

// Test answer model
class TestAnswer extends Equatable {
  final String questionId;
  final int selectedAnswerIndex;
  final bool isCorrect;
  final DateTime answeredAt;
  final Duration timeSpent;

  const TestAnswer({
    required this.questionId,
    required this.selectedAnswerIndex,
    required this.isCorrect,
    required this.answeredAt,
    required this.timeSpent,
  });

  factory TestAnswer.fromMap(Map<String, dynamic> map) {
    return TestAnswer(
      questionId: map['questionId'] ?? '',
      selectedAnswerIndex: map['selectedAnswerIndex'] ?? -1,
      isCorrect: map['isCorrect'] ?? false,
      answeredAt: map['answeredAt'] != null
          ? (map['answeredAt'] as Timestamp).toDate()
          : DateTime.now(),
      timeSpent: Duration(seconds: map['timeSpent'] ?? 0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'questionId': questionId,
      'selectedAnswerIndex': selectedAnswerIndex,
      'isCorrect': isCorrect,
      'answeredAt': Timestamp.fromDate(answeredAt),
      'timeSpent': timeSpent.inSeconds,
    };
  }

  @override
  List<Object?> get props => [
        questionId,
        selectedAnswerIndex,
        isCorrect,
        answeredAt,
        timeSpent,
      ];
}

// Test configuration model
class TestConfig extends Equatable {
  final String id;
  final String title;
  final String description;
  final String category;
  final int questionCount;
  final Duration timeLimit;
  final bool shuffleQuestions;
  final bool shuffleOptions;
  final bool showResults;
  final double passingScore; // percentage
  final List<String> questionIds;
  final DateTime createdAt;
  final String createdBy;
  final bool isPublished;

  const TestConfig({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.questionCount,
    required this.timeLimit,
    this.shuffleQuestions = true,
    this.shuffleOptions = false,
    this.showResults = true,
    this.passingScore = 60.0,
    this.questionIds = const [],
    required this.createdAt,
    required this.createdBy,
    this.isPublished = false,
  });

  factory TestConfig.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TestConfig(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      questionCount: data['questionCount'] ?? 0,
      timeLimit: Duration(seconds: data['timeLimit'] ?? 0),
      shuffleQuestions: data['shuffleQuestions'] ?? true,
      shuffleOptions: data['shuffleOptions'] ?? false,
      showResults: data['showResults'] ?? true,
      passingScore: (data['passingScore'] ?? 60.0).toDouble(),
      questionIds: List<String>.from(data['questionIds'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      createdBy: data['createdBy'] ?? '',
      isPublished: data['isPublished'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'questionCount': questionCount,
      'timeLimit': timeLimit.inSeconds,
      'shuffleQuestions': shuffleQuestions,
      'shuffleOptions': shuffleOptions,
      'showResults': showResults,
      'passingScore': passingScore,
      'questionIds': questionIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'isPublished': isPublished,
    };
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        category,
        questionCount,
        timeLimit,
        shuffleQuestions,
        shuffleOptions,
        showResults,
        passingScore,
        questionIds,
        createdAt,
        createdBy,
        isPublished,
      ];
}
