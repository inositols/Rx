import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminSetup {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Creates an admin account in Firestore and Firebase Auth
  static Future<void> createAdmin({
    required String email,
    required String password,
    required String name,
    String role = 'class_rep',
  }) async {
    try {
      // 1. Create Firebase Auth user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Add to admins collection
      await _firestore.collection('admins').doc(email).set({
        'email': email,
        'name': name,
        'role': role,
        'uid': userCredential.user!.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
      });

      print('✅ Admin created successfully: $email');
    } catch (e) {
      print('❌ Error creating admin: $e');
      rethrow;
    }
  }

  /// Adds an existing user as admin (if they already have Firebase Auth account)
  static Future<void> addExistingUserAsAdmin({
    required String email,
    required String name,
    String role = 'class_rep',
  }) async {
    try {
      await _firestore.collection('admins').doc(email).set({
        'email': email,
        'name': name,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
      });

      print('✅ Admin role added successfully: $email');
    } catch (e) {
      print('❌ Error adding admin role: $e');
      rethrow;
    }
  }

  /// Lists all admins
  static Future<void> listAdmins() async {
    try {
      final snapshot = await _firestore.collection('admins').get();
      
      print('\n📋 Current Admins:');
      print('=' * 50);
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        print('Email: ${data['email']}');
        print('Name: ${data['name']}');
        print('Role: ${data['role']}');
        print('Active: ${data['isActive']}');
        print('-' * 30);
      }
    } catch (e) {
      print('❌ Error listing admins: $e');
    }
  }

  /// Deactivates an admin
  static Future<void> deactivateAdmin(String email) async {
    try {
      await _firestore.collection('admins').doc(email).update({
        'isActive': false,
        'deactivatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Admin deactivated: $email');
    } catch (e) {
      print('❌ Error deactivating admin: $e');
      rethrow;
    }
  }
}

