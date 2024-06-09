# Student Placement Probability App

This is a Flutter application designed to predict student placement probabilities based on various parameters such as CGPA, semester, and courses. The app interacts with a backend prediction server to fetch the predicted scores.

## Features

- User Authentication with Firebase
- Integration with Firestore to save user data
- Prediction of scores based on courses using a Flask backend
- Interactive UI to add and remove courses
- Dynamic calculation of total score

## Requirements

- Flutter SDK
- Firebase account and project setup
- Python with Flask and required libraries

## Setup Instructions

### 1. Clone the Repository

```sh
git clone https://github.com/your-username/student-placement-probability.git
cd student-placement-probability
```
2. Install Flutter

Ensure you have Flutter installed. You can follow the official Flutter installation guide.

3. Set Up Firebase
```
    Create a Firebase project in the Firebase Console.
    Add an Android/iOS app to your Firebase project.
    Download the google-services.json (for Android) or GoogleService-Info.plist (for iOS) and place it in the appropriate directory:
        android/app for google-services.json
        ios/Runner for GoogleService-Info.plist
    Enable Firebase Authentication and Firestore in the Firebase console.
```
4. Update Project Configuration

Update the pubspec.yaml with the necessary dependencies and ensure Firebase is initialized in your Flutter project. Follow the FlutterFire documentation for detailed instructions.

5. Install Python Dependencies

Navigate to the prediction_server directory and install the required Python packages.
```
sh
cd prediction_server
pip install -r requirements.txt
```

6. Run the Prediction Server

Run the predictionserver.py script to start the backend server.
```
sh
python predictionserver.py
```

7. Update Server URL

Ensure the URL in your Flutter app points to the prediction server. Modify the URL in _getPredictedScore method if necessary.

dart

Future<double> _getPredictedScore(String course) async {
  try {
    final response = await http.post(
      Uri.parse('http://127.0.0.1:5000/predict'), // Update this URL if needed
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({'course': course}),
    );
    // ...
  } catch (e) {
    // ...
  }
}

8. Run the Flutter App

Navigate back to the root directory of your project and run the Flutter app.
```
sh
cd ..
flutter pub get
flutter run
```

Usage

    Register or log in using your email and password.
    Enter your details such as name, college, CGPA, and semester.
    Add courses to calculate the predicted placement score.
    Save the data to Firestore.

Project Structure

    lib: Contains the main Flutter application code.
    prediction_server: Contains the Python Flask server code for predictions.
    pubspec.yaml: Flutter project configuration file.
    
