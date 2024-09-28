import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:login_trial_2/auth/firebase/auth_service.dart';
import 'dart:io';

class UserDetails extends StatefulWidget {
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
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void dispose() {
    _rollNumberController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _semesterController.dispose();
    _branchController.dispose();
    super.dispose();
  }

  void _saveDetails() async {
    if (_firstNameController.text.isEmpty ||
        _lastNameController.text.isEmpty ||
        _semesterController.text.isEmpty ||
        _branchController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please fill in all fields';
      });
    } else {
      setState(() {
        _errorMessage = '';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saving details and linking Google account...'),
          duration: Duration(seconds: 2),
        ),
      );

      User? user = _auth.currentUser;
      if (user != null) {
        String? photoURL = user.photoURL; // Get the current user's photo URL

        // Check if there is an existing photo URL
        if (photoURL != null && photoURL.isNotEmpty) {
          try {
            // Define the path to upload in Firebase Storage
            String storagePath = 'userProfilePictures/${user.uid}.jpg';

            // Upload the profile picture to Firebase Storage
            Reference ref = FirebaseStorage.instance.ref().child(storagePath);
            await ref.putFile(File(photoURL));

            // Get the download URL from Firebase Storage
            photoURL = await ref.getDownloadURL();
          } catch (e) {
            print('Error uploading profile picture: $e');
          }
        }

        // Store user details in Firestore, including the profile picture URL
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'rollNumber': _rollNumberController.text.trim(),
          'firstName': _firstNameController.text.trim(),
          'lastName': _lastNameController.text.trim(),
          'semester': _semesterController.text.trim(),
          'branch': _branchController.text.trim(),
          'email': user.email,
          'profilePicture':
              photoURL, // Save the photo URL or Firebase Storage path
        });
      }

      await Future.delayed(Duration(seconds: 2));

      // Call the public function to link the Google account
      linkGoogleAccount(context);
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
              constraints: BoxConstraints(maxWidth: 600),
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
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
                  Align(
                    alignment: Alignment.topCenter,
                    child: Text(
                      'User Details',
                      style:
                          TextStyle(fontSize: 50, fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: _rollNumberController,
                    decoration: InputDecoration(
                      labelText: 'Roll Number',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: _firstNameController,
                    decoration: InputDecoration(
                      labelText: 'First Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: _lastNameController,
                    decoration: InputDecoration(
                      labelText: 'Last Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: _semesterController,
                    decoration: InputDecoration(
                      labelText: 'Semester',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: _branchController,
                    decoration: InputDecoration(
                      labelText: 'Branch',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    _errorMessage,
                    style: TextStyle(color: Colors.red),
                  ),
                  SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _saveDetails,
                    child: Text('Save Details'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.lightBlue,
                      padding:
                          EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                      textStyle:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text("Go Back"),
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
