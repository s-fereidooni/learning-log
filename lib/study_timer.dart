import 'package:flutter/material.dart';
import 'dart:async'; // For timer functionality
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:learning_log/study_history.dart';
import 'package:shared_preferences/shared_preferences.dart'; // For Firebase
import 'login_page.dart'; // Assuming you have a login page to navigate to
import 'dart:math'; // Import for generating random numbers
import 'settings_page.dart'; // Import the SettingsPage

class StudyTimerPage extends StatefulWidget {
  const StudyTimerPage({Key? key}) : super(key: key);

  @override
  _StudyTimerPageState createState() => _StudyTimerPageState();
}

class _StudyTimerPageState extends State<StudyTimerPage> {
  int _selectedDuration = 0; // Stores the selected duration in minutes
  bool _isTimerRunning = false;
  bool _isPaused = false; // Track whether the timer is paused
  int _remainingTime = 0; // Remaining time in seconds
  Timer? _timer;
  DateTime? _startTime; // Track when the session starts
  int? _actualStudyMinutes; // Store actual study time to log later
  String? _fetchedQuestion; // Store the fetched question
  List<String> _savedStudyMethods = []; // Store saved study methods
  List<String> _selectedStudyMethods =
      []; // Store methods selected after session

  // Fetch the saved study methods for the logged-in student
  Future<void> _getStudyMethods() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? studentId = prefs.getString('studentId');

    if (studentId != null) {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('student_codes')
          .doc(studentId)
          .get();

      if (docSnapshot.exists) {
        setState(() {
          _savedStudyMethods =
              List<String>.from(docSnapshot['study_methods'] ?? []);
        });
      }
    }
  }

  // Function to determine the current week based on the date ranges
  int getCurrentWeek() {
    final DateTime now = DateTime.now();
    // Define the start and end dates for each week
    final List<DateTimeRange> weekRanges = [
      DateTimeRange(
          start: DateTime(2025, 1, 6), end: DateTime(2025, 1, 12)), // Week 1
      DateTimeRange(
          start: DateTime(2025, 1, 13), end: DateTime(2025, 1, 19)), // Week 2
      DateTimeRange(
          start: DateTime(2025, 1, 20), end: DateTime(2025, 1, 26)), // Week 3
      DateTimeRange(
          start: DateTime(2025, 1, 27), end: DateTime(2025, 2, 2)), // Week 4
      DateTimeRange(
          start: DateTime(2025, 2, 3), end: DateTime(2025, 2, 9)), // Week 5
      DateTimeRange(
          start: DateTime(2025, 2, 10), end: DateTime(2025, 2, 16)), // Week 6
      DateTimeRange(
          start: DateTime(2025, 2, 17), end: DateTime(2025, 2, 23)), // Week 7
      DateTimeRange(
          start: DateTime(2025, 2, 24), end: DateTime(2025, 3, 2)), // Week 8
      DateTimeRange(
          start: DateTime(2025, 3, 3), end: DateTime(2025, 3, 9)), // Week 9
      DateTimeRange(
          start: DateTime(2025, 3, 10), end: DateTime(2025, 3, 16)), // Week 10
    ];

    for (int i = 0; i < weekRanges.length; i++) {
      if (now.isAfter(weekRanges[i].start) && now.isBefore(weekRanges[i].end)) {
        return i + 1; // Return the corresponding week number
      }
    }
    return 0; // Return 0 if the current date is not within the range of the 10 weeks
  }

  void _showHistoryPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const StudyHistoryPage(), // Navigate to StudyHistoryPage
      ),
    );
  }

  // Function to log out and clear studentId from SharedPreferences
  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('studentId'); // Clear the studentId

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (context) => const LoginPage()), // Navigate to Login Page
    );
  }

  Future<void> _showManualLoggingDialog() async {
    final TextEditingController durationController = TextEditingController();
    final TextEditingController notesController = TextEditingController();
    List<String> selectedMethods = List.from(_savedStudyMethods);

    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Log Past Study Session'),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: durationController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Duration (minutes)',
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Select Study Methods',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Column(
                      children: _savedStudyMethods.map((method) {
                        return CheckboxListTile(
                          title: Text(method),
                          value: selectedMethods.contains(method),
                          onChanged: (bool? selected) {
                            setState(() {
                              if (selected == true) {
                                selectedMethods.add(method);
                              } else {
                                selectedMethods.remove(method);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: notesController,
                      keyboardType: TextInputType.text,
                      decoration: const InputDecoration(
                        labelText: 'Notes (optional)',
                      ),
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
                  onPressed: () {
                    final int duration =
                        int.tryParse(durationController.text) ?? 0;
                    _logManualSession(
                        duration, selectedMethods, notesController.text);
                    Navigator.pop(context);
                  },
                  child: const Text('Log Session'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // This function starts or resumes the timer
  void _startTimer(int duration) {
    setState(() {
      _remainingTime = duration * 60; // Convert minutes to seconds
      _isTimerRunning = true;
      _isPaused = false;
      _startTime = DateTime.now(); // Record the start time
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingTime > 0) {
          _remainingTime--;
        } else {
          _isTimerRunning = false;
          _timer?.cancel();
          _endSession(); // Automatically end the session when time runs out
        }
      });
    });
  }

  // This function pauses the timer
  void _pauseTimer() {
    if (_timer != null && _isTimerRunning && !_isPaused) {
      _timer?.cancel();
      setState(() {
        _isPaused = true;
      });
    }
  }

  // This function resumes the paused timer
  void _resumeTimer() {
    if (_isPaused) {
      setState(() {
        _isPaused = false;
      });
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          if (_remainingTime > 0) {
            _remainingTime--;
          } else {
            _isTimerRunning = false;
            _timer?.cancel();
            _endSession();
          }
        });
      });
    }
  }

  // This function ends the session manually or automatically
  void _endSession() {
    setState(() {
      _isTimerRunning = false;
      _isPaused = false;
      _remainingTime = 0;
    });
    _timer?.cancel();

    // Calculate the actual time spent studying
    if (_startTime != null) {
      Duration actualStudyDuration = DateTime.now().difference(_startTime!);
      _actualStudyMinutes = actualStudyDuration.inMinutes;
    }

    _showRatingDialog(); // Show rating dialog after session ends
  }

  Future<void> _logManualSession(
      int duration, List<String> studyMethods, String notes) async {
    if (duration <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Duration must be greater than 0 minutes.')),
      );
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? studentId = prefs.getString('studentId');

    if (studentId != null) {
      await FirebaseFirestore.instance
          .collection('student_codes')
          .doc(studentId)
          .collection('study_sessions')
          .add({
        'duration': duration,
        'study_methods_used': studyMethods,
        'notes': notes,
        'timestamp': Timestamp.now(),
        'manual_entry': true, // Indicate this session was logged manually
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Past study session logged successfully!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: No student logged in.')),
      );
    }
  }

  // Show a rating dialog and then fetch the question
  // Future<void> _showRatingDialog() async {
  //   int? rating = await showDialog<int>(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         title: const Text('Rate Your Study Session'),
  //         content: const Text('How would you rate your study session?'),
  //         actions: <Widget>[
  //           TextButton(
  //               onPressed: () => Navigator.pop(context, 1),
  //               child: const Text('1')),
  //           TextButton(
  //               onPressed: () => Navigator.pop(context, 2),
  //               child: const Text('2')),
  //           TextButton(
  //               onPressed: () => Navigator.pop(context, 3),
  //               child: const Text('3')),
  //           TextButton(
  //               onPressed: () => Navigator.pop(context, 4),
  //               child: const Text('4')),
  //           TextButton(
  //               onPressed: () => Navigator.pop(context, 5),
  //               child: const Text('5')),
  //         ],
  //       );
  //     },
  //   );

  //   if (rating != null && _actualStudyMinutes != null) {
  //     _selectedStudyMethods =
  //         await _showStudyMethodsDialog(); // Show method selection
  //     _logStudySession(rating, _actualStudyMinutes!, _selectedStudyMethods);
  //     _fetchQuestionForCurrentWeek(); // Fetch the question after the rating
  //   }
  // }

  Future<void> _showRatingDialog() async {
    final TextEditingController notesController = TextEditingController();
    int? rating = await showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Rate Your Study Session'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('How would you rate your study session?'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 0.5,
                children: List.generate(5, (index) {
                  return TextButton(
                    onPressed: () => Navigator.pop(context, index + 1),
                    child: Text('${index + 1}'),
                  );
                }),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: notesController,
                maxLength: 200,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Add a note (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );

    if (rating != null && _actualStudyMinutes != null) {
      _selectedStudyMethods =
          await _showStudyMethodsDialog(); // Select study methods
      _logStudySession(rating, _actualStudyMinutes!, _selectedStudyMethods,
          notesController.text);
      _fetchQuestionForCurrentWeek(); // Fetch the question after the rating
    }
  }

  // Show dialog to select study methods used during the session
  // Future<List<String>> _showStudyMethodsDialog() async {
  //   List<String> selectedMethods = List.from(_savedStudyMethods);

  //   await showDialog<void>(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return StatefulBuilder(
  //         builder: (context, setState) {
  //           return AlertDialog(
  //             title: const Text('Select Study Methods Used'),
  //             content: SingleChildScrollView(
  //               child: Column(
  //                 children: _savedStudyMethods.map((method) {
  //                   return CheckboxListTile(
  //                     title: Text(method),
  //                     value: selectedMethods.contains(method),
  //                     onChanged: (bool? selected) {
  //                       setState(() {
  //                         if (selected == true) {
  //                           selectedMethods.add(method);
  //                         } else {
  //                           selectedMethods.remove(method);
  //                         }
  //                       });
  //                     },
  //                   );
  //                 }).toList(),
  //               ),
  //             ),
  //             actions: <Widget>[
  //               TextButton(
  //                 onPressed: () => Navigator.pop(context),
  //                 child: const Text('Done'),
  //               ),
  //             ],
  //           );
  //         },
  //       );
  //     },
  //   );

  //   return selectedMethods;
  // }

  Future<List<String>> _showStudyMethodsDialog() async {
    List<String> selectedMethods = List.from(_savedStudyMethods);
    bool showAllMethods = false;

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
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Show either only saved methods or all methods
            List<String> displayedMethods =
                showAllMethods ? allStudyMethods : _savedStudyMethods;

            return AlertDialog(
              title: const Text('Select Study Methods Used'),
              content: SingleChildScrollView(
                child: Column(
                  children: displayedMethods.map((method) {
                    return CheckboxListTile(
                      title: Text(method),
                      value: selectedMethods.contains(method),
                      onChanged: (bool? selected) {
                        setState(() {
                          if (selected == true) {
                            selectedMethods.add(method);
                          } else {
                            selectedMethods.remove(method);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: <Widget>[
                if (!showAllMethods)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        showAllMethods = true;
                      });
                    },
                    child: const Text('More Options'),
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(context, selectedMethods),
                  child: const Text('Done'),
                ),
              ],
            );
          },
        );
      },
    );

    return selectedMethods;
  }

  // Log the study session to Firebase with selected methods
  // Future<void> _logStudySession(
  //     int rating, int actualStudyMinutes, List<String> studyMethods) async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   String? studentId = prefs.getString('studentId');

  //   if (studentId != null) {
  //     await FirebaseFirestore.instance
  //         .collection('student_codes')
  //         .doc(studentId)
  //         .collection('study_sessions')
  //         .add({
  //       'duration': _selectedDuration,
  //       'actual_study_time': actualStudyMinutes,
  //       'rating': rating,
  //       'study_methods_used': studyMethods, // Log selected study methods
  //       'timestamp': Timestamp.now(),
  //     });

  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Study session logged successfully!')),
  //     );
  //   } else {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Error: No student logged in.')),
  //     );
  //   }
  // }

  Future<void> _logStudySession(int rating, int actualStudyMinutes,
      List<String> studyMethods, String notes) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? studentId = prefs.getString('studentId');

    if (studentId != null) {
      await FirebaseFirestore.instance
          .collection('student_codes')
          .doc(studentId)
          .collection('study_sessions')
          .add({
        'duration': _selectedDuration,
        'actual_study_time': actualStudyMinutes,
        'rating': rating,
        'study_methods_used': studyMethods,
        'notes': notes, // Store the student's note
        'timestamp': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Study session logged successfully!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: No student logged in.')),
      );
    }
  }

  // Fetch the question from Firestore for the current week and display it with confidence rating
  Future<void> _fetchQuestionForCurrentWeek() async {
    final int currentWeek = getCurrentWeek(); // Dynamically determine the week

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('week_questions')
          .doc('week$currentWeek') // Fetch questions based on current week
          .collection('questions')
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Generate a random index to pick a random question
        final random = Random();
        final int randomIndex = random.nextInt(querySnapshot.docs.length);
        final randomQuestion = querySnapshot.docs[randomIndex]
            ['question']; // Get the random question

        setState(() {
          _fetchedQuestion = randomQuestion;
        });
        _showQuestionDialog(_fetchedQuestion!);
      } else {
        setState(() {
          // _fetchedQuestion = 'No question available for this week.';
          _fetchedQuestion = 'What is 2+2?';
        });
        _showQuestionDialog(_fetchedQuestion!);
      }
    } catch (e) {
      print('Error fetching question: $e');
    }
  }

  // Show a dialog with the fetched question
  Future<void> _showQuestionDialog(String question) async {
    int? confidenceRating = await showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Professor’s Question'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(question),
              const SizedBox(height: 20),
              const Text('How confident do you feel answering this question?'),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    icon: const Icon(Icons.sentiment_very_dissatisfied),
                    onPressed: () => Navigator.pop(context, 1),
                  ),
                  IconButton(
                    icon: const Icon(Icons.sentiment_dissatisfied),
                    onPressed: () => Navigator.pop(context, 2),
                  ),
                  IconButton(
                    icon: const Icon(Icons.sentiment_neutral),
                    onPressed: () => Navigator.pop(context, 3),
                  ),
                  IconButton(
                    icon: const Icon(Icons.sentiment_satisfied),
                    onPressed: () => Navigator.pop(context, 4),
                  ),
                  IconButton(
                    icon: const Icon(Icons.sentiment_very_satisfied),
                    onPressed: () => Navigator.pop(context, 5),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (confidenceRating != null) {
      _logConfidenceRating(
          confidenceRating, question); // Log the confidence rating
    }
  }

  Future<void> _logConfidenceRating(
      int confidenceRating, String question) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? studentId = prefs.getString('studentId');

    if (studentId != null) {
      try {
        await FirebaseFirestore.instance
            .collection('student_codes')
            .doc(studentId)
            .collection('confidence_ratings')
            .add({
          'question': question,
          'confidence_rating': confidenceRating,
          'timestamp': Timestamp.now(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Confidence rating logged successfully!')),
        );
      } catch (e) {
        print('Error logging confidence rating: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to log confidence rating.')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: No student logged in.')),
      );
    }
  }

  // Dialog for custom time input
  Future<void> _showCustomTimeDialog() async {
    final TextEditingController hoursController = TextEditingController();
    final TextEditingController minutesController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter Custom Time'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: hoursController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Hours'),
              ),
              TextField(
                controller: minutesController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Minutes'),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                final int hours = int.tryParse(hoursController.text) ?? 0;
                final int minutes = int.tryParse(minutesController.text) ?? 0;
                setState(() {
                  _selectedDuration = hours * 60 + minutes;
                });
                Navigator.pop(context);
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _getStudyMethods(); // Fetch study methods on page load
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Timer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      SettingsPage(), // Navigate to SettingsPage
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _showHistoryPage, // Open the history page
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout, // Call logout function
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Select Your Study Session',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 10.0,
              runSpacing: 10.0,
              children: [
                _buildDurationButton(15),
                _buildDurationButton(30),
                _buildDurationButton(45),
                _buildDurationButton(60),
                ElevatedButton(
                  onPressed: _isTimerRunning ? null : _showCustomTimeDialog,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  child:
                      const Text('Custom Time', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
            const SizedBox(height: 40),
            _isTimerRunning
                ? Text(
                    _formatTime(_remainingTime),
                    style: const TextStyle(
                        fontSize: 48, fontWeight: FontWeight.bold),
                  )
                : const Text('Choose a session to begin'),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _selectedDuration > 0 && !_isTimerRunning
                  ? () => _startTimer(_selectedDuration)
                  : null,
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              child:
                  const Text('Start Session', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(height: 20),
            if (_isTimerRunning) ...[
              ElevatedButton(
                onPressed: _isPaused ? _resumeTimer : _pauseTimer,
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                child: Text(_isPaused ? 'Resume' : 'Pause',
                    style: const TextStyle(fontSize: 18)),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _endSession,
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                child:
                    const Text('End Session', style: TextStyle(fontSize: 18)),
              ),
            ],
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showManualLoggingDialog(),
        tooltip: 'Log Past Session',
        child: const Icon(Icons.add),
        backgroundColor: const Color.fromARGB(255, 205, 193, 213),
      ),
    );
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Widget _buildDurationButton(int minutes) {
    return ElevatedButton(
      onPressed: _isTimerRunning
          ? null
          : () {
              setState(() {
                _selectedDuration = minutes;
              });
            },
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        backgroundColor: _selectedDuration == minutes
            ? Colors.purple[300]
            : Colors.purple[100],
      ),
      child: Text('$minutes min', style: const TextStyle(fontSize: 16)),
    );
  }
}
