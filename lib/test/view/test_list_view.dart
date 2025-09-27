import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../auth/bloc/auth_bloc.dart';
import '../auth/bloc/auth_state.dart';
import '../models/cbt_models.dart';
import '../utils/responsive_utils.dart';
import 'test_taking_view.dart';

class TestListView extends StatefulWidget {
  const TestListView({super.key});

  @override
  State<TestListView> createState() => _TestListViewState();
}

class _TestListViewState extends State<TestListView> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<TestQuestion> _questions = [];
  bool _isLoading = true;
  String? _error;
  Map<String, List<TestQuestion>> _questionsByCategory = {};

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Fetch questions from Firestore using TestQuestion model
      final QuerySnapshot querySnapshot =
          await _firestore.collection('questions').get();

      final List<TestQuestion> questions = querySnapshot.docs
          .map((doc) => TestQuestion.fromFirestore(doc))
          .where((question) =>
              question.questionText.isNotEmpty && question.options.isNotEmpty)
          .toList();

      // Group questions by category
      final Map<String, List<TestQuestion>> questionsByCategory = {};
      for (final question in questions) {
        // Use the category from the question model
        final category =
            question.category.isNotEmpty ? question.category : 'General';
        if (!questionsByCategory.containsKey(category)) {
          questionsByCategory[category] = [];
        }
        questionsByCategory[category]!.add(question);
      }

      setState(() {
        _questions = questions;
        _questionsByCategory = questionsByCategory;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load questions: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Tests'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadQuestions,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading questions from Firestore...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadQuestions,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_questions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.quiz, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No questions available'),
            Text('Please add questions to Firestore first'),
          ],
        ),
      );
    }

    return _buildTestList();
  }

  Widget _buildTestList() {
    // Create test cards for each category - only show individual courses
    final categories = _questionsByCategory.keys.toList()..sort();

    // Use responsive layout based on screen size
    if (ResponsiveUtils.shouldUseSplitView(context)) {
      // Grid layout for tablet and desktop
      final columns = ResponsiveUtils.getResponsiveGridColumns(context);
      return GridView.builder(
        padding: ResponsiveUtils.getResponsivePadding(context),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          childAspectRatio: ResponsiveUtils.getResponsiveValue(
            context,
            mobile: 0.8,
            tablet: 0.85,
            desktop: 0.9,
          ),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final categoryQuestions = _questionsByCategory[category]!;

          return _buildTestCard(
            title: '$category',
            description: 'Test covering $category course material',
            category: category,
            questionCount: categoryQuestions.length,
            questions: categoryQuestions,
            color: _getCategoryColor(category),
          );
        },
      );
    } else {
      // List layout for mobile
      return ListView.builder(
        padding: ResponsiveUtils.getResponsivePadding(context),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final categoryQuestions = _questionsByCategory[category]!;

          return _buildTestCard(
            title: '$category',
            description: 'Test covering $category course material',
            category: category,
            questionCount: categoryQuestions.length,
            questions: categoryQuestions,
            color: _getCategoryColor(category),
          );
        },
      );
    }
  }

  Widget _buildTestCard({
    required String title,
    required String description,
    required String category,
    required int questionCount,
    required List<TestQuestion> questions,
    required Color color,
  }) {
    // Calculate estimated duration (1.5 minutes per question)
    final estimatedMinutes = (questionCount * 1.5).ceil();

    return Card(
      margin: ResponsiveUtils.getResponsiveValue(
        context,
        mobile: const EdgeInsets.only(bottom: 16),
        tablet: EdgeInsets.zero,
        desktop: EdgeInsets.zero,
      ),
      elevation: ResponsiveUtils.getResponsiveValue(
        context,
        mobile: 2,
        tablet: 3,
        desktop: 4,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(
            ResponsiveUtils.getResponsiveValue(
              context,
              mobile: 8,
              tablet: 12,
              desktop: 16,
            ),
          ),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Padding(
          padding: ResponsiveUtils.getResponsivePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      category,
                      style: TextStyle(
                        color: Colors.amber,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '$questionCount Questions',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.access_time,
                          size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '~$estimatedMinutes min',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.quiz, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '$questionCount questions',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () => _startTest(title, questions),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                    ),
                    child: const Text('Start Test',
                        style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    // Generate colors based on course name hash for consistency
    final hash = category.toLowerCase().hashCode;
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.pink,
      Colors.indigo,
      Colors.teal,
      Colors.red,
      Colors.amber,
      Colors.cyan,
    ];
    return colors[hash.abs() % colors.length];
  }

  void _startTest(String testTitle, List<TestQuestion> questions) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Start $testTitle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Questions: ${questions.length}'),
            Text(
                'Estimated Duration: ${(questions.length * 1.5).ceil()} minutes'),
            const SizedBox(height: 16),
            const Text(
              'Instructions:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text('• Answer all questions to the best of your ability'),
            const Text('• You can navigate between questions'),
            const Text('• Review your answers before submitting'),
            const Text('• Click "Submit Test" when you are done'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _navigateToTest(testTitle, questions);
            },
            child: const Text('Start'),
          ),
        ],
      ),
    );
  }

  void _navigateToTest(String testTitle, List<TestQuestion> questions) {
    // Get current user info
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to take the test')),
      );
      return;
    }

    // Shuffle questions for randomization
    final shuffledQuestions = List<TestQuestion>.from(questions)..shuffle();

    // Navigate to test taking view with the questions
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SimpleTestTakingView(
          testTitle: testTitle,
          questions: shuffledQuestions,
          userInfo: authState.userData,
        ),
      ),
    );
  }
}

// Simple test taking view that works directly with TestQuestion model
class SimpleTestTakingView extends StatefulWidget {
  final String testTitle;
  final List<TestQuestion> questions;
  final Map<String, dynamic> userInfo;

  const SimpleTestTakingView({
    super.key,
    required this.testTitle,
    required this.questions,
    required this.userInfo,
  });

  @override
  State<SimpleTestTakingView> createState() => _SimpleTestTakingViewState();
}

class _SimpleTestTakingViewState extends State<SimpleTestTakingView> {
  int _currentQuestionIndex = 0;
  Map<int, int> _answers = {}; // questionIndex -> selectedOptionIndex
  DateTime? _testStartTime;
  Timer? _timer;
  Duration _elapsedTime = Duration.zero;
  final labels = ['A', 'B', 'C', 'D'];

  @override
  void initState() {
    super.initState();
    _testStartTime = DateTime.now();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedTime = DateTime.now().difference(_testStartTime!);
      });
    });
  }

  String _formatElapsedTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));

    if (hours > 0) {
      return '${twoDigits(hours)}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          final shouldExit = await _showExitDialog();
          if (shouldExit && context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        body: ResponsiveBuilder(
          builder: (context, layoutType) {
            if (layoutType == ResponsiveLayoutType.mobile) {
              return _buildMobileLayout();
            } else {
              return _buildDesktopLayout();
            }
          },
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        // Mobile header with basic info
        Container(
          padding: ResponsiveUtils.getResponsivePadding(context),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () async {
                        final shouldExit = await _showExitDialog();
                        if (shouldExit && context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                      icon: const Icon(Icons.close),
                    ),
                    Expanded(
                      child: Text(
                        widget.testTitle,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _submitTest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Submit'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text(
                          _formatElapsedTime(_elapsedTime),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        const Text('Time Elapsed',
                            style: TextStyle(fontSize: 12)),
                      ],
                    ),
                    Column(
                      children: [
                        Text(
                          '${_answers.length}/${widget.questions.length}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const Text('Answered', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Question content
        Expanded(
          child: SingleChildScrollView(
            padding: ResponsiveUtils.getResponsivePadding(context),
            child: _buildQuestionCard(),
          ),
        ),

        // Bottom navigation
        Container(
          padding: ResponsiveUtils.getResponsivePadding(context),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            border: Border(top: BorderSide(color: Colors.grey[300]!)),
          ),
          child: Column(
            children: [
              Text(
                'Question ${_currentQuestionIndex + 1} of ${widget.questions.length}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 100,
                child: SingleChildScrollView(
                  child: _buildQuestionNavigation(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left sidebar with user details and timer
        Container(
          margin: ResponsiveUtils.getResponsiveMargin(context),
          width: ResponsiveUtils.getResponsiveSidebarWidth(context),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Test title
              Text(
                widget.testTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              // Course indicator
              if (widget.questions.isNotEmpty &&
                  widget.questions.first.category.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.teal[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.teal.shade200),
                  ),
                  child: Text(
                    'Course: ${widget.questions.first.category}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.teal[700],
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 24),

              // User avatar
              const CircleAvatar(
                radius: 50,
                backgroundColor: Colors.teal,
                child: Icon(Icons.person, size: 48, color: Colors.white),
              ),
              const SizedBox(height: 16),

              // User details
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Student Details',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow(
                        'Reg. No:', widget.userInfo['regNo'] ?? 'N/A'),
                    _buildDetailRow(
                        'Level:', widget.userInfo['level'] ?? 'N/A'),
                    _buildDetailRow(
                        'Gender:', widget.userInfo['gender'] ?? 'N/A'),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Timer
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.access_time, color: Colors.blue, size: 32),
                    const SizedBox(height: 8),
                    Text(
                      'Time Elapsed',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatElapsedTime(_elapsedTime),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Progress info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  children: [
                    Text(
                      'Progress',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_answers.length} / ${widget.questions.length}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Questions Answered',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: _answers.length / widget.questions.length,
                      backgroundColor: Colors.grey[300],
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.green),
                    ),
                  ],
                ),
              ),
              const Spacer(),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _submitTest,
                  icon: const Icon(Icons.send),
                  label: const Text('Submit Test'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Main content area
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(top: 24, right: 24, bottom: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Question header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.teal[50],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Question ${_currentQuestionIndex + 1}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                      Text(
                        '${_currentQuestionIndex + 1} / ${widget.questions.length}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                    ],
                  ),
                ),

                // Question content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: _buildQuestionCard(),
                  ),
                ),

                // Question navigation grid
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Question Navigation',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${_currentQuestionIndex + 1} of ${widget.questions.length}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Show navigation grid in a scrollable container for many questions
                      SizedBox(
                        height: widget.questions.length > 25 ? 200 : null,
                        child: widget.questions.length > 25
                            ? SingleChildScrollView(
                                child: _buildQuestionNavigation(),
                              )
                            : _buildQuestionNavigation(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionNavigation() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: List.generate(widget.questions.length, (index) {
        bool isAnswered = _answers[index] != null;
        bool isSelected = index == _currentQuestionIndex;

        // Determine size based on number of questions and screen size
        double buttonSize = ResponsiveUtils.getQuestionNavButtonSize(
            context, widget.questions.length);
        double fontSize = ResponsiveUtils.getResponsiveValue(
          context,
          mobile: widget.questions.length > 50 ? 9 : 11,
          tablet: widget.questions.length > 50 ? 10 : 12,
          desktop: widget.questions.length > 50 ? 10 : 14,
        );

        return GestureDetector(
          onTap: () {
            setState(() {
              _currentQuestionIndex = index;
            });
          },
          child: Container(
            width: buttonSize,
            height: buttonSize,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isAnswered
                  ? Colors.green
                  : isSelected
                      ? Colors.teal
                      : Colors.grey[300],
              borderRadius: BorderRadius.circular(6),
              border:
                  isSelected ? Border.all(color: Colors.teal, width: 2) : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Text(
              '${index + 1}',
              style: TextStyle(
                fontSize: fontSize,
                color: isAnswered || isSelected ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildQuestionCard() {
    final question = widget.questions[_currentQuestionIndex];
    final selectedAnswer = _answers[_currentQuestionIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Question text
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Text(
            question.questionText,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Answer options with better spacing for long lists
        ...question.options.asMap().entries.map((entry) {
          final optionIndex = entry.key;
          final option = entry.value;
          final isSelected = selectedAnswer == optionIndex;
          final label = labels[optionIndex];

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: Material(
              elevation: isSelected ? 4 : 1,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _answers[_currentQuestionIndex] = optionIndex;
                  });
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(minHeight: 60),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.teal[50] : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? Colors.teal : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.teal : Colors.grey[200],
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            option,
                            style: TextStyle(
                              fontSize: 16,
                              color:
                                  isSelected ? Colors.teal[700] : Colors.black,
                              fontWeight: isSelected
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                              height: 1.4,
                            ),
                            textAlign: TextAlign.left,
                          ),
                        ),
                      ),
                      if (isSelected)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Icon(
                            Icons.check_circle,
                            color: Colors.teal,
                            size: 24,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Future<bool> _showExitDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Exit Test'),
            content: const Text(
                'Are you sure you want to exit? Your progress will be lost.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Continue Test'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Exit'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _submitTest() {
    final unansweredCount = widget.questions.length - _answers.length;

    if (unansweredCount > 0) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Submit Test'),
          content: Text(
              'You have $unansweredCount unanswered questions. Submit anyway?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Continue Test'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _processResults();
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      );
    } else {
      _processResults();
    }
  }

  void _processResults() {
    // Calculate results
    int correctAnswers = 0;
    for (int i = 0; i < widget.questions.length; i++) {
      final selectedAnswer = _answers[i];
      if (selectedAnswer == widget.questions[i].correctAnswerIndex) {
        correctAnswers++;
      }
    }

    final percentage = (correctAnswers / widget.questions.length) * 100;
    final timeSpent = DateTime.now().difference(_testStartTime!);

    // Navigate to results page
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => SimpleTestResultView(
          testTitle: widget.testTitle,
          questions: widget.questions,
          answers: _answers,
          correctAnswers: correctAnswers,
          percentage: percentage,
          timeSpent: timeSpent,
          userInfo: widget.userInfo,
        ),
      ),
    );
  }
}

// Simple test result view
class SimpleTestResultView extends StatelessWidget {
  final String testTitle;
  final List<TestQuestion> questions;
  final Map<int, int> answers;
  final int correctAnswers;
  final double percentage;
  final Duration timeSpent;
  final Map<String, dynamic> userInfo;

  const SimpleTestResultView({
    super.key,
    required this.testTitle,
    required this.questions,
    required this.answers,
    required this.correctAnswers,
    required this.percentage,
    required this.timeSpent,
    required this.userInfo,
  });

  @override
  Widget build(BuildContext context) {
    final passed = percentage >= 60.0;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const TestListView()),
            (route) => false,
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Test Results'),
          leading: IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const TestListView()),
              (route) => false,
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Result summary
              Card(
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
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
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
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: passed
                                ? Colors.green.shade200
                                : Colors.red.shade200,
                          ),
                        ),
                        child: Column(
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
                            Text(
                              '$correctAnswers out of ${questions.length} correct',
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
                      _buildDetailRow('Test Title', testTitle),
                      if (questions.isNotEmpty &&
                          questions.first.category.isNotEmpty)
                        _buildDetailRow('Course', questions.first.category),
                      _buildDetailRow(
                          'Student', userInfo['regNo'] ?? 'Unknown'),
                      _buildDetailRow('Time Spent', _formatDuration(timeSpent)),
                      _buildDetailRow('Total Questions', '${questions.length}'),
                      _buildDetailRow('Correct Answers', '$correctAnswers'),
                      _buildDetailRow('Incorrect Answers',
                          '${questions.length - correctAnswers}'),
                      _buildDetailRow(
                          'Score', '${percentage.toStringAsFixed(1)}%'),
                      _buildDetailRow('Status', passed ? 'PASSED' : 'FAILED'),
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
                      onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                            builder: (context) => const TestListView()),
                        (route) => false,
                      ),
                      icon: const Icon(Icons.home),
                      label: const Text('Back to Dashboard'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                            builder: (context) => const TestListView()),
                        (route) => false,
                      ),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Take Another Test'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(value),
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
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }
}
