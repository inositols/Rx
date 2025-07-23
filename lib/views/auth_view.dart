import 'package:flutter/material.dart';
import 'quiz_view.dart'; // Your quiz screen

class LoginScreen extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  void login(BuildContext context) {
    if (formKey.currentState!.validate()) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => QuizScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          // 🌄 Background Image
          Positioned.fill(
            child: Image.asset(
              'images/bg.png',
              fit: BoxFit.cover,
            ),
          ),

          // 🧾 Login Form
          LayoutBuilder(
            builder: (context, constraints) {
              double formWidth = constraints.maxWidth > 800
                  ? constraints.maxWidth * 0.3
                  : constraints.maxWidth * 0.8;

              return Center(
                child: Container(
                  width: formWidth,
                  padding: EdgeInsets.symmetric(
                      horizontal: 24, vertical: screenHeight * 0.1),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 12)
                    ],
                  ),
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Login',
                            style: TextStyle(
                                fontSize: 32, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 32),
                        TextFormField(
                          controller: emailController,
                          decoration: InputDecoration(
                            labelText: 'Reg Number',
                            border: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: Colors.green.shade900)),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) =>
                              (value == null || !value.contains('/'))
                                  ? 'Enter a valid reg number'
                                  : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            border: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: Colors.green.shade900)),
                          ),
                          validator: (value) =>
                              (value == null || value.length < 6)
                                  ? 'Minimum 6 characters'
                                  : null,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => login(context),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                          ),
                          child: const Text('Log In'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
