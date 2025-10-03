import 'package:firebase_core/firebase_core.dart';
import 'package:monami/core/utils/debug_auth.dart';
import 'package:monami/firebase_options.dart';

void main() async {
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  print('🔧 Authentication Debug Tool');
  print('=' * 40);

  // Check what's in the database
  await DebugAuth.checkStudentsCollection();
  await DebugAuth.checkUsersCollection();

  // Test specific registration numbers
  print('\n🧪 Testing registration number formats:');
  DebugAuth.testRegNoNormalization('2023/123456');
  DebugAuth.testRegNoNormalization('2019/240045');
  DebugAuth.testRegNoNormalization('invalid');

  // Check for a specific student (you can modify this)
  await DebugAuth.checkSpecificStudent('2023/123456');

  // Create a test student if needed
  print('\n❓ Want to create a test student? Uncomment the line below:');
  print('// await DebugAuth.createTestStudent();');

  // Uncomment this line if you need a test student:
  await DebugAuth.createTestStudent();

  print('\n✅ Debug complete!');
}
