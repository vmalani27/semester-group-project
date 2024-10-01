import 'package:flutter/material.dart';
import 'package:googleapis/gmail/v1.dart';
import 'package:login_trial_2/auth/firebase/auth_service.dart';
import 'package:login_trial_2/auth/firebase/gmail_service.dart'; // Ensure ApiService is imported
import 'package:provider/provider.dart';

class GmailTab extends StatefulWidget {
  final ApiService apiService;

  const GmailTab({super.key, required this.apiService});

  @override
  _GmailTabState createState() => _GmailTabState();
}

class _GmailTabState extends State<GmailTab> {
  List<ClassifiedMessage> priorityMessages = []; // For priority emails
  List<ClassifiedMessage> optionalMessages = []; // For optional emails
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeApiService(); // Initialize the ApiService
  }

  // Initialize ApiService and fetch emails
  Future<void> _initializeApiService() async {
    setState(() {
      isLoading = true; // Show loading indicator
    });

    try {
      await widget.apiService.init(); // Call init on the ApiService
      await _fetchAndClassifyEmails(); // Fetch emails after initialization
    } catch (e) {
      print('Error initializing ApiService: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error initializing ApiService: $e')),
      );
    } finally {
      setState(() {
        isLoading = false; // Hide loading indicator
      });
    }
  }

  // Fetch and classify emails
  Future<void> _fetchAndClassifyEmails() async {
    setState(() {
      isLoading = true; // Show loading indicator
    });

    try {
      print('Fetching and classifying emails...');
      final client = await Provider.of<AuthService>(context, listen: false)
          .getAuthClient();

      if (client == null) {
        print('AuthClient is null, cannot fetch emails.');
        return;
      }

      // Fetch emails
      final classifiedMessages =
          await widget.apiService.fetchAndClassifyEmails();

      // Separate messages into priority and optional categories based on classification
      setState(() {
        priorityMessages = classifiedMessages
            .where((message) => message.spamProbability > 0.5)
            .toList();
        optionalMessages = classifiedMessages
            .where((message) => message.spamProbability <= 0.5)
            .toList();
      });

      print(
          'Fetched ${priorityMessages.length} priority messages and ${optionalMessages.length} optional messages.');
    } catch (e) {
      print('Error fetching and classifying emails: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching and classifying emails: $e')),
      );
    } finally {
      setState(() {
        isLoading = false; // Hide loading indicator
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
                  _buildEmailList(
                      priorityMessages, "Priority"), // Priority emails tab
                  _buildEmailList(
                      optionalMessages, "Optional"), // Optional emails tab
                ],
              ),
            ),
          );
  }

  // Helper function to build a list of emails
  Widget _buildEmailList(List<ClassifiedMessage> messages, String category) {
    return messages.isEmpty
        ? Center(child: Text('No $category emails found.'))
        : ListView.builder(
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final classifiedMessage = messages[index];
              final message =
                  classifiedMessage.message; // Access the original message
              return ListTile(
                title: Text(message.snippet ?? 'No Subject'),
                subtitle: Text(
                  message.payload?.headers
                          ?.firstWhere(
                            (header) => header.name == 'From',
                            orElse: () => MessagePartHeader(
                                name: 'From', value: 'No sender'),
                          )
                          .value ??
                      '',
                ),
              );
            },
          );
  }
}
