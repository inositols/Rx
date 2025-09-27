import 'package:cloud_firestore/cloud_firestore.dart';

class MigrationHelper {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Migrate existing user documents to new registration format
  Future<String> migrateUserDocuments() async {
    final log = StringBuffer();
    try {
      log.writeln('Starting user document migration...');
      
      final snapshot = await _firestore.collection('users').get();
      final batch = _firestore.batch();
      int migratedCount = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final regNo = data['regNo'] as String?;
        
        if (regNo != null) {
          // Check if it's already in the new format
          if (_isNewFormat(regNo)) {
            // Document already has new format data
            if (!data.containsKey('regNoNormalized')) {
              // Add normalized field
              batch.update(doc.reference, {
                'regNoNormalized': _normalizeRegistrationNumber(regNo),
                'year': _extractYearFromRegNo(regNo),
                'number': _extractNumberFromRegNo(regNo),
              });
              migratedCount++;
            }
          } else {
            // Old format - try to convert if possible
            final convertedRegNo = _tryConvertOldFormat(regNo);
            if (convertedRegNo != null) {
              batch.update(doc.reference, {
                'regNo': convertedRegNo,
                'regNoNormalized': _normalizeRegistrationNumber(convertedRegNo),
                'year': _extractYearFromRegNo(convertedRegNo),
                'number': _extractNumberFromRegNo(convertedRegNo),
              });
              migratedCount++;
            } else {
              log.writeln('Could not convert registration number: $regNo');
            }
          }
        }
      }

      if (migratedCount > 0) {
        await batch.commit();
        log.writeln('Successfully migrated $migratedCount user documents');
      } else {
        log.writeln('No user documents needed migration');
      }
    } catch (e) {
      log.writeln('Error during user migration: $e');
    }
    return log.toString();
  }

  // Migrate existing test session documents
  Future<String> migrateTestSessions() async {
    final log = StringBuffer();
    try {
      log.writeln('Starting test session migration...');
      
      final snapshot = await _firestore.collection('test_sessions').get();
      final batch = _firestore.batch();
      int migratedCount = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final userId = data['userId'] as String?;
        
        if (userId != null && !_isNormalizedFormat(userId)) {
          // Convert userId to normalized format
          if (_isNewFormat(userId)) {
            batch.update(doc.reference, {
              'userId': _normalizeRegistrationNumber(userId),
            });
            migratedCount++;
          } else {
            // Try to convert old format
            final convertedUserId = _tryConvertOldFormat(userId);
            if (convertedUserId != null) {
              batch.update(doc.reference, {
                'userId': _normalizeRegistrationNumber(convertedUserId),
              });
              migratedCount++;
            }
          }
        }
      }

      if (migratedCount > 0) {
        await batch.commit();
        log.writeln('Successfully migrated $migratedCount test session documents');
      } else {
        log.writeln('No test session documents needed migration');
      }
    } catch (e) {
      log.writeln('Error during test session migration: $e');
    }
    return log.toString();
  }

  // Run all migrations
  Future<String> runAllMigrations() async {
    final log = StringBuffer();
    log.writeln('=== Starting Data Migration ===');
    
    final userResult = await migrateUserDocuments();
    log.write(userResult);
    
    final sessionResult = await migrateTestSessions();
    log.write(sessionResult);
    
    log.writeln('=== Migration Complete ===');
    return log.toString();
  }

  // Helper methods
  bool _isNewFormat(String regNo) {
    final regExp = RegExp(r'^\d{4}/\d{6}$');
    return regExp.hasMatch(regNo);
  }

  bool _isNormalizedFormat(String regNo) {
    final regExp = RegExp(r'^\d{4}_\d{6}$');
    return regExp.hasMatch(regNo);
  }

  String? _tryConvertOldFormat(String oldRegNo) {
    // Remove any spaces and special characters except numbers
    String cleaned = oldRegNo.replaceAll(RegExp(r'[^\d]'), '');
    
    // If we have exactly 10 digits, assume first 4 are year and last 6 are number
    if (cleaned.length == 10) {
      final year = cleaned.substring(0, 4);
      final number = cleaned.substring(4);
      
      // Validate year is reasonable
      final yearInt = int.tryParse(year);
      if (yearInt != null && yearInt >= 2000 && yearInt <= 2030) {
        return '$year/$number';
      }
    }
    
    // If we have 4 + 6 pattern with some separator
    final pattern = RegExp(r'^(\d{4})\D+(\d{6})$');
    final match = pattern.firstMatch(oldRegNo);
    if (match != null) {
      final year = match.group(1)!;
      final number = match.group(2)!;
      
      final yearInt = int.tryParse(year);
      if (yearInt != null && yearInt >= 2000 && yearInt <= 2030) {
        return '$year/$number';
      }
    }
    
    return null; // Could not convert
  }

  String _normalizeRegistrationNumber(String regNo) {
    return regNo.replaceAll('/', '_');
  }

  String _extractYearFromRegNo(String regNo) {
    return regNo.substring(0, 4);
  }

  String _extractNumberFromRegNo(String regNo) {
    return regNo.substring(5); // Skip "YYYY/"
  }

  // Utility method to validate all data after migration
  Future<String> validateMigration() async {
    final log = StringBuffer();
    try {
      log.writeln('Validating migration...');
      
      // Check users collection
      final userSnapshot = await _firestore.collection('users').get();
      int validUsers = 0;
      int invalidUsers = 0;
      
      for (final doc in userSnapshot.docs) {
        final data = doc.data();
        final regNo = data['regNo'] as String?;
        final regNoNormalized = data['regNoNormalized'] as String?;
        
        if (regNo != null && _isNewFormat(regNo) && 
            regNoNormalized != null && _isNormalizedFormat(regNoNormalized)) {
          validUsers++;
        } else {
          invalidUsers++;
          log.writeln('Invalid user document: ${doc.id} - regNo: $regNo, normalized: $regNoNormalized');
        }
      }
      
      log.writeln('User validation: $validUsers valid, $invalidUsers invalid');
      
      // Check test sessions collection
      final sessionSnapshot = await _firestore.collection('test_sessions').get();
      int validSessions = 0;
      int invalidSessions = 0;
      
      for (final doc in sessionSnapshot.docs) {
        final data = doc.data();
        final userId = data['userId'] as String?;
        
        if (userId != null && _isNormalizedFormat(userId)) {
          validSessions++;
        } else {
          invalidSessions++;
          log.writeln('Invalid session document: ${doc.id} - userId: $userId');
        }
      }
      
      log.writeln('Session validation: $validSessions valid, $invalidSessions invalid');
      
    } catch (e) {
      log.writeln('Error during validation: $e');
    }
    return log.toString();
  }
}
