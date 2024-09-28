import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart'; // Import for AuthClient

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
      'https://www.googleapis.com/auth/gmail.readonly',
      'https://www.googleapis.com/auth/classroom.announcements.readonly',
      'https://www.googleapis.com/auth/classroom.courses.readonly',
      'https://www.googleapis.com/auth/classroom.profile.emails',
      'https://www.googleapis.com/auth/classroom.profile.photos',
    ],
  );

  // Variables to hold access token and expiry
  String? _accessToken;
  DateTime? _accessTokenExpiry;

  // Getters for access token and expiry
  String? get accessToken => _accessToken;
  DateTime? get accessTokenExpiry => _accessTokenExpiry;

  // Sign in with Google and fetch token
  Future<User?> signInWithGoogle(BuildContext context) async {
    try {
      // Initiate Google Sign-In process
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _showMessage(context, 'Google Sign-In canceled by user.');
        return null;
      }

      // Authenticate with Google
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Retrieve access token and expiry time
      _accessToken = googleAuth.accessToken;
      _accessTokenExpiry = DateTime.now()
          .toUtc()
          .add(const Duration(hours: 1)); // Assuming token lasts 1 hour

      // Store tokens in local storage
      await _storeAccessToken(_accessToken!, _accessTokenExpiry!);

      // Firebase authentication
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      // Store user details in Firestore
      await _storeUserDetailsInFirestore(userCredential.user, googleUser);

      // Notify listeners of change
      notifyListeners();

      return userCredential.user;
    } catch (e) {
      _showMessage(context, 'Error signing in with Google: $e');
      return null;
    }
  }

  // Get AuthClient for making API requests
  Future<http.Client?> getAuthClient() async {
    await _loadAccessToken();
    if (_accessToken == null) {
      return null; // Token is not available
    }

    // Create a client using the stored access token
    final client = authenticatedClient(
      http.Client(),
      AccessCredentials(
        AccessToken(
          'Bearer',
          _accessToken!,
          _accessTokenExpiry!.toUtc(),
        ),
        null,
        [],
      ),
    );
    return client;
  }

  // Sign out from Firebase and Google
  Future<void> signOut(BuildContext context) async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      _accessToken = null;
      _accessTokenExpiry = null;
      notifyListeners();
    } catch (e) {
      _showMessage(context, 'Error signing out: $e');
    }
  }

  // Silent sign-in for refreshing tokens
  Future<void> silentSignIn(BuildContext context) async {
    try {
      final GoogleSignInAccount? googleUser =
          await _googleSignIn.signInSilently();
      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        // Update access token and expiry
        _accessToken = googleAuth.accessToken;
        _accessTokenExpiry =
            DateTime.now().toUtc().add(const Duration(hours: 1));
        await _storeAccessToken(_accessToken!, _accessTokenExpiry!);

        notifyListeners();
      } else {
        _showMessage(context, 'Silent sign-in failed.');
      }
    } catch (e) {
      _showMessage(context, 'Error during silent sign-in: $e');
    }
  }

  // Check if token needs refreshing and refresh if necessary
  Future<void> refreshTokenIfNeeded(BuildContext context) async {
    await _loadAccessToken();
    if (_accessToken == null ||
        _accessTokenExpiry == null ||
        _accessTokenExpiry!.isBefore(DateTime.now())) {
      await silentSignIn(context);
    }
  }

  // Load stored access token from local storage
  Future<void> _loadAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('accessToken');
    String? expiryStr = prefs.getString('accessTokenExpiry');
    _accessTokenExpiry = expiryStr != null ? DateTime.parse(expiryStr) : null;
  }

  // Store access token in local storage
  Future<void> _storeAccessToken(String token, DateTime expiry) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('accessToken', token);
    await prefs.setString('accessTokenExpiry', expiry.toIso8601String());
  }

  // Store user details in Firestore
  Future<void> _storeUserDetailsInFirestore(
      User? user, GoogleSignInAccount googleUser) async {
    if (user == null) return;

    final userDoc =
        FirebaseFirestore.instance.collection('users').doc(user.uid);

    // Fetch user data and update Firestore
    await userDoc.set({
      'linkedGmail': user.email,
      'profilePicture': googleUser.photoUrl ?? '',
      'name': user.displayName ?? '',
      'lastLogin': DateTime.now().toUtc(),
    }, SetOptions(merge: true));
  }

  // Helper function to show messages in UI
  void _showMessage(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }
}
