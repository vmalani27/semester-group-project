import 'dart:convert'; // For base64 decoding
import 'package:googleapis/gmail/v1.dart';
import 'package:googleapis_auth/auth_io.dart'; // For AuthClient and OAuth2
import 'package:http/http.dart' as http; // HTTP package for API calls
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async'; // For TimeoutException handling
import 'package:login_trial_2/auth/firebase/gmail_service.dart'; // Import Gmail Service for API access

class GeminiSummaryService {
  final GenerativeModel _genAiClient;
  final ApiService _apiService;
  List<ClassifiedMessage> emailMessages = []; // List to store email messages
  bool isInitialized = false;

  /// Initialize the Gemini client with the specific model and API key
  GeminiSummaryService(String apiKey, this._apiService)
      : _genAiClient = GenerativeModel(
          model: 'gemini-1.5-flash', // Using the Gemini model version specified
          apiKey: 'AIzaSyBmW2XfRNchbrDCfQ2qRyhX_T62vCxUVT8',
        );

  /// Initialize the GeminiSummaryService
  Future<void> init() async {
    try {
      await _apiService.init(); // Initialize ApiService
      isInitialized = true; // Set initialized flag
      print('GeminiSummaryService initialized successfully.');
    } catch (e) {
      print('Error during GeminiSummaryService initialization: $e');
    }
  }

  /// Fetch emails and store them in the local list
  Future<void> fetchAndStoreEmails() async {
    if (!isInitialized) {
      print('Service not initialized. Please call init() first.');
      return;
    }

    try {
      final classifiedMessages = await _apiService.fetchAndClassifyEmails();
      emailMessages = classifiedMessages; // Store the classified messages
      print('Fetched and stored emails successfully.');
    } catch (e) {
      print('Error fetching and storing emails: $e');
    }
  }

  /// Summarizes the Gmail messages using the Gemini model
  Future<String> summarizeNotifications() async {
    if (!isInitialized || emailMessages.isEmpty) {
      return 'No emails to summarize or service not initialized.';
    }

    try {
      final prompt = 'Summarize the following emails:\n' +
          emailMessages.map((msg) => msg.message.snippet ?? 'No Subject').join('\n');

      final response = await _genAiClient.generateContent([Content.text(prompt)]);

      return response.text ?? 'No summary generated.';
    } catch (e) {
      print("Error summarizing notifications: $e");
      return 'Error generating summary';
    }
  }

  /// Extracts important assignments and deadlines from the summarized content
  Map<String, String> extractAssignments(String summary) {
    final assignmentPattern = RegExp(r'Assignment: (.*?)\nDeadline: (.*?)\n');
    final matches = assignmentPattern.allMatches(summary);
    Map<String, String> assignments = {};

    for (var match in matches) {
      String assignment = match.group(1) ?? 'Unknown assignment';
      String deadline = match.group(2) ?? 'Unknown deadline';
      assignments[assignment] = deadline;
    }

    return assignments;
  }

  /// Save assignments and their deadlines to Firestore
  Future<void> saveAssignmentsToFirestore(Map<String, String> assignments) async {
    CollectionReference assignmentsCollection =
        FirebaseFirestore.instance.collection('assignments');

    for (var entry in assignments.entries) {
      String assignmentName = entry.key;
      String deadline = entry.value;

      await assignmentsCollection.doc(assignmentName).set({
        'assignment': assignmentName,
        'deadline': deadline,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Retrieve all saved assignments from Firestore
  Future<List<Map<String, dynamic>>> fetchAssignmentsFromFirestore() async {
    CollectionReference assignmentsCollection =
        FirebaseFirestore.instance.collection('assignments');

    QuerySnapshot querySnapshot = await assignmentsCollection.get();
    List<QueryDocumentSnapshot> docs = querySnapshot.docs;

    List<Map<String, dynamic>> assignments = docs.map((doc) {
      return {
        'assignment': doc['assignment'],
        'deadline': doc['deadline'],
        'timestamp': doc['timestamp'],
      };
    }).toList();

    return assignments;
  }
}
