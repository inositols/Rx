import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:monami/core/models/cbt_models.dart';

import 'question_event.dart';
import 'question_state.dart';

class QuestionBloc extends Bloc<QuestionEvent, QuestionState> {
  final FirebaseFirestore _firestore;

  QuestionBloc({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        super(QuestionInitial()) {
    on<LoadQuestions>(_onLoadQuestions);
    on<UploadQuestionsFromCSV>(_onUploadQuestionsFromCSV);
    on<AddQuestion>(_onAddQuestion);
    on<UpdateQuestion>(_onUpdateQuestion);
    on<DeleteQuestion>(_onDeleteQuestion);
    on<LoadQuestionsByIds>(_onLoadQuestionsByIds);
    on<SearchQuestions>(_onSearchQuestions);
    on<LoadCategories>(_onLoadCategories);
    on<ValidateCSV>(_onValidateCSV);
  }

  Future<void> _onLoadQuestions(
    LoadQuestions event,
    Emitter<QuestionState> emit,
  ) async {
    emit(QuestionLoading());
    try {
      Query query = _firestore.collection('questions');

      // Apply filters
      if (event.category != null && event.category!.isNotEmpty) {
        query = query.where('category', isEqualTo: event.category);
      }

      // Apply limit
      if (event.limit != null && event.limit! > 0) {
        query = query.limit(event.limit!);
      }

      final querySnapshot = await query.get();
      final questions = querySnapshot.docs
          .map((doc) => TestQuestion.fromFirestore(doc))
          .toList();

      // Get total count for pagination
      final totalQuery = _firestore.collection('questions');
      final totalSnapshot = await totalQuery.get();
      final totalCount = totalSnapshot.docs.length;

      emit(QuestionsLoaded(
        questions: questions,
        totalCount: totalCount,
        category: event.category,
      ));
    } catch (e) {
      emit(QuestionError(
        message: 'Failed to load questions: ${e.toString()}',
        errorType: QuestionErrorType.network,
      ));
    }
  }

  Future<void> _onUploadQuestionsFromCSV(
    UploadQuestionsFromCSV event,
    Emitter<QuestionState> emit,
  ) async {
    try {
      // First validate the CSV
      final validationResult = _validateCSVContent(event.csvContent);
      if (validationResult['errors'].isNotEmpty) {
        emit(QuestionError(
          message:
              'CSV validation failed: ${validationResult['errors'].join(', ')}',
          errorType: QuestionErrorType.csvFormat,
        ));
        return;
      }

      final rows = validationResult['rows'] as List<List<dynamic>>;
      final questionsToUpload = <TestQuestion>[];

      // Skip header row and process data rows
      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.length >= 6) {
          final question = TestQuestion(
            id: '', // Will be set by Firestore
            questionText: row[0].toString().trim(),
            options: [
              row[1].toString().trim(),
              row[2].toString().trim(),
              row[3].toString().trim(),
              row[4].toString().trim(),
            ],
            correctAnswerIndex: int.tryParse(row[5].toString()) ?? 0,
            category: event.category,
          );
          questionsToUpload.add(question);
        }
      }

      if (questionsToUpload.isEmpty) {
        emit(const QuestionError(
          message: 'No valid questions found in CSV',
          errorType: QuestionErrorType.validation,
        ));
        return;
      }

      // Upload questions with progress updates
      final batch = _firestore.batch();
      for (int i = 0; i < questionsToUpload.length; i++) {
        final question = questionsToUpload[i];
        final docRef = _firestore.collection('questions').doc();
        batch.set(docRef, question.toFirestore());

        // Emit progress update every 10 questions or at the end
        if ((i + 1) % 10 == 0 || i == questionsToUpload.length - 1) {
          emit(QuestionUploadInProgress(
            uploaded: i + 1,
            total: questionsToUpload.length,
            currentStatus:
                'Uploading question ${i + 1} of ${questionsToUpload.length}',
          ));
        }
      }

      // Commit the batch
      await batch.commit();

      emit(QuestionUploadCompleted(
        totalUploaded: questionsToUpload.length,
        message: 'Successfully uploaded ${questionsToUpload.length} questions',
      ));
    } catch (e) {
      emit(QuestionError(
        message: 'Failed to upload questions: ${e.toString()}',
        errorType: QuestionErrorType.network,
      ));
    }
  }

  Future<void> _onAddQuestion(
    AddQuestion event,
    Emitter<QuestionState> emit,
  ) async {
    emit(QuestionLoading());
    try {
      await _firestore
          .collection('questions')
          .add(event.question.toFirestore());

      emit(const QuestionOperationCompleted(
        message: 'Question added successfully',
        operationType: QuestionOperationType.add,
      ));
    } catch (e) {
      emit(QuestionError(
        message: 'Failed to add question: ${e.toString()}',
        errorType: QuestionErrorType.network,
      ));
    }
  }

  Future<void> _onUpdateQuestion(
    UpdateQuestion event,
    Emitter<QuestionState> emit,
  ) async {
    emit(QuestionLoading());
    try {
      await _firestore
          .collection('questions')
          .doc(event.question.id)
          .update(event.question.toFirestore());

      emit(const QuestionOperationCompleted(
        message: 'Question updated successfully',
        operationType: QuestionOperationType.update,
      ));
    } catch (e) {
      emit(QuestionError(
        message: 'Failed to update question: ${e.toString()}',
        errorType: QuestionErrorType.network,
      ));
    }
  }

  Future<void> _onDeleteQuestion(
    DeleteQuestion event,
    Emitter<QuestionState> emit,
  ) async {
    emit(QuestionLoading());
    try {
      await _firestore.collection('questions').doc(event.questionId).delete();

      emit(const QuestionOperationCompleted(
        message: 'Question deleted successfully',
        operationType: QuestionOperationType.delete,
      ));
    } catch (e) {
      emit(QuestionError(
        message: 'Failed to delete question: ${e.toString()}',
        errorType: QuestionErrorType.network,
      ));
    }
  }

  Future<void> _onLoadQuestionsByIds(
    LoadQuestionsByIds event,
    Emitter<QuestionState> emit,
  ) async {
    emit(QuestionLoading());
    try {
      final questions = <TestQuestion>[];

      // Load questions in batches (Firestore 'in' query limit is 10)
      for (int i = 0; i < event.questionIds.length; i += 10) {
        final batchIds = event.questionIds.skip(i).take(10).toList();
        final querySnapshot = await _firestore
            .collection('questions')
            .where(FieldPath.documentId, whereIn: batchIds)
            .get();

        final batchQuestions = querySnapshot.docs
            .map((doc) => TestQuestion.fromFirestore(doc))
            .toList();
        questions.addAll(batchQuestions);
      }

      emit(QuestionsLoaded(
        questions: questions,
        totalCount: questions.length,
      ));
    } catch (e) {
      emit(QuestionError(
        message: 'Failed to load questions: ${e.toString()}',
        errorType: QuestionErrorType.network,
      ));
    }
  }

  Future<void> _onSearchQuestions(
    SearchQuestions event,
    Emitter<QuestionState> emit,
  ) async {
    emit(QuestionLoading());
    try {
      // Note: Firestore doesn't support full-text search natively
      // This is a basic implementation that searches in question text
      final querySnapshot = await _firestore.collection('questions').get();

      final allQuestions = querySnapshot.docs
          .map((doc) => TestQuestion.fromFirestore(doc))
          .toList();

      final searchTerm = event.searchTerm.toLowerCase();
      final filteredQuestions = allQuestions.where((question) {
        return question.questionText.toLowerCase().contains(searchTerm) ||
            question.category.toLowerCase().contains(searchTerm) ||
            question.options
                .any((option) => option.toLowerCase().contains(searchTerm));
      }).toList();

      emit(QuestionSearchResults(
        results: filteredQuestions,
        searchTerm: event.searchTerm,
      ));
    } catch (e) {
      emit(QuestionError(
        message: 'Failed to search questions: ${e.toString()}',
        errorType: QuestionErrorType.network,
      ));
    }
  }

  Future<void> _onLoadCategories(
    LoadCategories event,
    Emitter<QuestionState> emit,
  ) async {
    emit(QuestionLoading());
    try {
      final querySnapshot = await _firestore.collection('questions').get();

      final categories = <String>{};
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final category = data['category']?.toString();
        if (category != null && category.isNotEmpty) {
          categories.add(category);
        }
      }

      emit(CategoriesLoaded(categories: categories.toList()..sort()));
    } catch (e) {
      emit(QuestionError(
        message: 'Failed to load categories: ${e.toString()}',
        errorType: QuestionErrorType.network,
      ));
    }
  }

  Future<void> _onValidateCSV(
    ValidateCSV event,
    Emitter<QuestionState> emit,
  ) async {
    try {
      final result = _validateCSVContent(event.csvContent);
      final rows = result['rows'] as List<List<dynamic>>;
      final errors = result['errors'] as List<String>;

      final validQuestions = <Map<String, dynamic>>[];

      // Process valid rows (skip header)
      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.length >= 6) {
          validQuestions.add({
            'question': row[0].toString().trim(),
            'option1': row[1].toString().trim(),
            'option2': row[2].toString().trim(),
            'option3': row[3].toString().trim(),
            'option4': row[4].toString().trim(),
            'correctIndex': int.tryParse(row[5].toString()) ?? 0,
            'rowIndex': i + 1,
          });
        }
      }

      emit(CSVValidated(
        validQuestions: validQuestions,
        errors: errors,
        totalRows: rows.length - 1, // Exclude header
      ));
    } catch (e) {
      emit(QuestionError(
        message: 'Failed to validate CSV: ${e.toString()}',
        errorType: QuestionErrorType.csvFormat,
      ));
    }
  }

  Map<String, dynamic> _validateCSVContent(String content) {
    final errors = <String>[];
    List<List<dynamic>> rows = [];

    try {
      rows = _parseCsvContent(content);
    } catch (e) {
      errors.add('Invalid CSV format: ${e.toString()}');
      return {'rows': <List<dynamic>>[], 'errors': errors};
    }

    if (rows.isEmpty) {
      errors.add('CSV file is empty');
      return {'rows': rows, 'errors': errors};
    }

    if (rows.length < 2) {
      errors.add('CSV must contain at least a header row and one data row');
      return {'rows': rows, 'errors': errors};
    }

    // Validate header
    final header = rows[0];
    if (header.length < 6) {
      errors.add(
          'Header must contain at least 6 columns: Question, Option1, Option2, Option3, Option4, CorrectIndex');
    }

    // Validate data rows
    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      final rowNum = i + 1;

      if (row.length < 6) {
        errors.add(
            'Row $rowNum: Insufficient columns (expected 6, got ${row.length})');
        continue;
      }

      if (row[0].toString().trim().isEmpty) {
        errors.add('Row $rowNum: Question text is empty');
      }

      for (int j = 1; j <= 4; j++) {
        if (row[j].toString().trim().isEmpty) {
          errors.add('Row $rowNum: Option $j is empty');
        }
      }

      final correctIndex = int.tryParse(row[5].toString());
      if (correctIndex == null || correctIndex < 0 || correctIndex > 3) {
        errors
            .add('Row $rowNum: Correct index must be a number between 0 and 3');
      }
    }

    return {'rows': rows, 'errors': errors};
  }

  // Simple CSV parser used as a fallback so the code compiles without relying
  // on an external CsvToListConverter symbol; supports quoted fields and
  // escaped quotes ("").
  List<List<dynamic>> _parseCsvContent(String content) {
    final result = <List<dynamic>>[];
    if (content.isEmpty) return result;

    final currentField = StringBuffer();
    final currentRow = <dynamic>[];
    bool inQuotes = false;
    int i = 0;
    final len = content.length;

    while (i < len) {
      final char = content[i];

      if (char == '"') {
        if (inQuotes && i + 1 < len && content[i + 1] == '"') {
          // Escaped quote
          currentField.write('"');
          i += 2;
          continue;
        } else {
          inQuotes = !inQuotes;
          i++;
          continue;
        }
      }

      if (!inQuotes && char == ',') {
        currentRow.add(currentField.toString());
        currentField.clear();
        i++;
        continue;
      }

      if (!inQuotes && (char == '\n' || char == '\r')) {
        // End of row
        currentRow.add(currentField.toString());
        currentField.clear();
        result.add(List<dynamic>.from(currentRow));
        currentRow.clear();

        if (char == '\r' && i + 1 < len && content[i + 1] == '\n') {
          i += 2;
        } else {
          i += 1;
        }
        continue;
      }

      currentField.write(char);
      i++;
    }

    // Add any remaining data as the last row
    if (inQuotes) {
      throw FormatException('Unterminated quoted field in CSV');
    }

    if (currentField.isNotEmpty || currentRow.isNotEmpty) {
      currentRow.add(currentField.toString());
      result.add(List<dynamic>.from(currentRow));
    }

    return result;
  }
}
