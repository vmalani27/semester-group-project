import 'package:flutter/material.dart';

class AppDataProvider with ChangeNotifier {
  List<String> gmailMessages = ["Gmail 1", "Gmail 2", "Gmail 3"];
  List<String> classroomMessages = [
    "Classroom 1",
    "Classroom 2",
    "Classroom 3"
  ];

  // Dummy method to simulate refreshing Gmail messages
  void refreshGmailMessages() {
    gmailMessages = ["New Gmail 1", "New Gmail 2"];
    notifyListeners();
  }

  // Dummy method to simulate refreshing WhatsApp messages

  // Dummy method to simulate refreshing Classroom messages
  void refreshClassroomMessages() {
    classroomMessages = ["New Classroom 1", "New Classroom 2"];
    notifyListeners();
  }
}
