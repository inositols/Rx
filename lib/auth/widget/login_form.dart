import 'package:flutter/material.dart';

List<Widget> buildLoginForm(
  TextEditingController emailController,
  TextEditingController passwordController,
  Function() adminSignIn,
) {
  return [
    TextField(
      controller: emailController,
      decoration: const InputDecoration(
        labelText: 'Admin Email Address',
        hintText: 'admin@university.edu',
        prefixIcon: Icon(Icons.admin_panel_settings),
        border: OutlineInputBorder(),
      ),
      keyboardType: TextInputType.emailAddress,
    ),
    const SizedBox(height: 16),
    TextField(
      controller: passwordController,
      decoration: const InputDecoration(
        labelText: 'Password',
        prefixIcon: Icon(Icons.lock),
        border: OutlineInputBorder(),
      ),
      obscureText: true,
    ),
    const SizedBox(height: 30),
    ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      onPressed: adminSignIn,
      child: const Text('Admin Login', style: TextStyle(fontSize: 16)),
    ),
  ];
}
