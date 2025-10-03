import 'package:firebase_core/firebase_core.dart';
import 'package:monami/core/utils/admin_setup.dart';
import 'package:monami/firebase_options.dart';

void main() async {
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  print('🚀 Admin Creation Tool');
  print('=' * 40);

  // Example: Create multiple admins
  final adminsToCreate = [
    {
      'email': 'classrep@pharmacy.unn.edu.ng',
      'password': 'ClassRep2024!',
      'name': 'Class Representative',
      'role': 'class_rep',
    },
    {
      'email': 'admin@pharmacy.unn.edu.ng',
      'password': 'Admin2024!',
      'name': 'System Administrator',
      'role': 'admin',
    },
    {
      'email': 'lecturer@pharmacy.unn.edu.ng',
      'password': 'Lecturer2024!',
      'name': 'Course Lecturer',
      'role': 'lecturer',
    }
  ];

  // Create admins
  for (final admin in adminsToCreate) {
    try {
      await AdminSetup.createAdmin(
        email: admin['email']!,
        password: admin['password']!,
        name: admin['name']!,
        role: admin['role']!,
      );
    } catch (e) {
      print('Failed to create ${admin['email']}: $e');
    }
  }

  // List all admins
  await AdminSetup.listAdmins();

  print('\n✅ Admin creation process completed!');
  print('\n📝 Admin Login Credentials:');
  print('=' * 40);
  for (final admin in adminsToCreate) {
    print('Email: ${admin['email']}');
    print('Password: ${admin['password']}');
    print('Role: ${admin['role']}');
    print('-' * 30);
  }
}
