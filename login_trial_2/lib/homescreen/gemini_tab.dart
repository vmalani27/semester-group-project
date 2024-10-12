import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:login_trial_2/auth/firebase/gmail_service.dart'; // Your Gmail service
import 'package:login_trial_2/auth/firebase/gemini_service.dart'; // Import the service

class GeminiTab extends StatefulWidget {
  final GeminiSummaryService geminiService;

  const GeminiTab({super.key, required this.geminiService});

  @override
  _GeminiTabState createState() => _GeminiTabState();
}

class _GeminiTabState extends State<GeminiTab> {
  String summary = 'No summary generated yet.';
  bool isLoading = false;
  List<Map<String, dynamic>> assignments = []; // List to store assignments

  @override
  void initState() {
    super.initState();
    widget.geminiService.init(); // Initialize Gemini Service
  }

  // Fetch emails, summarize, and display results
  Future<void> generateSummary() async {
    setState(() {
      isLoading = true;
    });

    try {
      await widget.geminiService
          .fetchAndStoreEmails(); // Fetch and store emails
      String generatedSummary =
          await widget.geminiService.summarizeNotifications();
      setState(() {
        summary = generatedSummary;
      });

      // Extract assignments from the summary and save to Firestore
      Map<String, String> extractedAssignments =
          widget.geminiService.extractAssignments(generatedSummary);
      await widget.geminiService
          .saveAssignmentsToFirestore(extractedAssignments);
      print('Assignments saved successfully');
    } catch (e) {
      print('Error generating summary: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Fetch assignments from Firestore and update UI
  Future<void> fetchAssignments() async {
    try {
      List<Map<String, dynamic>> fetchedAssignments =
          await widget.geminiService.fetchAssignmentsFromFirestore();
      setState(() {
        assignments = fetchedAssignments;
      });
    } catch (e) {
      print('Error fetching assignments: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gemini Summary'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed:
                fetchAssignments, // Fetch assignments when refresh is pressed
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator()) // Show loading indicator
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Email Summary:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Text(summary), // Display the generated summary
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed:
                        generateSummary, // Button to trigger email fetching and summarization
                    child: Text('Generate Summary'),
                  ),
                  SizedBox(height: 30),
                  Text(
                    'Assignments:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  assignments.isEmpty
                      ? Text('No assignments found.')
                      : ListView.builder(
                          shrinkWrap:
                              true, // To make the ListView fit within the column
                          itemCount: assignments.length,
                          itemBuilder: (context, index) {
                            final assignment = assignments[index];
                            return ListTile(
                              title: Text(
                                  'Assignment: ${assignment['assignment']}'),
                              subtitle:
                                  Text('Deadline: ${assignment['deadline']}'),
                              trailing: Text(
                                  'Added: ${(assignment['timestamp'] as Timestamp).toDate()}'),
                            );
                          },
                        ),
                ],
              ),
            ),
    );
  }
}
