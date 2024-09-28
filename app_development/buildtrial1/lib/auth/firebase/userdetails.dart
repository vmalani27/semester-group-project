import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:googleapis/gmail/v1.dart' as gMail;
import 'package:googleapis_auth/auth_io.dart';

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
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  gMail.GmailApi? gmailApi;
  List<gMail.Message> messagesList = [];

  @override
  void dispose() {
    _rollNumberController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _semesterController.dispose();
    _branchController.dispose();
    super.dispose();
  }

  Future<void> _linkGoogleAccount() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      final GoogleSignInAuthentication googleAuth =
          await googleUser!.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Link the Google account with Firebase
      await _auth.currentUser!.linkWithCredential(credential);

      // Initialize Gmail API client
      final authHeaders = await googleUser.authHeaders;
      final authenticateClient = GoogleAuthClient(authHeaders);
      gmailApi = gMail.GmailApi(authenticateClient);

      // Fetch messages from Gmail API
      _fetchEmails();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to link Google account: $e';
      });
    }
  }

  Future<void> _fetchEmails() async {
    if (gmailApi == null) return;

    gMail.ListMessagesResponse results =
        await gmailApi!.users.messages.list("me");
    for (gMail.Message message in results.messages!) {
      gMail.Message messageData =
          await gmailApi!.users.messages.get("me", message.id!);
      setState(() {
        messagesList.add(messageData);
      });
    }
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

      // Show a notice that the details are being saved
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Saving details and linking Google account...'),
          duration: Duration(seconds: 2),
        ),
      );

      // Save user details to Firestore
      User? user = _auth.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'rollNumber': _rollNumberController.text.trim(),
          'firstName': _firstNameController.text.trim(),
          'lastName': _lastNameController.text.trim(),
          'semester': _semesterController.text.trim(),
          'branch': _branchController.text.trim(),
          'email': user.email,
        });
      }

      // Wait for the notice to be dismissed
      await Future.delayed(const Duration(seconds: 2));

      // Proceed to link Google account
      _linkGoogleAccount();
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
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _saveDetails,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.lightBlue,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 50, vertical: 15),
                      textStyle: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 25),
                    ),
                    child: Text('Save Details'),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context); // Go back to the previous screen
                    },
                    child: const Text("Go Back"),
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
