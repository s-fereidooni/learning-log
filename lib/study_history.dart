// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class StudyHistoryPage extends StatefulWidget {
//   const StudyHistoryPage({Key? key}) : super(key: key);

//   @override
//   _StudyHistoryPageState createState() => _StudyHistoryPageState();
// }

// class _StudyHistoryPageState extends State<StudyHistoryPage> {
//   late Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _studySessions;

//   @override
//   void initState() {
//     super.initState();
//     _studySessions = _fetchStudySessions(); // Fetch sessions on page load
//   }

//   // Fetch study sessions from Firestore
//   Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
//       _fetchStudySessions() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     String? studentId = prefs.getString('studentId');
//     if (studentId == null) {
//       return [];
//     }

//     final querySnapshot = await FirebaseFirestore.instance
//         .collection('student_codes')
//         .doc(studentId)
//         .collection('study_sessions')
//         .orderBy('timestamp', descending: true)
//         .get();

//     return querySnapshot.docs;
//   }

//   // Show edit dialog for a specific session
//   Future<void> _showEditDialog(
//       QueryDocumentSnapshot<Map<String, dynamic>> sessionDoc) async {
//     final data = sessionDoc.data();
//     final TextEditingController durationController =
//         TextEditingController(text: data['duration']?.toString() ?? '');
//     final TextEditingController actualStudyTimeController =
//         TextEditingController(
//             text: data['actual_study_time']?.toString() ?? '');
//     final TextEditingController methodsController = TextEditingController(
//         text: (data['study_methods_used'] as List<dynamic>?)?.join(', ') ?? '');

//     await showDialog<void>(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           title: const Text('Edit Study Session'),
//           content: SingleChildScrollView(
//             child: Column(
//               children: [
//                 TextField(
//                   controller: durationController,
//                   keyboardType: TextInputType.number,
//                   decoration:
//                       const InputDecoration(labelText: 'Duration (minutes)'),
//                 ),
//                 TextField(
//                   controller: actualStudyTimeController,
//                   keyboardType: TextInputType.number,
//                   decoration: const InputDecoration(
//                       labelText: 'Actual Study Time (minutes)'),
//                 ),
//                 TextField(
//                   controller: methodsController,
//                   decoration: const InputDecoration(
//                     labelText: 'Study Methods (comma-separated)',
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text('Cancel'),
//             ),
//             TextButton(
//               onPressed: () async {
//                 final updatedData = {
//                   'duration': int.tryParse(durationController.text) ?? 0,
//                   'actual_study_time':
//                       int.tryParse(actualStudyTimeController.text) ?? 0,
//                   'study_methods_used': methodsController.text
//                       .split(',')
//                       .map((method) => method.trim())
//                       .toList(),
//                 };

//                 await sessionDoc.reference.update(updatedData);

//                 setState(() {
//                   _studySessions = _fetchStudySessions(); // Refresh the data
//                 });

//                 Navigator.pop(context);
//               },
//               child: const Text('Save'),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Study History'),
//       ),
//       body: FutureBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
//         future: _studySessions,
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           } else if (snapshot.hasError) {
//             return Center(child: Text('Error: ${snapshot.error}'));
//           } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
//             return const Center(child: Text('No study sessions found.'));
//           } else {
//             final studySessions = snapshot.data!;
//             return ListView.builder(
//               itemCount: studySessions.length,
//               itemBuilder: (context, index) {
//                 final sessionDoc = studySessions[index];
//                 final session = sessionDoc.data();
//                 final timestamp = session['timestamp'] != null
//                     ? (session['timestamp'] as Timestamp).toDate()
//                     : null;
//                 final formattedDate = timestamp != null
//                     ? '${timestamp.year}-${timestamp.month}-${timestamp.day} ${timestamp.hour}:${timestamp.minute}'
//                     : 'No Date';
//                 final duration = session['duration'] ?? 'Unknown';
//                 final actualStudyTime =
//                     session['actual_study_time'] ?? 'Unknown';
//                 final methods =
//                     (session['study_methods_used'] as List<dynamic>?)
//                             ?.join(', ') ??
//                         'Unknown';

//                 return ListTile(
//                   leading: const Icon(Icons.event_note),
//                   title: Text('Date: $formattedDate'),
//                   subtitle: Text(
//                     'Duration: $duration min\n'
//                     'Actual Study Time: $actualStudyTime min\n'
//                     'Methods: $methods',
//                   ),
//                   trailing: IconButton(
//                     icon: const Icon(Icons.edit),
//                     onPressed: () => _showEditDialog(sessionDoc),
//                   ),
//                 );
//               },
//             );
//           }
//         },
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StudyHistoryPage extends StatefulWidget {
  const StudyHistoryPage({Key? key}) : super(key: key);

  @override
  _StudyHistoryPageState createState() => _StudyHistoryPageState();
}

class _StudyHistoryPageState extends State<StudyHistoryPage> {
  late Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _studySessions;

  @override
  void initState() {
    super.initState();
    _studySessions = _fetchStudySessions(); // Fetch sessions on page load
  }

  // Fetch study sessions from Firestore
  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
      _fetchStudySessions() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? studentId = prefs.getString('studentId');
    if (studentId == null) {
      return [];
    }

    final querySnapshot = await FirebaseFirestore.instance
        .collection('student_codes')
        .doc(studentId)
        .collection('study_sessions')
        .orderBy('timestamp', descending: true)
        .get();

    return querySnapshot.docs;
  }

  // Show edit dialog for a specific session
  Future<void> _showEditDialog(
      QueryDocumentSnapshot<Map<String, dynamic>> sessionDoc) async {
    final data = sessionDoc.data();
    final TextEditingController durationController =
        TextEditingController(text: data['duration']?.toString() ?? '');
    final TextEditingController actualStudyTimeController =
        TextEditingController(
            text: data['actual_study_time']?.toString() ?? '');
    final TextEditingController methodsController = TextEditingController(
        text: (data['study_methods_used'] as List<dynamic>?)?.join(', ') ?? '');
    final TextEditingController notesController =
        TextEditingController(text: data['notes'] ?? '');

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Study Session'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: durationController,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: 'Duration (minutes)'),
                ),
                TextField(
                  controller: actualStudyTimeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Actual Study Time (minutes)'),
                ),
                TextField(
                  controller: methodsController,
                  decoration: const InputDecoration(
                    labelText: 'Study Methods (comma-separated)',
                  ),
                ),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final updatedData = {
                  'duration': int.tryParse(durationController.text) ?? 0,
                  'actual_study_time':
                      int.tryParse(actualStudyTimeController.text) ?? 0,
                  'study_methods_used': methodsController.text
                      .split(',')
                      .map((method) => method.trim())
                      .toList(),
                  'notes': notesController.text, // Save updated notes
                };

                await sessionDoc.reference.update(updatedData);

                setState(() {
                  _studySessions = _fetchStudySessions(); // Refresh data
                });

                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Study History'),
      ),
      body: FutureBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
        future: _studySessions,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No study sessions found.'));
          } else {
            final studySessions = snapshot.data!;
            return ListView.builder(
              itemCount: studySessions.length,
              itemBuilder: (context, index) {
                final sessionDoc = studySessions[index];
                final session = sessionDoc.data();
                final timestamp = session['timestamp'] != null
                    ? (session['timestamp'] as Timestamp).toDate()
                    : null;
                final formattedDate = timestamp != null
                    ? '${timestamp.year}-${timestamp.month}-${timestamp.day} ${timestamp.hour}:${timestamp.minute}'
                    : 'No Date';
                final duration = session['duration'] ?? 'Unknown';
                final actualStudyTime =
                    session['actual_study_time'] ?? 'Unknown';
                final methods =
                    (session['study_methods_used'] as List<dynamic>?)
                            ?.join(', ') ??
                        'Unknown';
                final notes =
                    session['notes'] ?? 'No notes added'; // Fetch notes

                return ListTile(
                  leading: const Icon(Icons.event_note),
                  title: Text('Date: $formattedDate'),
                  subtitle: Text(
                    'Duration: $duration min\n'
                    'Actual Study Time: $actualStudyTime min\n'
                    'Methods: $methods\n'
                    'Notes: $notes', // Display notes
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _showEditDialog(sessionDoc),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
