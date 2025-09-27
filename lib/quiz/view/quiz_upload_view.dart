import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import '../question/question/question_bloc.dart';
import '../question/question/question_event.dart';
import '../question/question/question_state.dart';
import '../utils/responsive_utils.dart';

class WebCsvUploadScreen extends StatefulWidget {
  const WebCsvUploadScreen({super.key});

  @override
  State<WebCsvUploadScreen> createState() => _WebCsvUploadScreenState();
}

class _WebCsvUploadScreenState extends State<WebCsvUploadScreen> {
  final _categoryController = TextEditingController();
  String _selectedCategory = '';

  @override
  void initState() {
    super.initState();
    _categoryController.text = _selectedCategory;
  }

  @override
  void dispose() {
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> startFilePicker() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.bytes != null) {
        final bytes = result.files.single.bytes!;
        final content = utf8.decode(bytes);
        _validateAndUploadCSV(content);
      } else if (result != null && result.files.single.path != null) {
        // Fallback for platforms that provide file path instead of bytes
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'File reading from path not supported on this platform. Please try web version.'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking file: $e')),
      );
    }
  }

  void _validateAndUploadCSV(String content) {
    // Store the content for later upload
    _currentCSVContent = content;
    // First validate the CSV
    context.read<QuestionBloc>().add(ValidateCSV(csvContent: content));
  }

  void _uploadQuestions(String csvContent) {
    if (_selectedCategory.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a course name'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    context.read<QuestionBloc>().add(
          UploadQuestionsFromCSV(
            csvContent: csvContent,
            category: _selectedCategory.trim(),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Questions'),
        elevation: 0,
      ),
      body: BlocListener<QuestionBloc, QuestionState>(
        listener: (context, state) {
          if (state is QuestionUploadCompleted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state is QuestionError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: SingleChildScrollView(
          padding: ResponsiveUtils.getResponsivePadding(context),
          child: ResponsiveContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Instructions
                ResponsiveCard(
                  child: Padding(
                    padding: ResponsiveUtils.getResponsivePadding(context),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CSV Upload Instructions',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Your CSV file should have the following format:',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Question,Option1,Option2,Option3,Option4,CorrectIndex\n'
                            'What is 2+2?,2,3,4,5,2\n'
                            'Capital of France?,London,Paris,Berlin,Madrid,1',
                            style: TextStyle(fontFamily: 'monospace'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                            '• CorrectIndex: 0=Option1, 1=Option2, 2=Option3, 3=Option4'),
                        const Text('• First row should be the header'),
                        const Text('• All fields are required'),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Configuration
                ResponsiveCard(
                  child: Padding(
                    padding: ResponsiveUtils.getResponsivePadding(context),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Question Configuration',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 16),

                        // Course name text field
                        TextFormField(
                          controller: _categoryController,
                          decoration: const InputDecoration(
                            labelText: 'Course Name',
                            hintText:
                                'e.g., Biochemistry, Pharmacology, Anatomy',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.book),
                            helperText:
                                'Enter the course/subject name for these questions',
                          ),
                          onChanged: (value) {
                            setState(() {
                              _selectedCategory = value;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a course name';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Upload section
                BlocBuilder<QuestionBloc, QuestionState>(
                  builder: (context, state) {
                    if (state is QuestionLoading) {
                      return const Center(
                        child: Column(
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Processing...'),
                          ],
                        ),
                      );
                    }

                    if (state is QuestionUploadInProgress) {
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Text(
                                'Uploading Questions',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 16),
                              LinearProgressIndicator(value: state.progress),
                              const SizedBox(height: 8),
                              Text(
                                  '${state.uploaded}/${state.total} questions uploaded'),
                              const SizedBox(height: 4),
                              Text(state.currentStatus),
                            ],
                          ),
                        ),
                      );
                    }

                    if (state is CSVValidated) {
                      return Column(
                        children: [
                          if (state.hasErrors) ...[
                            Card(
                              color: Colors.red.shade50,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Validation Errors',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red.shade700,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ...state.errors.map((error) => Text(
                                          '• $error',
                                          style: TextStyle(
                                              color: Colors.red.shade700),
                                        )),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          if (state.isValid) ...[
                            Card(
                              color: Colors.green.shade50,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    Text(
                                      'Validation Successful!',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green.shade700,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                        'Found ${state.validQuestions.length} valid questions'),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: () => _uploadQuestions(
                                          _currentCSVContent ?? ''),
                                      child: const Text('Upload Questions'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ],
                      );
                    }

                    return Column(
                      children: [
                        ElevatedButton.icon(
                          onPressed: startFilePicker,
                          icon: const Icon(Icons.upload_file),
                          label: const Text('Select CSV File'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Select a CSV file to validate and upload questions',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _currentCSVContent;
}
