import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';


import '../screens/bottomNav.dart';
import '../utils.dart';


class EmailVerificationPage extends StatefulWidget {
  const EmailVerificationPage({super.key});

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  bool isEmailVerified = false;
  bool canResendEmail = false;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    isEmailVerified = FirebaseAuth.instance.currentUser!.emailVerified;

    if (!isEmailVerified) {
      sendVerificationEmail();
      timer = Timer.periodic(const Duration(seconds: 3), (_) {
        checkIfEmailVerified();
      });
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> sendVerificationEmail() async {
    try {
      final user = FirebaseAuth.instance.currentUser!;
      await user.sendEmailVerification();

      setState(() => canResendEmail = false);
      await Future.delayed(const Duration(seconds: 5));
      setState(() => canResendEmail = true);
    } catch (e) {
      Utils.showSnackBar(e.toString());
    }
  }

  Future<void> checkIfEmailVerified() async {
    await FirebaseAuth.instance.currentUser!.reload();
    setState(() {
      isEmailVerified = FirebaseAuth.instance.currentUser!.emailVerified;
    });

    if (isEmailVerified) timer?.cancel();
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
    return isEmailVerified
        ? const MyNavBar()
        : Scaffold(
      appBar: AppBar(
        title: const Text('Verify Email'),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Padding(
              padding: EdgeInsets.symmetric(
                horizontal: constraints.maxWidth * 0.1,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'A verification email has been sent to your email address.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, color: Colors.blueAccent),
                  ),
                  const SizedBox(height: 20),
                  platformButton(
                    text: 'Resend Email',
                    onPressed: (){
                      canResendEmail ? sendVerificationEmail : null;
                    }
                  ),
                  const SizedBox(height: 20),
                  platformButton(
                    text: 'Cancel',
                    onPressed: () {
                      FirebaseAuth.instance.signOut();
                    },
                    isPrimary: false,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
