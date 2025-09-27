import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  AuthBloc({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthSignUpRequested>(_onAuthSignUpRequested);
    on<AuthSignInRequested>(_onAuthSignInRequested);
    on<AuthSignOutRequested>(_onAuthSignOutRequested);
    // New admin events
    on<AdminSignInRequested>(_onAdminSignInRequested);
    on<AdminBulkStudentCreationRequested>(_onAdminBulkStudentCreationRequested);
    // New student events
    on<StudentSignInRequested>(_onStudentSignInRequested);
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        // Get additional user data from Firestore
        final userData = await _getUserData(user.uid);
        // Check if user is admin
        final isAdmin = await _isUserAdmin(user.email ?? '');
        emit(AuthAuthenticated(
          user: user,
          userData: userData,
          isAdmin: isAdmin,
        ));
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onAuthSignUpRequested(
    AuthSignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      // Validate registration number format
      if (!_isValidRegistrationNumber(event.regNo)) {
        throw Exception(
            'Invalid registration number format. Use YYYY/NNNNNN (e.g., 2019/240045)');
      }

      // Create user with email and password
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: event.email,
        password: event.password,
      );

      // Store additional user data in Firestore with normalized regNo as document ID
      final normalizedRegNo = _normalizeRegistrationNumber(event.regNo);
      final userData = {
        'uid': userCredential.user!.uid,
        'email': event.email,
        'level': event.level,
        'gender': event.gender,
        'regNo': event.regNo, // Keep original format for display
        'regNoNormalized': normalizedRegNo, // For querying
        'year': _extractYearFromRegNo(event.regNo),
        'number': _extractNumberFromRegNo(event.regNo),
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('users')
          .doc(normalizedRegNo) // Use normalized version as document ID
          .set(userData);

      if (userCredential.user != null) {
        emit(AuthAuthenticated(
          user: userCredential.user!,
          userData: userData,
        ));
      }
    } catch (e) {
      emit(AuthError(message: 'Sign-up failed: ${e.toString()}'));
    }
  }

  Future<void> _onAuthSignInRequested(
    AuthSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      // Validate registration number format
      if (!_isValidRegistrationNumber(event.regNo)) {
        throw Exception(
            'Invalid registration number format. Use YYYY/NNNNNN (e.g., 2019/240045)');
      }

      // Normalize registration number for document lookup
      final normalizedRegNo = _normalizeRegistrationNumber(event.regNo);

      // Get user email from Firestore using normalized regNo
      final doc =
          await _firestore.collection('users').doc(normalizedRegNo).get();

      if (!doc.exists) {
        throw Exception('Registration number not found');
      }

      final email = doc.data()!['email'] as String;

      // Sign in with email and password
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: event.password,
      );

      if (userCredential.user != null) {
        final userData = doc.data()!;
        emit(AuthAuthenticated(
          user: userCredential.user!,
          userData: userData,
        ));
      }
    } catch (e) {
      emit(AuthError(message: 'Login failed: ${e.toString()}'));
    }
  }

  Future<void> _onAuthSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await _firebaseAuth.signOut();
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(message: 'Sign-out failed: ${e.toString()}'));
    }
  }

  // New admin authentication
  Future<void> _onAdminSignInRequested(
    AdminSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      // Check if user is authorized admin
      if (!await _isUserAdmin(event.email)) {
        throw Exception(
            'Unauthorized: This email is not registered as an admin');
      }

      // Sign in with email and password
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: event.email,
        password: event.password,
      );

      if (userCredential.user != null) {
        final userData = await _getUserData(userCredential.user!.uid);
        emit(AuthAuthenticated(
          user: userCredential.user!,
          userData: userData,
          isAdmin: true,
        ));
      }
    } catch (e) {
      emit(AuthError(message: 'Admin login failed: ${e.toString()}'));
    }
  }

  // Bulk student creation from CSV
  Future<void> _onAdminBulkStudentCreationRequested(
    AdminBulkStudentCreationRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final List<String> errors = [];
      int createdCount = 0;

      // Parse CSV data
      final students = _parseCsvData(event.csvData);

      for (int i = 0; i < students.length; i++) {
        try {
          final student = students[i];
          await _createStudentAccount(
            serialNumber: student['serialNumber']!,
            fullName: student['fullName']!,
            regNo: student['regNo']!,
            level: event.level,
            university: event.university,
          );
          createdCount++;
        } catch (e) {
          errors.add('Row ${i + 1}: ${e.toString()}');
        }
      }

      emit(BulkStudentCreationSuccess(
        createdCount: createdCount,
        errors: errors,
      ));
    } catch (e) {
      emit(AuthError(message: 'Bulk creation failed: ${e.toString()}'));
    }
  }

  // Student registration number only login
  Future<void> _onStudentSignInRequested(
    StudentSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      print('🔍 Student login attempt: ${event.regNo}');

      // Validate registration number format
      if (!_isValidRegistrationNumber(event.regNo)) {
        print('❌ Invalid registration number format: ${event.regNo}');
        throw Exception(
            'Invalid registration number format. Use YYYY/NNNNNN (e.g., 2019/240045)');
      }

      // Normalize registration number for document lookup
      final normalizedRegNo = _normalizeRegistrationNumber(event.regNo);
      print('🔍 Looking for document: $normalizedRegNo in students collection');

      // Get user data from Firestore using normalized regNo
      final doc =
          await _firestore.collection('students').doc(normalizedRegNo).get();

      if (!doc.exists) {
        print('❌ Student not found in students collection: $normalizedRegNo');

        // Try checking users collection as fallback
        final userDoc =
            await _firestore.collection('users').doc(normalizedRegNo).get();
        if (userDoc.exists) {
          print('✅ Found student in users collection instead');
          final userData = userDoc.data()!;
          emit(AuthAuthenticated(
            user: _firebaseAuth.currentUser ??
                await _firebaseAuth
                    .signInAnonymously()
                    .then((result) => result.user!),
            userData: userData,
            isAdmin: false,
          ));
          return;
        }

        throw Exception(
            'Registration number not found. Please contact your class representative.');
      }

      final userData = doc.data()!;
      print('✅ Student found: ${userData['name']}');

      // Create a temporary Firebase Auth user or use anonymous auth
      // For students, we'll use the existing student data directly without creating Firebase Auth users
      emit(AuthAuthenticated(
        user: _firebaseAuth.currentUser ??
            await _firebaseAuth
                .signInAnonymously()
                .then((result) => result.user!),
        userData: userData,
        isAdmin: false,
      ));
    } catch (e) {
      print('❌ Student login error: $e');
      emit(AuthError(message: 'Student login failed: ${e.toString()}'));
    }
  }

  Future<Map<String, dynamic>> _getUserData(String uid) async {
    try {
      // Try to find user data by UID first
      final userQuery = await _firestore
          .collection('users')
          .where('uid', isEqualTo: uid)
          .get();

      if (userQuery.docs.isNotEmpty) {
        return userQuery.docs.first.data();
      }

      // If not found by UID, return basic data
      return {
        'uid': uid,
        'email': _firebaseAuth.currentUser?.email,
      };
    } catch (e) {
      return {
        'uid': uid,
        'email': _firebaseAuth.currentUser?.email,
      };
    }
  }

  // Helper methods for registration number handling
  bool _isValidRegistrationNumber(String regNo) {
    // Check format: YYYY/NNNNNN (4 digits, slash, 6 digits)
    final regExp = RegExp(r'^\d{4}/\d{6}$');
    if (!regExp.hasMatch(regNo)) return false;

    // Additional validation: year should be reasonable (e.g., 2000-2030)
    final year = int.tryParse(regNo.substring(0, 4));
    if (year == null || year < 2000 || year > 2030) return false;

    return true;
  }

  String _normalizeRegistrationNumber(String regNo) {
    // Convert to a format suitable for document ID (replace / with _)
    return regNo.replaceAll('/', '_');
  }

  String _extractYearFromRegNo(String regNo) {
    return regNo.substring(0, 4);
  }

  String _extractNumberFromRegNo(String regNo) {
    return regNo.substring(5); // Skip "YYYY/"
  }

  String _formatRegistrationNumber(String input) {
    // Remove any non-numeric characters except /
    String cleaned = input.replaceAll(RegExp(r'[^\d/]'), '');

    // If no slash and has 10 digits, insert slash after 4th digit
    if (!cleaned.contains('/') && cleaned.length >= 4) {
      cleaned = '${cleaned.substring(0, 4)}/${cleaned.substring(4)}';
    }

    // Limit to 11 characters (YYYY/NNNNNN)
    if (cleaned.length > 11) {
      cleaned = cleaned.substring(0, 11);
    }

    return cleaned;
  }

  // New helper methods for admin functionality
  Future<bool> _isUserAdmin(String email) async {
    try {
      // Check if email exists in admins collection
      final adminDoc = await _firestore.collection('admins').doc(email).get();
      return adminDoc.exists;
    } catch (e) {
      return false;
    }
  }

  List<Map<String, String>> _parseCsvData(String csvData) {
    final lines = csvData.trim().split('\n');
    final students = <Map<String, String>>[];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      // Split by comma and handle quoted fields
      final parts = _parseCsvLine(line);

      if (parts.length >= 3) {
        students.add({
          'serialNumber': parts[0].trim(),
          'fullName': parts[1].trim(),
          'regNo': parts[2].trim(),
        });
      }
    }

    return students;
  }

  List<String> _parseCsvLine(String line) {
    final parts = <String>[];
    bool inQuotes = false;
    String currentPart = '';

    for (int i = 0; i < line.length; i++) {
      final char = line[i];

      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        parts.add(currentPart);
        currentPart = '';
      } else {
        currentPart += char;
      }
    }

    parts.add(currentPart); // Add the last part
    return parts;
  }

  Future<void> _createStudentAccount({
    required String serialNumber,
    required String fullName,
    required String regNo,
    required String level,
    required String university,
  }) async {
    // Validate registration number
    if (!_isValidRegistrationNumber(regNo)) {
      throw Exception('Invalid registration number format: $regNo');
    }

    final normalizedRegNo = _normalizeRegistrationNumber(regNo);

    // Check if student already exists
    final existingStudent =
        await _firestore.collection('students').doc(normalizedRegNo).get();
    if (existingStudent.exists) {
      throw Exception('Student with registration number $regNo already exists');
    }

    // Create student document
    final studentData = {
      'serialNumber': serialNumber,
      'name': fullName,
      'regNo': regNo,
      'regNoNormalized': normalizedRegNo,
      'level': level,
      'university': university,
      'year': _extractYearFromRegNo(regNo),
      'number': _extractNumberFromRegNo(regNo),
      'createdAt': FieldValue.serverTimestamp(),
      'isActive': true,
    };

    await _firestore
        .collection('students')
        .doc(normalizedRegNo)
        .set(studentData);
  }
}
