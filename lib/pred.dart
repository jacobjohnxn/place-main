import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PredictionPage extends StatefulWidget {
  @override
  _PredictionPageState createState() => _PredictionPageState();
}

class _PredictionPageState extends State<PredictionPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  TextEditingController _nameController = TextEditingController();
  TextEditingController _collegeController = TextEditingController();
  TextEditingController _cgpaController = TextEditingController();
  TextEditingController _semesterController = TextEditingController();
  TextEditingController _courseController = TextEditingController();
  List<String> _courses = [];
  double _totalScore = 0.0;

  @override
  void initState() {
    super.initState();
    // Load user data when the page is initialized
    _loadUserData();
  }

  Future<void> _loadUserData() async {
  // Retrieve user data from Firestore
  User? user = _auth.currentUser;
  if (user != null) {
    try {
      DocumentSnapshot userData = await _firestore.collection('users').doc(user.uid).get().timeout(Duration(seconds: 5)); // Set a timeout of 5 seconds
      if (userData.exists) {
        setState(() {
          _nameController.text = userData['name'] ?? '';
          _collegeController.text = userData['college'] ?? '';
          _cgpaController.text = userData['cgpa']?.toString() ?? '';
          _semesterController.text = userData['semester']?.toString() ?? '';
          _courses = List<String>.from(userData['courses'] ?? []);
          _calculateTotalScore();
        });
      } else {
        // If user data doesn't exist, add new user data to Firestore
        await _saveUserData();
      }
    } catch (e) {
      // Handle timeout or other errors
      print('Error loading user data: $e');
    }
  }
}


  // Modified _saveUserData to ensure it's called at an appropriate time
Future<void> _saveUserData() async {
  // Save user data to Firestore
  User? user = _auth.currentUser;
  if (user != null) {
    // Check if the text controllers contain valid data before saving
    String name = _nameController.text.trim();
    String college = _collegeController.text.trim();
    double cgpa = double.tryParse(_cgpaController.text.trim()) ?? 0.0;
    int semester = int.tryParse(_semesterController.text.trim()) ?? 0;

    if (name.isNotEmpty && college.isNotEmpty) {
      // Save data only if name and college are not empty
      await _firestore.collection('users').doc(user.uid).set({
        'name': name,
        'college': college,
        'cgpa': cgpa,
        'semester': semester,
        'courses': _courses,
      });
    } else {
      // Show a message or handle the case where name or college is empty
      print('Name and College cannot be empty. Please fill in the details.');
    }
  }
}

// Example of calling _saveUserData when a "Save" button is pressed


  Future<double> _getPredictedScore(String course) async {
    try {
      // Make HTTP POST request to send course to the backend for prediction
      final response = await http.post(
        Uri.parse('http://127.0.0.1:5000/predict'),
        headers: {
          'Content-Type': 'application/json', // Set Content-Type header
        },
        body: json.encode({'course': course}), // Encode request body as JSON
      );

      if (response.statusCode == 200) {
        // Parse the response body to get the predicted score
        final Map<String, dynamic> data = json.decode(response.body);
        final double predictedScore = data['predicted_score'];
        return predictedScore.toDouble(); // Convert predictedScore to double
      } else {
        // Handle errors
        print('Failed to fetch predicted score: ${response.reasonPhrase}');
        return 0.0; // Return a default value or handle the error accordingly
      }
    } catch (e) {
      // Handle network errors or other exceptions
      print('Error predicting score: $e');
      return 0.0; // Return a default value or handle the error accordingly
    }
  }

  void _calculateTotalScore() async {
    double total = 0.0;
    if (_courses.isNotEmpty) {
      // Calculate the total score for courses
      for (var course in _courses) {
        double predictedScore = await _getPredictedScore(course);
        total += predictedScore;
      }
      // Add half of the total score for courses to half of the CGPA
      total = (total * 0.5) + ((double.tryParse(_cgpaController.text) ?? 0.0) * 0.5);
    } else {
      // If no courses are entered, only consider the CGPA
      total = (double.tryParse(_cgpaController.text) ?? 0.0) * 0.5;
    }
    setState(() {
      _totalScore = total.clamp(0.0, 9.9); // Clamp total score to maximum 9.9
    });
  }

  Future<void> _addCourse(String name) async {
    try {
      // Call _getPredictedScore() to get the predicted score for the course
      double predictedScore = await _getPredictedScore(name);
      // ignore: unnecessary_null_comparison
      if (predictedScore != null) {
        setState(() {
          _courses.add(name);
          _calculateTotalScore();
        });
      }
    } catch (e) {
      // Handle errors
      print('Error adding course: $e');
    }
  }

  void _deleteCourse(int index) {
    setState(() {
      _courses.removeAt(index);
      _calculateTotalScore();
    });
  }

  String _getCircleText() {
    if (_cgpaController.text.isNotEmpty && double.parse(_cgpaController.text) < 6.0) {
      return 'NA';
    } else {
      return _totalScore.toStringAsFixed(2);
    }
  }

   @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Prediction Page'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              _signOut(); // Call the sign out function when the button is pressed
            },
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 200, // Set a fixed height for the container
                color: Colors.grey,
                child: Center(
                  child: Image.asset('assets/1.jpg'),
                ),
              ),
              
              SizedBox(height: 20),
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _getCircleColor(),
                ),
                child: Center(
                  child: Text(
                    _getCircleText(),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Divider(),
              SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Name:'),
                        SizedBox(height: 5),
                        TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            hintText: 'Enter your name',
                          ),
                        ),
                        SizedBox(height: 10),
                        Text('College:'),
                        SizedBox(height: 5),
                        TextField(
                          controller: _collegeController,
                          decoration: InputDecoration(
                            hintText: 'Enter your college',
                          ),
                        ),
                        SizedBox(height: 10),
                        Text('CGPA:'),
                        SizedBox(height: 5),
                        TextField(
                          controller: _cgpaController,
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            hintText: 'Enter your CGPA',
                          ),
                          onChanged: (_) => _calculateTotalScore(),
                        ),
                        SizedBox(height: 10),
                        Text('Semester:'),
                        SizedBox(height: 5),
                        TextField(
                          controller: _semesterController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'Enter your semester',
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 20),
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Courses:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _courseController,
                                decoration: InputDecoration(
                                  hintText: 'Enter course name',
                                ),
                              ),
                            ),
                            SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: () {
                                String courseName = _courseController.text.trim();
                                if (courseName.isNotEmpty) {
                                  _addCourse(courseName);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                    content: Text('Please enter a course name.'),
                                  ));
                                }
                                _courseController.clear();
                              },
                              child: Text('Add'),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        ListView.builder(
                          shrinkWrap: true,
                          itemCount: _courses.length,
                          itemBuilder: (context, index) {
                            return Column(
                              children: [
                                ListTile(
                                  title: Text(_courses[index]),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    _deleteCourse(index);
                                  },
                                  child: Text('Delete'),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              ElevatedButton(
                  onPressed: () {
                    // Call _saveUserData when the user interacts with the "Save" button
                    _saveUserData();
                  },
                  child: Text('Save'),
                ),
            ],
          ),
        ),
      ),
    );
  }
Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      // Navigate to the login page or any other page you desire after signing out
      Navigator.of(context).pop(); // Navigate back to the previous screen
    } catch (e) {
      print('Error signing out: $e');
    }
  }
  Color _getCircleColor() {
    if (_totalScore >= 9.0) {
      return Colors.green;
    } else if (_totalScore >= 6.0) {
      return Colors.yellow;
    } else {
      return Colors.red;
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MaterialApp(
    home: PredictionPage(),
  ));
}