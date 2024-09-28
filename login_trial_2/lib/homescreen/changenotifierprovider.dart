import 'package:flutter/material.dart';
import 'package:login_trial_2/homescreen/appdataprovider.dart';
import 'package:login_trial_2/homescreen/tablayout.dart';
import 'package:provider/provider.dart';
// import 'app_data_provider.dart'; // import the provider file

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => AppDataProvider(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomeScreen(),
    );
  }
}
