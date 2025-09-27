import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../../utils/responsive_utils.dart';
import '../../views/cbt_dashboard_view.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;

  final regNoController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final levelController = TextEditingController();
  final genderController = TextEditingController();

  @override
  void dispose() {
    regNoController.dispose();
    emailController.dispose();
    passwordController.dispose();
    levelController.dispose();
    genderController.dispose();
    super.dispose();
  }

  void _signUp() {
    if (_validateFields()) {
      context.read<AuthBloc>().add(
            AuthSignUpRequested(
              regNo: regNoController.text.trim(),
              email: emailController.text.trim(),
              password: passwordController.text.trim(),
              level: levelController.text.trim(),
              gender: genderController.text.trim(),
            ),
          );
    }
  }

  void _signIn() {
    if (_validateSignInFields()) {
      context.read<AuthBloc>().add(
            AuthSignInRequested(
              regNo: regNoController.text.trim(),
              password: passwordController.text.trim(),
            ),
          );
    }
  }

  bool _validateFields() {
    if (regNoController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty ||
        levelController.text.trim().isEmpty ||
        genderController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
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

    // Validate email format
    if (!_isValidEmail(emailController.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address')),
      );
      return false;
    }

    return true;
  }

  bool _validateSignInFields() {
    if (regNoController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
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

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
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
      appBar: AppBar(title: Text(isLogin ? 'Login' : 'Sign Up')),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      isLogin ? 'Login successful!' : 'Sign-up successful!')),
            );
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const CBTDashboardView()),
            );
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
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
                        color: Colors.white.withOpacity(0.9),
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
                            Text(
                              'FACULTY OF PHARMACEUTICAL SCIENCES\n UNIVERSITY OF NIGERIA, NSUKKA',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: ResponsiveUtils.getResponsiveFontSize(
                                  context,
                                  mobile: 18,
                                  tablet: 22,
                                  desktop: 24,
                                ),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextField(
                              controller: regNoController,
                              decoration: const InputDecoration(
                                labelText: 'Registration Number',
                                hintText: '2019/240045',
                                helperText: 'Format: YYYY/NNNNNN',
                                prefixIcon: Icon(Icons.badge),
                              ),
                              keyboardType: TextInputType.text,
                              maxLength: 11,
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
                            if (!isLogin)
                              TextField(
                                controller: emailController,
                                decoration: const InputDecoration(
                                  labelText: 'Email Address',
                                  hintText: 'student@example.com',
                                  prefixIcon: Icon(Icons.email),
                                ),
                                keyboardType: TextInputType.emailAddress,
                              ),
                            TextField(
                              controller: passwordController,
                              decoration: const InputDecoration(
                                labelText: 'Password',
                                prefixIcon: Icon(Icons.lock),
                              ),
                              obscureText: true,
                            ),
                            if (!isLogin)
                              DropdownButtonFormField<String>(
                                value: levelController.text.isEmpty
                                    ? null
                                    : levelController.text,
                                decoration: const InputDecoration(
                                  labelText: 'Level',
                                  prefixIcon: Icon(Icons.school),
                                ),
                                items: [
                                  '100',
                                  '200',
                                  '300',
                                  '400',
                                  '500',
                                  '600'
                                ].map((level) {
                                  return DropdownMenuItem(
                                    value: level,
                                    child: Text(level),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    levelController.text = value;
                                  }
                                },
                              ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                minimumSize: const Size(double.infinity, 50),
                              ),
                              onPressed: isLogin ? _signIn : _signUp,
                              child: Text(
                                isLogin ? 'Login' : 'Sign Up',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 16),
                              ),
                            ),
                            TextButton(
                              onPressed: () =>
                                  setState(() => isLogin = !isLogin),
                              child: Text(
                                isLogin
                                    ? 'Don’t have an account? Sign Up'
                                    : 'Already have an account? Login',
                                style: TextStyle(
                                    color: Colors.teal.shade700, fontSize: 18),
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
