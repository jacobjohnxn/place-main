// ignore_for_file: file_names, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _emailError = false; // Define _emailError variable to track email format validity

  Future<void> _signUp() async {
    try {
      final String email = _emailController.text.trim();
      final String password = _passwordController.text.trim();

      // Validate the email format
      bool isValidEmail = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
      
      if (!isValidEmail) {
        setState(() {
          _emailError = true;
        });
        return; // Exit signUp function if email is not valid
      }

      // Create user with email and password
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // User successfully registered, navigate to another screen or do something else
      Navigator.pop(context); // Close SignUpPage and return to the previous screen
    } catch (e) {
      // Handle registration errors
      print('Failed to sign up: $e');
      // You can also show a snackbar or dialog to inform the user about the error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Up'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
              ),
            ),
            const SizedBox(height: 12.0),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              onChanged: (value) {
                setState(() {
                  // Reset the error state when user changes the email
                  _emailError = false;
                });
              },
              decoration: InputDecoration(
                labelText: 'Email',
                errorText: _emailError ? 'Enter a valid email' : null,
              ),
            ),
            const SizedBox(height: 12.0),
            TextField(
            controller: _passwordController,
            obscureText: true,
            onChanged: (_) {
              setState(() {}); // Trigger rebuild when password changes
            },
            decoration: InputDecoration(
              labelText: 'Password',
              errorText: _passwordController.text.isNotEmpty && _passwordController.text.length < 6
                  ? 'Password should be at least 6 characters'
                  : null,
            ),
          ),

            const SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: _signUp, // Call _signUp function when the button is pressed
              child: const Text('Sign Up'),
            ),
          ],
        ),
      ),
    );
  }
}