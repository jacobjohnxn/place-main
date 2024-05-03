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

  bool _nameError = false;
  bool _collegeError = false;
  bool _cgpaError = false;
  bool _semesterError = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot userData = await _firestore
            .collection('users')
            .doc(user.uid)
            .get()
            .timeout(Duration(seconds: 5));
        if (userData.exists) {
          setState(() {
            _nameController.text = userData['name'] ?? '';
            _collegeController.text = userData['college'] ?? '';
            _cgpaController.text = userData['cgpa']?.toString() ?? '';
            _semesterController.text =
                userData['semester']?.toString() ?? '';
            _courses = List<String>.from(userData['courses'] ?? []);
            _calculateTotalScore();
          });
        } else {
          await _saveUserData();
        }
      } catch (e) {
        print('Error loading user data: $e');
      }
    }
  }

  Future<void> _saveUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      String name = _nameController.text.trim();
      String college = _collegeController.text.trim();
      double cgpa = double.tryParse(_cgpaController.text.trim()) ?? 0.0;
      int semester = int.tryParse(_semesterController.text.trim()) ?? 0;

      if (name.isNotEmpty && college.isNotEmpty) {
        await _firestore.collection('users').doc(user.uid).set({
          'name': name,
          'college': college,
          'cgpa': cgpa,
          'semester': semester,
          'courses': _courses,
        });
      } else {
        print('Name and College cannot be empty. Please fill in the details.');
      }
    }
  }

  Future<double> _getPredictedScore(String course) async {
    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:5000/predict'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({'course': course}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final double predictedScore = data['predicted_score'];
        return predictedScore.toDouble();
      } else {
        print('Failed to fetch predicted score: ${response.reasonPhrase}');
        return 0.0;
      }
    } catch (e) {
      print('Error predicting score: $e');
      return 0.0;
    }
  }

  void _calculateTotalScore() async {
    double total = 0.0;
    if (_courses.isNotEmpty) {
      for (var course in _courses) {
        double predictedScore = await _getPredictedScore(course);
        total += predictedScore;
      }
      total = (total * 0.5) +
          ((double.tryParse(_cgpaController.text) ?? 0.0) * 0.5);
    } else {
      total = (double.tryParse(_cgpaController.text) ?? 0.0) * 0.5;
    }
    setState(() {
      _totalScore = total.clamp(0.0, 9.9);
    });
  }

  Future<void> _addCourse(String name) async {
    try {
      double predictedScore = await _getPredictedScore(name);
      if (predictedScore != null) {
        setState(() {
          _courses.add(name);
          _calculateTotalScore();
        });
      }
    } catch (e) {
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
    if (_cgpaController.text.isNotEmpty &&
        (double.tryParse(_cgpaController.text) == null ||
            double.parse(_cgpaController.text) < 6 ||
            double.parse(_cgpaController.text) > 10)) {
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
            tooltip: 'Logout',
            onPressed: () {
              _signOut();
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
                height: 200,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/1.jpg'),
                    fit: BoxFit.cover,
                  ),
                  borderRadius: BorderRadius.circular(10.0),
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
                            errorText: _nameError ? 'Enter text without numbers' : null,
                          ),
                          onChanged: (_) {
                            setState(() {
                              _nameError = _nameController.text.isNotEmpty &&
                                  _nameController.text.contains(RegExp(r'[0-9]'));
                            });
                          },
                        ),
                        SizedBox(height: 10),
                        Text('College:'),
                        SizedBox(height: 5),
                        TextField(
                          controller: _collegeController,
                          decoration: InputDecoration(
                            hintText: 'Enter your college',
                            errorText: _collegeError ? 'Enter text without numbers' : null,
                          ),
                          onChanged: (_) {
                            setState(() {
                              _collegeError = _collegeController.text.isNotEmpty &&
                                  _collegeController.text.contains(RegExp(r'[0-9]'));
                            });
                          },
                        ),
                        SizedBox(height: 10),
                        Text('CGPA:'),
                        SizedBox(height: 5),
                        TextField(
                          controller: _cgpaController,
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            hintText: 'Enter your CGPA',
                            errorText: _cgpaError ? 'Enter a valid CGPA (0 to 10)' : null,
                          ),
                          onChanged: (_) {
                            setState(() {
                              _cgpaError = _cgpaController.text.isNotEmpty &&
                                  !RegExp(r'^\d*\.?\d*$').hasMatch(
                                      _cgpaController.text.trim());
                            });
                            _calculateTotalScore();
                          },
                        ),
                        SizedBox(height: 10),
                        Text('Semester:'),
                        SizedBox(height: 5),
                        TextField(
                          controller: _semesterController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'Enter your semester',
                            errorText: _semesterError ? 'Enter digits only' : null,
                          ),
                          onChanged: (_) {
                            setState(() {
                              _semesterError = _semesterController.text.isNotEmpty &&
                                  !RegExp(r'^\d*$').hasMatch(
                                      _semesterController.text.trim());
                            });
                          },
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
                        Text(
                          'Courses:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
                                String courseName =
                                    _courseController.text.trim();
                                if (courseName.isNotEmpty) {
                                  _addCourse(courseName);
                                } else {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(SnackBar(
                                    content: Text(
                                      'Please enter a course name.',
                                    ),
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
                  setState(() {
                    _nameError = _nameController.text.isNotEmpty &&
                        _nameController.text.contains(RegExp(r'[0-9]'));
                    _collegeError = _collegeController.text.isNotEmpty &&
                        _collegeController.text.contains(RegExp(r'[0-9]'));
                    _cgpaError = _cgpaController.text.isNotEmpty &&
                        !RegExp(r'^\d*\.?\d*$').hasMatch(
                            _cgpaController.text.trim());
                    _semesterError =
                        _semesterController.text.isNotEmpty &&
                            !RegExp(r'^\d*$').hasMatch(
                                _semesterController.text.trim());
                  });
                  if (!_nameError &&
                      !_collegeError &&
                      !_cgpaError &&
                      !_semesterError) {
                    _saveUserData();
                  }
                },
                child: Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
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

  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.of(context).pop();
    } catch (e) {
      print('Error signing out: $e');
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
