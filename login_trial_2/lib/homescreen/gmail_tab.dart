import 'package:flutter/material.dart';
import 'package:googleapis/gmail/v1.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart';
import 'package:login_trial_2/auth/firebase/api_service.dart';
import 'package:login_trial_2/auth/firebase/auth_service.dart';
import 'package:provider/provider.dart';

class GmailTab extends StatefulWidget {
  final ApiService apiService; // Add ApiService instance

  GmailTab({required this.apiService}); // Update constructor

  @override
  _GmailTabState createState() => _GmailTabState();
}

class _GmailTabState extends State<GmailTab> {
  List<Message> unreadMessages = [];
  bool isLoading = true;
  bool isFetchingMore = false;
  String? nextPageToken;

  @override
  void initState() {
    super.initState();
    _fetchUnreadEmails();
  }

  Future<void> _fetchUnreadEmails({String? pageToken}) async {
    if (isLoading || isFetchingMore) return;

    if (pageToken != null) {
      setState(() {
        isFetchingMore = true;
      });
    } else {
      setState(() {
        isLoading = true;
      });
    }

    try {
      print('Fetching unread emails...');

      // Use the passed apiService instance to fetch emails
      final fetchedMessages =
          await widget.apiService.fetchUserEmails(nextPageToken: pageToken);

      setState(() {
        unreadMessages.addAll(fetchedMessages);
        nextPageToken =
            fetchedMessages.isNotEmpty ? fetchedMessages.last.id : null;
      });

      print('Fetched ${fetchedMessages.length} unread messages.');
    } catch (e) {
      print('Error fetching unread emails: $e');
    } finally {
      setState(() {
        isLoading = false;
        isFetchingMore = false;
        print('Loading completed.');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    print('Building GmailTab widget...');
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (!isLoading &&
            !isFetchingMore &&
            scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent &&
            nextPageToken != null) {
          _fetchUnreadEmails(pageToken: nextPageToken);
        }
        return true;
      },
      child: isLoading && unreadMessages.isEmpty
          ? Center(child: CircularProgressIndicator())
          : unreadMessages.isEmpty
              ? Center(child: Text('No unread messages found.'))
              : ListView.builder(
                  itemCount: unreadMessages.length + (isFetchingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == unreadMessages.length) {
                      return Center(child: CircularProgressIndicator());
                    }
                    final message = unreadMessages[index];
                    return ListTile(
                      title: Text(message.snippet ?? 'No Subject'),
                      subtitle: Text(message.payload?.headers
                              ?.firstWhere((header) => header.name == 'From')
                              .value ??
                          ''),
                    );
                  },
                ),
    );
  }
}
