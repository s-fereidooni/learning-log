import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'study_methods_selection_page.dart';
import 'study_timer.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;
  String _message = '';

  Future<void> _checkClassCode() async {
    String enteredCode = _codeController.text.trim();

    if (enteredCode.isEmpty) {
      setState(() {
        _message = "Please enter a class code.";
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      var querySnapshot = await FirebaseFirestore.instance
          .collection('student_codes')
          .where('classcode', isEqualTo: enteredCode)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // get the student document
        var studentDoc = querySnapshot.docs.first;
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('studentId', studentDoc.id);

        // check if the student has already selected study methods
        bool firstLogin =
            studentDoc.data().containsKey('study_methods') == false;
        await prefs.setBool('firstLogin', firstLogin);

        // save login status
        await prefs.setBool('isLoggedIn', true);

        // [debugging step] print firstLogin status
        print("First login status: $firstLogin");

        // navigate to either StudyMethodsSelectionPage or StudyTimerPage
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => firstLogin
                ? StudyMethodsSelectionPage() // navigate to study methods selection page if first login
                : const StudyTimerPage(), // otw navigate to the timer page
          ),
        );
      } else {
        setState(() {
          _message = 'Class code does not exist.';
        });
      }
    } catch (e) {
      setState(() {
        _message = 'Error checking class code: $e';
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Join Your Class'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // creates a fixed width rectangle entry field
            SizedBox(
              width: 200,
              child: TextField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: 'Enter Class Code',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(
                        8.0)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _checkClassCode,
                    child: const Text(
                      'Join Class',
                    ),
                  ),
            const SizedBox(height: 20),
            Text(_message),
          ],
        ),
      ),
    );
  }
}
