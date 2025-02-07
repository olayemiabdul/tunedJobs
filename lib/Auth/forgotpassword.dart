import 'dart:io';
import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../utils.dart';


class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  Future<void> resetPassword() async {
    // Validate the form first
    if (!formKey.currentState!.validate()) {
      return; // Don't proceed if the form is invalid
    }

    // Show a loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: SpinKitFadingCube(
          color: Colors.green,
          size: 50,
        ),
      ),
    );

    try {
      // Attempt to send a password reset email
      await FirebaseAuth.instance
          .sendPasswordResetEmail(email: emailController.text.trim());

      // Inform the user of success
      Utils.showSnackBar('Password reset email has been sent.');
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on FirebaseAuthException catch (e) {
      // Display the error
      Navigator.of(context).pop(); // Close the loading indicator
      Utils.showSnackBar(e.message ?? 'An error occurred.');
    }
  }

  Widget platformButton({
    required String text,
    required VoidCallback onPressed,
    bool isPrimary = true,
  }) {
    return Platform.isIOS
        ? CupertinoButton(
      onPressed: onPressed,
      color: isPrimary ? CupertinoColors.activeBlue : CupertinoColors.systemGrey,
      child: Text(text),
    )
        : ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary ? Colors.blue : Colors.grey[400],
        minimumSize: const Size.fromHeight(50),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 18),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forgot Password'),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Padding(
              padding: EdgeInsets.symmetric(
                horizontal: constraints.maxWidth * 0.1,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Enter your email to receive a password reset link.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, color: Colors.black87),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: emailController,
                      decoration: InputDecoration(
                        hintText: 'Enter your email',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        prefixIcon: const Icon(Icons.email),
                      ),
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: (email) {
                        if (email == null || email.isEmpty) {
                          return 'Email cannot be empty.';
                        } else if (!EmailValidator.validate(email)) {
                          return 'Please enter a valid email.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    platformButton(
                      text: 'Reset Password',
                      onPressed: resetPassword,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
