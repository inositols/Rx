import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:monami/auth/bloc/bloc.dart';
import 'package:monami/auth/widget/login_form.dart';
import 'package:monami/auth/widget/upload_form.dart';
import 'dart:convert';
import 'package:monami/core/utils/responsive_utils.dart';
import 'package:monami/dashboard/view/cbt_dashboard_view.dart';

class AdminAuthScreen extends StatefulWidget {
  const AdminAuthScreen({super.key});

  @override
  State<AdminAuthScreen> createState() => _AdminAuthScreenState();
}

class _AdminAuthScreenState extends State<AdminAuthScreen> {
  bool isLogin = true;
  bool isLoading = false;

  // Login form controllers
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // CSV upload form controllers
  final levelController = TextEditingController();
  final universityController = TextEditingController();
  String? csvData;
  String? csvFileName;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    levelController.dispose();
    universityController.dispose();
    super.dispose();
  }

  void _adminSignIn() {
    if (_validateLoginFields()) {
      context.read<AuthBloc>().add(
            AdminSignInRequested(
              email: emailController.text.trim(),
              password: passwordController.text.trim(),
            ),
          );
    }
  }

  void _uploadStudents() {
    if (_validateUploadFields()) {
      context.read<AuthBloc>().add(
            AdminBulkStudentCreationRequested(
              csvData: csvData!,
              level: levelController.text.trim(),
              university: universityController.text.trim(),
            ),
          );
    }
  }

  bool _validateLoginFields() {
    if (emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all login fields')),
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

  bool _validateUploadFields() {
    if (csvData == null ||
        levelController.text.trim().isEmpty ||
        universityController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please fill all fields and select a CSV file')),
      );
      return false;
    }

    return true;
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  Future<void> _pickCSVFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.bytes != null) {
        setState(() {
          csvData = utf8.decode(result.files.single.bytes!);
          csvFileName = result.files.single.name;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking file: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isLogin ? 'Admin Login' : 'Upload Students'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/student-login'),
            child: const Text('Student Login',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated && state.isAdmin) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      isLogin ? 'Admin login successful!' : 'Welcome back!')),
            );
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const CBTDashboardView()),
            );
          } else if (state is BulkStudentCreationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Successfully created ${state.createdCount} student accounts'
                  '${state.errors.isNotEmpty ? '\n${state.errors.length} errors occurred' : ''}',
                ),
                duration: const Duration(seconds: 5),
              ),
            );
            if (state.errors.isNotEmpty) {
              _showErrorsDialog(state.errors);
            }
            // Reset form after successful upload
            setState(() {
              csvData = null;
              csvFileName = null;
              levelController.clear();
              universityController.clear();
            });
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
                            Text(
                              'ADMIN PORTAL\nFACULTY OF PHARMACEUTICAL SCIENCES\nUNIVERSITY OF NIGERIA, NSUKKA',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: ResponsiveUtils.getResponsiveFontSize(
                                  context,
                                  mobile: 16,
                                  tablet: 20,
                                  desktop: 22,
                                ),
                                fontWeight: FontWeight.bold,
                                color: Colors.teal.shade700,
                              ),
                            ),
                            const SizedBox(height: 30),

                            // Toggle buttons
                            SegmentedButton<bool>(
                              segments: const [
                                ButtonSegment(
                                  value: true,
                                  label: Text('Login'),
                                  icon: Icon(Icons.login),
                                ),
                                ButtonSegment(
                                  value: false,
                                  label: Text('Upload Students'),
                                  icon: Icon(Icons.upload_file),
                                ),
                              ],
                              selected: {isLogin},
                              onSelectionChanged: (selection) {
                                setState(() {
                                  isLogin = selection.first;
                                });
                              },
                            ),
                            const SizedBox(height: 30),

                            if (isLogin)
                              ...buildLoginForm(emailController,
                                  passwordController, _adminSignIn)
                            else
                              ...buildUploadForm(
                                csvData,
                                csvFileName,
                                levelController,
                                universityController,
                                _pickCSVFile,
                                _uploadStudents,
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

  void _showErrorsDialog(List<String> errors) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upload Errors'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: errors
                .map((error) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text('• $error',
                          style: const TextStyle(fontSize: 12)),
                    ))
                .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
