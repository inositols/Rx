import 'package:cloud_firestore/cloud_firestore.dart';

class DebugAuth {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Debug: Check what's in the students collection
  static Future<void> checkStudentsCollection() async {
    try {
      print('\n🔍 Checking students collection...');
      final snapshot = await _firestore.collection('students').get();
      
      if (snapshot.docs.isEmpty) {
        print('❌ No students found in students collection');
        print('💡 You need to upload students via CSV first!');
        return;
      }

      print('✅ Found ${snapshot.docs.length} students:');
      print('=' * 50);
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        print('Doc ID: ${doc.id}');
        print('RegNo: ${data['regNo']}');
        print('Name: ${data['name']}');
        print('Level: ${data['level']}');
        print('University: ${data['university']}');
        print('-' * 30);
      }
    } catch (e) {
      print('❌ Error checking students: $e');
    }
  }

  /// Debug: Check what's in the users collection (legacy)
  static Future<void> checkUsersCollection() async {
    try {
      print('\n🔍 Checking users collection (legacy)...');
      final snapshot = await _firestore.collection('users').get();
      
      if (snapshot.docs.isEmpty) {
        print('❌ No users found in users collection');
        return;
      }

      print('✅ Found ${snapshot.docs.length} users:');
      print('=' * 50);
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        print('Doc ID: ${doc.id}');
        print('RegNo: ${data['regNo']}');
        print('Email: ${data['email']}');
        print('Level: ${data['level']}');
        print('-' * 30);
      }
    } catch (e) {
      print('❌ Error checking users: $e');
    }
  }

  /// Debug: Test registration number normalization
  static void testRegNoNormalization(String regNo) {
    print('\n🧪 Testing registration number: $regNo');
    
    // Test validation
    final isValid = _isValidRegistrationNumber(regNo);
    print('Valid format: $isValid');
    
    if (isValid) {
      final normalized = _normalizeRegistrationNumber(regNo);
      print('Normalized: $normalized');
      print('Year: ${_extractYearFromRegNo(regNo)}');
      print('Number: ${_extractNumberFromRegNo(regNo)}');
    }
  }

  /// Check if a specific student exists
  static Future<void> checkSpecificStudent(String regNo) async {
    try {
      print('\n🔍 Checking specific student: $regNo');
      
      final normalized = _normalizeRegistrationNumber(regNo);
      print('Looking for document ID: $normalized');
      
      final doc = await _firestore.collection('students').doc(normalized).get();
      
      if (doc.exists) {
        print('✅ Student found!');
        final data = doc.data()!;
        print('Name: ${data['name']}');
        print('Level: ${data['level']}');
        print('University: ${data['university']}');
      } else {
        print('❌ Student not found in students collection');
        
        // Check users collection too
        final userDoc = await _firestore.collection('users').doc(normalized).get();
        if (userDoc.exists) {
          print('✅ Found in users collection instead');
          final data = userDoc.data()!;
          print('Email: ${data['email']}');
          print('Level: ${data['level']}');
        } else {
          print('❌ Not found in users collection either');
        }
      }
    } catch (e) {
      print('❌ Error checking student: $e');
    }
  }

  /// Helper methods (copied from AuthBloc)
  static bool _isValidRegistrationNumber(String regNo) {
    final regExp = RegExp(r'^\d{4}/\d{6}$');
    if (!regExp.hasMatch(regNo)) return false;
    
    final year = int.tryParse(regNo.substring(0, 4));
    if (year == null || year < 2000 || year > 2030) return false;
    
    return true;
  }

  static String _normalizeRegistrationNumber(String regNo) {
    return regNo.replaceAll('/', '_');
  }

  static String _extractYearFromRegNo(String regNo) {
    return regNo.substring(0, 4);
  }

  static String _extractNumberFromRegNo(String regNo) {
    return regNo.substring(5);
  }

  /// Create a test student manually
  static Future<void> createTestStudent() async {
    try {
      print('\n🧪 Creating test student...');
      
      const testRegNo = '2023/123456';
      const normalized = '2023_123456';
      
      final studentData = {
        'serialNumber': '1',
        'name': 'Test Student',
        'regNo': testRegNo,
        'regNoNormalized': normalized,
        'level': '300',
        'university': 'University of Nigeria, Nsukka',
        'year': '2023',
        'number': '123456',
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
      };

      await _firestore.collection('students').doc(normalized).set(studentData);
      print('✅ Test student created: $testRegNo');
      print('📝 You can now try logging in with: $testRegNo');
    } catch (e) {
      print('❌ Error creating test student: $e');
    }
  }
}

