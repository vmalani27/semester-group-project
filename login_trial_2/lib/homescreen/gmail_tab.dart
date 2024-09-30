import 'package:flutter/material.dart';
import 'package:googleapis/gmail/v1.dart';
import 'package:login_trial_2/auth/firebase/auth_service.dart';
import 'package:login_trial_2/auth/firebase/gmail_service.dart';
import 'package:provider/provider.dart';

class GmailTab extends StatefulWidget {
  final ApiService apiService;

  const GmailTab({super.key, required this.apiService});

  @override
  _GmailTabState createState() => _GmailTabState();
}

class _GmailTabState extends State<GmailTab> {
  List<Message> unreadMessages = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUnreadEmails();
  }

  Future<void> _fetchUnreadEmails() async {
    setState(() {
      isLoading = true; // Show loading indicator
    });

    try {
      print('Fetching unread emails...');
      final client = await Provider.of<AuthService>(context, listen: false)
          .getAuthClient();

      if (client == null) {
        print('AuthClient is null, cannot fetch emails.');
        return;
      }

      final fetchedMessages = await widget.apiService.fetchLast15Emails();
      setState(() {
        unreadMessages = fetchedMessages; // Store fetched messages
      });
      print('Fetched ${fetchedMessages.length} unread messages.');
    } catch (e) {
      print('Error fetching unread emails: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching unread emails: $e')),
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
        : unreadMessages.isEmpty
            ? const Center(child: Text('No unread messages found.'))
            : ListView.builder(
                itemCount: unreadMessages.length,
                itemBuilder: (context, index) {
                  final message = unreadMessages[index];
                  return ListTile(
                    title: Text(message.snippet ?? 'No Subject'),
                    subtitle: Text(message.payload?.headers
                            ?.firstWhere(
                              (header) => header.name == 'From',
                              orElse: () => MessagePartHeader(
                                  name: 'From', value: 'No sender'),
                            )
                            .value ??
                        ''),
                  );
                },
              );
  }
}
