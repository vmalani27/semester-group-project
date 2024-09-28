import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:login_trial_2/auth/firebase/userdetails.dart';
import 'package:login_trial_2/homescreen/useraccountpage.dart';
import 'package:provider/provider.dart';
import 'auth/welcome_screen.dart';
import 'auth/register.dart';
import 'splash.dart';
import 'auth/login.dart';
import 'homescreen/message_tab.dart';
import 'homescreen/message_provider.dart';
import "package:cloud_firestore/cloud_firestore.dart";
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => MessageProvider1()),
        ChangeNotifierProvider(create: (context) => MessageProvider2()),
        ChangeNotifierProvider(create: (context) => MessageProvider3()),
      ],
      child: MyApp(),
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
        '/': (context) => Splash(),
        '/welcome': (context) => const Welcome(),
        '/register': (context) => Register(),
        '/login': (context) => Login(),
        '/homescreen': (context) => MessageTabs(),
        '/user-details': (context) => UserDetails(),
        '/user-account': (context) => UserAccountPage(),
      },
      builder: (context, child) {
        return Stack(
          children: [
            child!,
            UserAccountListener(), // Add the listener widget here
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
          // User document does not exist, log out the user
          FirebaseAuth.instance.signOut();
          Navigator.pushReplacementNamed(context, '/login');
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(); // No UI needed, just the listener
  }
}
