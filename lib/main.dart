import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'study_methods_selection_page.dart';
import 'study_timer.dart'; // Study Timer Page
import 'login_page.dart'; // Login Page

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isLoggedIn = false;
  bool _firstLogin = false; // Track if this is the first login

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  // Check login status using SharedPreferences
  Future<void> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? loggedIn = prefs.getBool('isLoggedIn');
    bool? firstLogin =
        prefs.getBool('firstLogin') ?? true; // Defaults to true if not set

    setState(() {
      _isLoggedIn = loggedIn ?? false;
      _firstLogin = firstLogin;
    });

    // [Debug] print login status and firstLogin status
    print("Is logged in: $_isLoggedIn");
    print("First login: $_firstLogin");
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: _isLoggedIn
          ? _firstLogin
              ? StudyMethodsSelectionPage() // show the study methods selection page if first login
              : const StudyTimerPage() // otw show the main page
          : const LoginPage(),
    );
  }
}