import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:monami/question/bloc/bloc.dart';
import 'package:monami/core/models/cbt_models.dart';

class QuestionManagementView extends StatefulWidget {
  const QuestionManagementView({super.key});

  @override
  State<QuestionManagementView> createState() => _QuestionManagementViewState();
}

class _QuestionManagementViewState extends State<QuestionManagementView> {
  final _searchController = TextEditingController();
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    context.read<QuestionBloc>().add(const LoadQuestions());
    context.read<QuestionBloc>().add(LoadCategories());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Question Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddQuestionDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadQuestions(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and filter section
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Search bar
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search questions...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _loadQuestions();
                        },
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      if (value.isEmpty) {
                        _loadQuestions();
                      }
                    },
                    onSubmitted: (value) {
                      if (value.isNotEmpty) {
                        context
                            .read<QuestionBloc>()
                            .add(SearchQuestions(searchTerm: value));
                      } else {
                        _loadQuestions();
                      }
                    },
                  ),

                  const SizedBox(height: 16),

                  // Filter dropdowns
                  Row(
                    children: [
                      Expanded(
                        child: BlocBuilder<QuestionBloc, QuestionState>(
                          builder: (context, state) {
                            List<String> categories = ['All'];
                            if (state is CategoriesLoaded) {
                              categories.addAll(state.categories);
                            }

                            return DropdownButtonFormField<String>(
                              value: _selectedCategory,
                              decoration: const InputDecoration(
                                labelText: 'Category',
                                border: OutlineInputBorder(),
                              ),
                              items: categories.map((category) {
                                return DropdownMenuItem(
                                  value: category,
                                  child: Text(category),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedCategory = value ?? 'All';
                                });
                                _loadQuestions();
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Questions list
          Expanded(
            child: BlocBuilder<QuestionBloc, QuestionState>(
              builder: (context, state) {
                if (state is QuestionLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is QuestionError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Error: ${state.message}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadQuestions,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                } else if (state is QuestionsLoaded) {
                  if (state.questions.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.quiz, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('No questions found'),
                          Text('Upload some questions to get started'),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: state.questions.length,
                    itemBuilder: (context, index) {
                      final question = state.questions[index];
                      return _buildQuestionCard(question);
                    },
                  );
                } else if (state is QuestionSearchResults) {
                  if (state.results.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.search_off,
                              size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text('No results found for "${state.searchTerm}"'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              _searchController.clear();
                              _loadQuestions();
                            },
                            child: const Text('Clear Search'),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: state.results.length,
                    itemBuilder: (context, index) {
                      final question = state.results[index];
                      return _buildQuestionCard(question);
                    },
                  );
                }

                return const Center(child: Text('Loading questions...'));
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(TestQuestion question) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        title: Text(
          question.questionText,
          style: const TextStyle(fontWeight: FontWeight.bold),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  question.category,
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Spacer(),
              Text('${question.points} pts'),
            ],
          ),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleQuestionAction(value, question),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete'),
                ],
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (question.imageUrl != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      question.imageUrl!,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 150,
                          color: Colors.grey[200],
                          child: const Center(
                            child: Text('Image not available'),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                const Text(
                  'Options:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...question.options.asMap().entries.map((entry) {
                  final index = entry.key;
                  final option = entry.value;
                  final isCorrect = index == question.correctAnswerIndex;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isCorrect ? Colors.green.shade50 : null,
                      borderRadius: BorderRadius.circular(4),
                      border: isCorrect
                          ? Border.all(color: Colors.green.shade300)
                          : Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: isCorrect ? Colors.green : Colors.grey[300],
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              String.fromCharCode(65 + index), // A, B, C, D
                              style: TextStyle(
                                color: isCorrect ? Colors.white : Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(option)),
                        if (isCorrect)
                          Icon(Icons.check_circle,
                              color: Colors.green.shade600),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _loadQuestions() {
    context.read<QuestionBloc>().add(LoadQuestions(
          category: _selectedCategory == 'All' ? null : _selectedCategory,
        ));
  }

  void _handleQuestionAction(String action, TestQuestion question) {
    switch (action) {
      case 'edit':
        _showEditQuestionDialog(question);
        break;
      case 'delete':
        _showDeleteConfirmation(question);
        break;
    }
  }

  void _showAddQuestionDialog() {
    // TODO: Implement add question dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add question dialog coming soon!')),
    );
  }

  void _showEditQuestionDialog(TestQuestion question) {
    // TODO: Implement edit question dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit question dialog coming soon!')),
    );
  }

  void _showDeleteConfirmation(TestQuestion question) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Question'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to delete this question?'),
            const SizedBox(height: 12),
            Text(
              question.questionText,
              style: const TextStyle(fontStyle: FontStyle.italic),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
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
              context
                  .read<QuestionBloc>()
                  .add(DeleteQuestion(questionId: question.id));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
