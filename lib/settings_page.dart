import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final List<String> studyMethods = [
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

  @override
  void initState() {
    super.initState();
    _loadSelectedMethods(); // Load the current selections when the page opens
  }

  Future<void> _loadSelectedMethods() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? studentId = prefs.getString('studentId');

      if (studentId != null) {
        DocumentSnapshot studentDoc = await FirebaseFirestore.instance
            .collection('student_codes')
            .doc(studentId)
            .get();

        if (studentDoc.exists && studentDoc['study_methods'] != null) {
          List<dynamic> methods = studentDoc['study_methods'];
          setState(() {
            selectedMethods = methods.cast<String>();
          });
        }
      } else {
        print("Error: No student ID found in SharedPreferences.");
      }
    } catch (e) {
      print("Error loading study methods: $e");
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
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? studentId = prefs.getString('studentId');

      if (studentId != null) {
        await FirebaseFirestore.instance
            .collection('student_codes')
            .doc(studentId)
            .update({
          'study_methods': selectedMethods, // Update the selected methods
        });

        // Show a confirmation message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Study methods updated successfully!')),
        );

        // Optionally, navigate back after saving
        Navigator.pop(context);
      } else {
        print("Error: No student ID found in SharedPreferences.");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: No student logged in.')),
        );
      }
    } catch (e) {
      print("Error saving study methods: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving study methods: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings - Study Methods'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            const Text(
              'Modify your frequent study methods (Select all that apply)',
              style: TextStyle(fontSize: 18),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: studyMethods.length,
                itemBuilder: (context, index) {
                  return CheckboxListTile(
                    title: Text(studyMethods[index]),
                    value: selectedMethods.contains(studyMethods[index]),
                    onChanged: (bool? selected) {
                      _onStudyMethodSelected(
                          selected ?? false, studyMethods[index]);
                    },
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: _saveStudyMethods,
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}
