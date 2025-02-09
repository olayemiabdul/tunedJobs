
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:tuned_jobs/Auth/register.dart';



import '../screens/bottomNav.dart';
import 'forgotpassword.dart';
import '../main.dart';

class AuthScreen extends StatefulWidget {
  final bool isLogin;
  final VoidCallback onToggleAuth;

  const AuthScreen({
    super.key,
    required this.isLogin,
    required this.onToggleAuth,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  bool isLoading = false;
  bool isSplashFinished = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      setState(() => isSplashFinished = true);
    });
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    super.dispose();
  }

  // Platform-specific widgets
  Widget platformTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    // if (Platform.isIOS) {
    //   return CupertinoTextFormFieldRow(
    //     controller: controller,
    //     placeholder: label,
    //     prefix: Icon(icon),
    //     obscureText: isPassword,
    //     keyboardType: keyboardType,
    //     validator: validator,
    //     decoration: BoxDecoration(
    //       border: Border.all(color: CupertinoColors.systemGrey4),
    //       borderRadius: BorderRadius.circular(8),
    //     ),
    //     padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
    //   );
    // }

    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      obscureText: isPassword,
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  Widget platformButton({
    required String text,
    required VoidCallback onPressed,
    bool isPrimary = true,
  }) {
    if (Platform.isIOS) {
      return CupertinoButton(
        onPressed: onPressed,
        color: isPrimary ? CupertinoColors.activeBlue : null,
        child: Text(text),
      );
    }

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary ? Colors.blue : Colors.grey[200],
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isPrimary ? Colors.white : Colors.black87,
        ),
      ),
    );
  }

  Widget buildAuthForm(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;
    final padding = size.width * 0.05;

    return Form(
      key: formKey,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? padding : size.width * 0.2,
          vertical: padding,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!widget.isLogin) ...[
              platformTextField(
                controller: nameController,
                label: 'Full Name',
                icon: FontAwesomeIcons.person,
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Please enter your name' : null,
              ),
              SizedBox(height: size.height * 0.02),
            ],
            platformTextField(
              controller: emailController,
              label: 'Email',
              icon: FontAwesomeIcons.message,
              keyboardType: TextInputType.emailAddress,
              validator: (email) =>
                  email != null && !EmailValidator.validate(email)
                      ? 'Enter a valid email'
                      : null,
            ),
            SizedBox(height: size.height * 0.02),
            platformTextField(
              controller: passwordController,
              label: 'Password',
              icon: Icons.lock,
              isPassword: true,
              validator: (password) => password != null && password.length < 6
                  ? 'Password must be at least 6 characters'
                  : null,
            ),
            SizedBox(height: size.height * 0.03),
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else
              platformButton(
                text: widget.isLogin ? 'Sign In' : 'Sign Up',
                onPressed: submitSignIn,
              ),
            if (kIsWeb || Platform.isAndroid || Platform.isIOS) ...[
              SizedBox(height: size.height * 0.02),
              buildSocialLogin(),
            ],
            SizedBox(height: size.height * 0.02),
            TextButton(
              onPressed: (){
                Navigator.push(context, MaterialPageRoute(builder:(context)=>SignUpScreen (onSignIn: () {  },)));
              },
              child: Text(
                widget.isLogin
                    ? 'Don\'t have an account? Sign Up'
                    : 'Already have an account? Sign In',
              ),
            ),
            SizedBox(height: size.height * 0.02),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ForgotPasswordPage(),
                    ),
                  );
                },
                child: const Text(
                  'Forgot Password?',
                  style: TextStyle(
                    color: Colors.lightBlueAccent,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSocialLogin() {
    return Column(
      children: [
        const Text('Or continue with'),
        const SizedBox(height: 16),
        platformButton(
          text: 'Continue with Google',
          onPressed: googleSignIn,
          isPrimary: false,
        ),
      ],
    );
  }

  Future<void> submitSignIn() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      if (widget.isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailController.text,
          password: passwordController.text,
        );
      } else {
        final userCredential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailController.text,
          password: passwordController.text,
        );
        await userCredential.user?.updateDisplayName(nameController.text);
      }
      // to pop up to the mainpage
      Navigator.pushReplacement(
        navigatorkey.currentContext!,
        MaterialPageRoute(builder: (context) =>const  MyNavBar()),
      );
    } catch (e) {
      // Handle error appropriately
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  Future<void> googleSignIn() async {
    setState(() => isLoading = true);

    try {
      if (kIsWeb) {
        await signInWithGoogleWeb();
      } else {
        await signInWithGoogle();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: '315632173712-6l8a0vm4fsjrv0f37etmo77mo6hfsf07.apps.googleusercontent.com',
        scopes: ['email', 'profile'],
      );

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        throw 'Google Sign In was canceled';
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      // Navigate to MyNav() after successful sign-in
      Navigator.pushReplacement(
        navigatorkey.currentContext!,
        MaterialPageRoute(builder: (context) =>const  MyNavBar()),
      );

    } catch (e) {
      print('Google Sign In Error: $e');
      rethrow;
    }
  }


  Future<void> signInWithGoogleWeb() async {
    final GoogleAuthProvider authProvider = GoogleAuthProvider();
    await FirebaseAuth.instance.signInWithPopup(authProvider);
  }

  @override
  Widget build(BuildContext context) {
    final scaffold =  Scaffold(
            appBar: AppBar(
              //title: const Text('Authentication'),
              centerTitle: true,
            ),
            body: SafeArea(child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.greenAccent,
                    Colors.white,
                  ],
                ),
              ),
              child: Center(child: isSplashFinished
                  ? buildAuthForm(context)
                  : const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SpinKitFadingCube(
                    color: Colors.blue,
                    size: 50.0,
                  ),
                  SizedBox(height: 20),
                  Text('Loading...',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),),
            )),
          );

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: scaffold,
    );
  }
}
