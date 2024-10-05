import 'dart:convert'; // Import for base64 decoding

import 'package:flutter/material.dart';
import 'package:googleapis/gmail/v1.dart';
import 'package:login_trial_2/auth/firebase/auth_service.dart';
import 'package:login_trial_2/auth/firebase/gmail_service.dart';
import 'package:login_trial_2/homescreen/fullemaiscreen.dart';
import 'package:provider/provider.dart';

class GmailTab extends StatefulWidget {
  final ApiService apiService;

  const GmailTab({super.key, required this.apiService});

  @override
  _GmailTabState createState() => _GmailTabState();
}

class _GmailTabState extends State<GmailTab> {
  List<ClassifiedMessage> priorityMessages = [];
  List<ClassifiedMessage> optionalMessages = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeApiService();
  }

  Future<void> _initializeApiService() async {
    setState(() {
      isLoading = true;
    });

    try {
      await widget.apiService.init();
      await _fetchAndClassifyEmails();
    } catch (e) {
      print('Error initializing ApiService: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error initializing ApiService: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchAndClassifyEmails() async {
    setState(() {
      isLoading = true;
    });

    try {
      final client = await Provider.of<AuthService>(context, listen: false)
          .getAuthClient();

      if (client == null) {
        print('AuthClient is null, cannot fetch emails.');
        return;
      }

      final classifiedMessages =
          await widget.apiService.fetchAndClassifyEmails();

      setState(() {
        priorityMessages = classifiedMessages
            .where((message) => message.spamProbability > 0.5)
            .toList();
        optionalMessages = classifiedMessages
            .where((message) => message.spamProbability <= 0.5)
            .toList();
      });
    } catch (e) {
      print('Error fetching and classifying emails: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching and classifying emails: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : DefaultTabController(
            length: 2,
            child: Scaffold(
              appBar: AppBar(
                title: const Text("Classified Emails"),
                bottom: const TabBar(
                  tabs: [
                    Tab(text: "Priority"),
                    Tab(text: "Optional"),
                  ],
                ),
              ),
              body: TabBarView(
                children: [
                  _buildEmailList(priorityMessages, "Priority"),
                  _buildEmailList(optionalMessages, "Optional"),
                ],
              ),
            ),
          );
  }

  Widget _buildEmailList(List<ClassifiedMessage> messages, String category) {
    return messages.isEmpty
        ? Center(child: Text('No $category emails found.'))
        : ListView.builder(
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final classifiedMessage = messages[index];
              final message = classifiedMessage.message;

              final fromHeader = message.payload?.headers
                  ?.firstWhere(
                    (header) => header.name == 'From',
                    orElse: () =>
                        MessagePartHeader(name: 'From', value: 'No sender'),
                  )
                  ?.value;

              final dateHeader = message.payload?.headers
                  ?.firstWhere(
                    (header) => header.name == 'Date',
                    orElse: () =>
                        MessagePartHeader(name: 'Date', value: 'No date'),
                  )
                  ?.value;

              final subject = message.snippet ?? 'No Subject';
              final sender = fromHeader ?? 'Unknown Sender';
              final date = dateHeader ?? 'Unknown Date';

              // Get full email body and decode it
              String body = _getDecodedBody(message);

              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Card(
                  elevation: 3.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  child: ListTile(
                    title: Text(
                      subject,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.0,
                        color: Colors.black87,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8.0),
                        Text(
                          'From: $sender',
                          style: const TextStyle(
                            fontSize: 14.0,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          'Date: $date',
                          style: const TextStyle(
                            fontSize: 12.0,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                    trailing: const Icon(Icons.arrow_forward,
                        color: Colors.blueAccent),
                    onTap: () {
                      // Navigate to the FullEmailScreen on tap
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FullEmailScreen(
                            subject: subject,
                            sender: sender,
                            date: date,
                            body: body, // Pass the decoded email body
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
  }

  // Helper function to decode email body
  String _getDecodedBody(Message message) {
    final bodyData = message.payload?.parts
        ?.firstWhere(
            (part) =>
                part.mimeType == 'text/plain' || part.mimeType == 'text/html',
            orElse: () => MessagePart())
        ?.body
        ?.data;

    if (bodyData != null) {
      // Decode base64url encoded string
      return utf8.decode(base64Url.decode(bodyData));
    } else {
      return 'No content available';
    }
  }
}
