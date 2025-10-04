// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'study_timer.dart';

// class StudyMethodsSelectionPage extends StatefulWidget {
//   @override
//   _StudyMethodsSelectionPageState createState() =>
//       _StudyMethodsSelectionPageState();
// }

// class _StudyMethodsSelectionPageState extends State<StudyMethodsSelectionPage> {
//   final List<String> studyMethods = [
//     'Rereading',
//     'Rewatching lectures',
//     'Rewriting notes',
//     'Highlighting',
//     'Verbatim notes',
//     'Review solutions',
//     'Summarizing',
//     'Imagery',
//     'Real-life examples',
//     'Concept mapping',
//     'Active recall',
//     'Self-testing',
//     'Self-explanation',
//     'Teaching',
//     'Mnemonics',
//     'Feedback use',
//     'Spaced studying',
//     'Interleaving',
//     'Self-care',
//     'Study planning',
//     'Distraction-free',
//     'Group study',
//     'Tutoring/office hours',
//   ];

//   List<String> selectedMethods = [];

//   void _onStudyMethodSelected(bool selected, String method) {
//     setState(() {
//       if (selected) {
//         selectedMethods.add(method);
//       } else {
//         selectedMethods.remove(method);
//       }
//     });
//   }

//   Future<void> _saveStudyMethods() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     String? studentId = prefs.getString('studentId');

//     if (studentId != null) {
//       await FirebaseFirestore.instance
//           .collection('student_codes')
//           .doc(studentId)
//           .update({
//         'study_methods': selectedMethods, // Save selected methods
//       });

//       // Mark that the user has completed the first login
//       await prefs.setBool('firstLogin', false);

//       // Navigate to the Study Timer Page
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (context) => const StudyTimerPage()),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Select Study Methods'),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: <Widget>[
//             const Text(
//               'Which of the following study methods do you use frequently? (Select all that apply)',
//               style: TextStyle(fontSize: 18),
//             ),
//             Expanded(
//               child: ListView.builder(
//                 itemCount: studyMethods.length,
//                 itemBuilder: (context, index) {
//                   return CheckboxListTile(
//                     title: Text(studyMethods[index]),
//                     value: selectedMethods.contains(studyMethods[index]),
//                     onChanged: (bool? selected) {
//                       _onStudyMethodSelected(
//                           selected ?? false, studyMethods[index]);
//                     },
//                   );
//                 },
//               ),
//             ),
//             ElevatedButton(
//               onPressed: _saveStudyMethods,
//               child: const Text('Save and Continue'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'study_timer.dart';

class StudyMethodsSelectionPage extends StatefulWidget {
  @override
  _StudyMethodsSelectionPageState createState() =>
      _StudyMethodsSelectionPageState();
}

class _StudyMethodsSelectionPageState extends State<StudyMethodsSelectionPage> {
  final List<String> allStudyMethods = [
    'Rereading',
    'Rewatching lectures',
    'Rewriting notes',
    'Highlighting',
    'Verbatim notes',
    'Review solutions',
    'Summarizing',
    'Imagery',
    'Real-life examples',
    'Concept mapping',
    'Active recall',
    'Self-testing',
    'Self-explanation',
    'Teaching',
    'Mnemonics',
    'Feedback use',
    'Spaced studying',
    'Interleaving',
    'Self-care',
    'Study planning',
    'Distraction-free',
    'Group study',
    'Tutoring/office hours',
  ];

  List<String> selectedMethods = [];
  List<String> previouslySelectedMethods = [];
  bool showAllMethods = false;

  @override
  void initState() {
    super.initState();
    _loadSelectedMethods();
  }

  Future<void> _loadSelectedMethods() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? studentId = prefs.getString('studentId');

    if (studentId != null) {
      DocumentSnapshot studentDoc = await FirebaseFirestore.instance
          .collection('student_codes')
          .doc(studentId)
          .get();

      if (studentDoc.exists && studentDoc.data() != null) {
        List<dynamic>? savedMethods = studentDoc['study_methods'];
        if (savedMethods != null) {
          setState(() {
            previouslySelectedMethods = List<String>.from(savedMethods);
            selectedMethods = List<String>.from(savedMethods);
          });
        }
      }
    }
  }

  void _onStudyMethodSelected(bool selected, String method) {
    setState(() {
      if (selected) {
        selectedMethods.add(method);
      } else {
        selectedMethods.remove(method);
      }
    });
  }

  Future<void> _saveStudyMethods() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? studentId = prefs.getString('studentId');

    if (studentId != null) {
      await FirebaseFirestore.instance
          .collection('student_codes')
          .doc(studentId)
          .update({
        'study_methods': selectedMethods,
      });

      await prefs.setBool('firstLogin', false);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const StudyTimerPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    List<String> displayedMethods =
        showAllMethods ? allStudyMethods : previouslySelectedMethods;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Study Methods'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            const Text(
              'Which of the following study methods do you use frequently? (Select all that apply)',
              style: TextStyle(fontSize: 18),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: displayedMethods.length,
                itemBuilder: (context, index) {
                  return CheckboxListTile(
                    title: Text(displayedMethods[index]),
                    value: selectedMethods.contains(displayedMethods[index]),
                    onChanged: (bool? selected) {
                      _onStudyMethodSelected(
                          selected ?? false, displayedMethods[index]);
                    },
                  );
                },
              ),
            ),
            if (!showAllMethods)
              TextButton(
                onPressed: () {
                  setState(() {
                    showAllMethods = true;
                  });
                },
                child: const Text('Select More'),
              ),
            ElevatedButton(
              onPressed: _saveStudyMethods,
              child: const Text('Save and Continue'),
            ),
          ],
        ),
      ),
    );
  }
}
