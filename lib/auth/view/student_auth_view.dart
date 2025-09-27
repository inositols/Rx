import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../auth/bloc/auth_bloc.dart';
import '../auth/bloc/auth_event.dart';
import '../auth/bloc/auth_state.dart';
import '../utils/responsive_utils.dart';
import 'cbt_dashboard_view.dart';

class StudentAuthScreen extends StatefulWidget {
  const StudentAuthScreen({super.key});

  @override
  State<StudentAuthScreen> createState() => _StudentAuthScreenState();
}

class _StudentAuthScreenState extends State<StudentAuthScreen> {
  final regNoController = TextEditingController();

  @override
  void dispose() {
    regNoController.dispose();
    super.dispose();
  }

  void _studentSignIn() {
    if (_validateFields()) {
      context.read<AuthBloc>().add(
            StudentSignInRequested(
              regNo: regNoController.text.trim(),
            ),
          );
    }
  }

  bool _validateFields() {
    if (regNoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your registration number')),
      );
      return false;
    }

    // Validate registration number format
    if (!_isValidRegistrationNumber(regNoController.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Invalid registration number format. Use YYYY/NNNNNN (e.g., 2019/240045)'),
          duration: Duration(seconds: 4),
        ),
      );
      return false;
    }

    return true;
  }

  bool _isValidRegistrationNumber(String regNo) {
    // Check format: YYYY/NNNNNN (4 digits, slash, 6 digits)
    final regExp = RegExp(r'^\d{4}/\d{6}$');
    if (!regExp.hasMatch(regNo)) return false;

    // Additional validation: year should be reasonable (e.g., 2000-2030)
    final year = int.tryParse(regNo.substring(0, 4));
    if (year == null || year < 2000 || year > 2030) return false;

    return true;
  }

  String _formatRegistrationNumber(String input) {
    // Remove any non-numeric characters except /
    String cleaned = input.replaceAll(RegExp(r'[^\d/]'), '');

    // If no slash and has at least 4 digits, insert slash after 4th digit
    if (!cleaned.contains('/') && cleaned.length >= 4) {
      cleaned = '${cleaned.substring(0, 4)}/${cleaned.substring(4)}';
    }

    // Limit to 11 characters (YYYY/NNNNNN)
    if (cleaned.length > 11) {
      cleaned = cleaned.substring(0, 11);
    }

    return cleaned;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Login'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/admin-login'),
            child: const Text('Admin Portal',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated && !state.isAdmin) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    Text('Welcome, ${state.userData['name'] ?? 'Student'}!'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const CBTDashboardView()),
            );
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          return Stack(
            fit: StackFit.expand,
            children: [
              // Background image
              Image.asset(
                'images/bg.png',
                fit: BoxFit.cover,
              ),
              if (state is AuthLoading)
                const Center(child: CircularProgressIndicator())
              else
                Center(
                  child: SingleChildScrollView(
                    child: Container(
                      width: ResponsiveUtils.getResponsiveFormWidth(context),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(
                          ResponsiveUtils.getResponsiveValue(
                            context,
                            mobile: 12,
                            tablet: 16,
                            desktop: 20,
                          ),
                        ),
                      ),
                      margin: ResponsiveUtils.getResponsiveMargin(context),
                      child: Padding(
                        padding: ResponsiveUtils.getResponsivePadding(context),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.school,
                              size: ResponsiveUtils.getResponsiveValue(
                                context,
                                mobile: 60,
                                tablet: 80,
                                desktop: 100,
                              ),
                              color: Colors.teal,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'STUDENT PORTAL',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: ResponsiveUtils.getResponsiveFontSize(
                                  context,
                                  mobile: 24,
                                  tablet: 28,
                                  desktop: 32,
                                ),
                                fontWeight: FontWeight.bold,
                                color: Colors.teal.shade700,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'FACULTY OF PHARMACEUTICAL SCIENCES\nUNIVERSITY OF NIGERIA, NSUKKA',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: ResponsiveUtils.getResponsiveFontSize(
                                  context,
                                  mobile: 14,
                                  tablet: 16,
                                  desktop: 18,
                                ),
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 40),
                            Card(
                              elevation: 2,
                              color: Colors.blue.shade50,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Icon(Icons.info,
                                        color: Colors.blue.shade700),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Enter your registration number to access your tests. Contact your class representative if you encounter any issues.',
                                        style: TextStyle(
                                          color: Colors.blue.shade700,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 30),
                            TextField(
                              controller: regNoController,
                              decoration: InputDecoration(
                                labelText: 'Registration Number',
                                hintText: '2019/240045',
                                helperText: 'Format: YYYY/NNNNNN',
                                prefixIcon: const Icon(Icons.badge),
                                border: const OutlineInputBorder(),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Colors.teal.shade700, width: 2),
                                ),
                                labelStyle:
                                    TextStyle(color: Colors.teal.shade700),
                              ),
                              keyboardType: TextInputType.text,
                              maxLength: 11,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                              onChanged: (value) {
                                final formatted =
                                    _formatRegistrationNumber(value);
                                if (formatted != value) {
                                  regNoController.value = TextEditingValue(
                                    text: formatted,
                                    selection: TextSelection.collapsed(
                                        offset: formatted.length),
                                  );
                                }
                              },
                            ),
                            const SizedBox(height: 30),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 55),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 3,
                              ),
                              onPressed: _studentSignIn,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.login, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Access Tests',
                                    style: TextStyle(
                                      fontSize:
                                          ResponsiveUtils.getResponsiveFontSize(
                                        context,
                                        mobile: 16,
                                        tablet: 18,
                                        desktop: 20,
                                      ),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 30),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    'Need Help?',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'If your registration number is not recognized, please contact your class representative to be added to the system.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

