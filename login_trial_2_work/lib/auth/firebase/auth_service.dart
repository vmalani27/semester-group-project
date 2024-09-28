import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Define a public function for Google Sign-In
Future<void> linkGoogleAccount(BuildContext context) async {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
  String errorMessage = '';

  try {
    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      errorMessage = 'Google Sign-In aborted by user';
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(errorMessage)));
      }
      return;
    }

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    UserCredential userCredential =
        await _auth.currentUser!.linkWithCredential(credential);

    if (userCredential.user != null) {
      final profilePictureUrl = googleUser.photoUrl;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'linkedGmail': userCredential.user!.email,
        'profilePicture': profilePictureUrl,
      }, SetOptions(merge: true));
    }

    if (context.mounted) {
      Navigator.pushReplacementNamed(context, '/homescreen');
    }
  } catch (e) {
    if (e is FirebaseAuthException && e.code == 'provider-already-linked') {
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/homescreen');
      }
    } else {
      errorMessage = 'Failed to link Google account: $e';
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(errorMessage)));
      }
    }
  }
}
