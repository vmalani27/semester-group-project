import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:login_trial_2/homescreen/tablayout.dart';
import 'auth_service.dart'; // Import the updated auth service file

class UserDetails extends StatefulWidget {
  const UserDetails({super.key});

  @override
  _UserDetailsState createState() => _UserDetailsState();
}

class _UserDetailsState extends State<UserDetails> {
  final TextEditingController _rollNumberController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _semesterController = TextEditingController();
  final TextEditingController _branchController = TextEditingController();

  String _errorMessage = '';
  final AuthService _authService =
      AuthService(); // Use the new AuthService class

  @override
  void dispose() {
    _rollNumberController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _semesterController.dispose();
    _branchController.dispose();
    super.dispose();
  }

  // Method to safely call setState if the widget is still mounted
  void _safeSetState(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    }
  }

  void _saveDetails() async {
    if (_firstNameController.text.isEmpty ||
        _lastNameController.text.isEmpty ||
        _semesterController.text.isEmpty ||
        _branchController.text.isEmpty) {
      _safeSetState(() {
        _errorMessage = 'Please fill in all fields';
      });
    } else {
      _safeSetState(() {
        _errorMessage = '';
      });

      // Show a notice that the details are being saved
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Saving details and linking Google account...'),
          duration: Duration(seconds: 2),
        ),
      );

      // Sign in with Google and get user credentials
      try {
        User? user = await _authService.signInWithGoogle(context);

        if (user != null) {
          final String? photoURL =
              user.photoURL; // Check for the photo URL from the user object

          // Save user details to Firestore
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
            'rollNumber': _rollNumberController.text.trim(),
            'firstName': _firstNameController.text.trim(),
            'lastName': _lastNameController.text.trim(),
            'semester': _semesterController.text.trim(),
            'branch': _branchController.text.trim(),
            'email': user.email,
            'profilePicture': photoURL ?? '',
            'apiIntegrationStatus': 'linked', // Mark as linked
            'integrationDetails': {
              'integrationType': 'Google',
              'integrationDate': Timestamp.fromDate(
                  DateTime.now().toUtc()), // Correctly formatted date
            },
          });

          // Wait for the notice to be dismissed
          await Future.delayed(const Duration(seconds: 2));

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Details saved successfully!')),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    HomeScreen()), // Replace with your actual home screen widget
          );
        }
      } catch (e) {
        // Handle any errors during account linking or saving
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to link account: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Container(
              constraints: const BoxConstraints(
                  maxWidth: 600), // Limit max width if needed
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Align(
                    alignment: Alignment.topCenter,
                    child: Text(
                      'User Details',
                      style:
                          TextStyle(fontSize: 50, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _rollNumberController,
                    decoration: InputDecoration(
                      labelText: 'Roll Number',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _firstNameController,
                    decoration: InputDecoration(
                      labelText: 'First Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _lastNameController,
                    decoration: InputDecoration(
                      labelText: 'Last Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _semesterController,
                    decoration: InputDecoration(
                      labelText: 'Semester',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _branchController,
                    decoration: InputDecoration(
                      labelText: 'Branch',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _saveDetails,
                    child: const Text('Save Details'),
                  ),
                  if (_errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
