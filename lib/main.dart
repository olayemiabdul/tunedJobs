import 'dart:io';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tuned_jobs/provider/favouriteProvider.dart';
import 'package:tuned_jobs/screen/firstPage.dart';
import 'package:tuned_jobs/utils.dart';

import 'Auth/emailverification.dart';
import 'firebase_options.dart';



class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize App Check
    if (kDebugMode) {
      await FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.debug,
        appleProvider: AppleProvider.debug,
      );
    } else {
      await FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.playIntegrity,
        appleProvider: AppleProvider.deviceCheck,
      );
    }

    print('Firebase and App Check initialized successfully');
  } catch (e) {
    print('Error initializing Firebase: $e');
    rethrow;
  }

  // Set global HTTP overrides
  HttpOverrides.global = MyHttpOverrides();

  // Configure status bar
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Color(0xFF7FFFD4),
    statusBarIconBrightness: Brightness.light,
  ));

  runApp(const JobSearchApp());
}

final navigatorkey = GlobalKey<NavigatorState>();

class JobSearchApp extends StatelessWidget {
  const JobSearchApp({super.key});


  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => FavouritesJob(),
      builder: (context, child) {
        return MaterialApp(

          scaffoldMessengerKey: messengerkey,
          navigatorKey: navigatorkey,
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            body: StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Colors.blueAccent,
                    ),
                  );
                } else if (snapshot.hasError) {
                  return const Center(child: Text('Something went wrong'));
                } else if (snapshot.hasData) {
                  return const EmailVerificationPage();
                } else {
                  return const TheWelcomePage();
                }
              },
            ),
          ),
        );
      },
    );
  }
}
