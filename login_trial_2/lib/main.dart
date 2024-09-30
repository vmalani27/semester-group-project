import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:login_trial_2/auth/firebase/auth_service.dart';
import 'package:login_trial_2/auth/firebase/userdetails.dart';
import 'package:login_trial_2/homescreen/appdataprovider.dart';
import 'package:login_trial_2/homescreen/useraccountpage.dart';
import 'package:provider/provider.dart';
import 'auth/welcome_screen.dart';
import 'auth/register.dart';
import 'splash.dart';
import 'auth/login.dart';
import 'package:login_trial_2/homescreen/tablayout.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:login_trial_2/homescreen/tablayout.dart';
// import 'package:login_trial_2/auth/gapps_auth.dart';
// import 'package:google_sign_in/google_sign_in.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AppDataProvider()),
        ChangeNotifierProvider(create: (Context) => AuthService())
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const Splash(),
        '/welcome': (context) => const Welcome(),
        '/register': (context) => const Register(),
        '/login': (context) => const Login(),
        '/homescreen': (context) => HomeScreen(),
        '/user-details': (context) => const UserDetails(),
        '/user-account': (context) => const UserAccountPage(),
      },
      // Add UserAccountListener in the builder method
      builder: (context, child) {
        return Stack(
          children: [
            child!,
            const UserAccountListener(), // Background listener
          ],
        );
      },
    );
  }
}

class UserAccountListener extends StatefulWidget {
  const UserAccountListener({super.key});

  @override
  _UserAccountListenerState createState() => _UserAccountListenerState();
}

class _UserAccountListenerState extends State<UserAccountListener> {
  @override
  void initState() {
    super.initState();
    _listenToUserAccount();
    _checkAndUpdateProfilePicture(); // Check and update the profile picture if needed
  }

  void _listenToUserAccount() {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .listen((DocumentSnapshot documentSnapshot) {
        if (!documentSnapshot.exists) {
          // If the user document does not exist, log out and redirect to login
          FirebaseAuth.instance.signOut();
          Navigator.pushReplacementNamed(context, '/login');
        }
      });
    }
  }

  Future<void> _checkAndUpdateProfilePicture() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // Check Firestore for user's document and update profile picture
        DocumentSnapshot<Map<String, dynamic>> userDoc = await FirebaseFirestore
            .instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          _updateProfilePictureIfNeeded(user);
        } else {
          print('User document does not exist in Firestore.');
        }
      } else {
        print('No user is currently signed in.');
      }
    } catch (e) {
      print('Error checking or updating profile picture: $e');
    }
  }

  Future<void> _updateProfilePictureIfNeeded(User user) async {
    try {
      // Fetch current profile picture URL
      String? currentProfilePictureUrl = user.photoURL;

      // Get the profile picture URL from Firestore and compare
      DocumentSnapshot<Map<String, dynamic>> userDoc = await FirebaseFirestore
          .instance
          .collection('users')
          .doc(user.uid)
          .get();

      String? storedProfilePictureUrl = userDoc.data()?['profilePicture'];

      if (currentProfilePictureUrl != storedProfilePictureUrl) {
        // Update the profile picture in Firestore if needed
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'profilePicture': currentProfilePictureUrl});
      }
    } catch (e) {
      print('Error updating profile picture: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink(); // No UI needed
  }
}
