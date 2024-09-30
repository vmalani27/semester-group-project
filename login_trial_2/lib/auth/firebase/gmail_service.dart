import 'package:googleapis/gmail/v1.dart';
import 'package:googleapis_auth/auth_io.dart';

class ApiService {
  final AuthClient authClient;

  ApiService(this.authClient);

  // Fetch the last 15 user emails using Gmail API
  Future<List<Message>> fetchLast15Emails() async {
    List<Message> messagesList = [];
    try {
      print(
          'Starting to fetch last 15 emails...'); // Print statement to indicate the function has been called
      final gmailApi = GmailApi(authClient);

      // Fetch the last 15 message IDs
      var messagesResponse = await gmailApi.users.messages.list(
        'me',
        maxResults: 15, // Set maxResults to 15
      );
      print(
          'Fetched message response: ${messagesResponse.messages?.length ?? 0} messages found.'); // Print the number of messages fetched

      // Check if we have messages
      if (messagesResponse.messages != null &&
          messagesResponse.messages!.isNotEmpty) {
        // Fetch each message using its ID
        for (var messageInfo in messagesResponse.messages!) {
          print(
              'Fetching message with ID: ${messageInfo.id}'); // Print the message ID being fetched
          var message =
              await gmailApi.users.messages.get('me', messageInfo.id!);
          messagesList.add(message);
          print(
              'Fetched message: ${message.id}'); // Print confirmation of message fetched
        }
      } else {
        print('No emails found.'); // Print when no messages are found
      }
    } catch (e) {
      print('Error fetching emails: $e'); // Print error message
    }

    print(
        'Finished fetching emails. Total emails fetched: ${messagesList.length}'); // Print total emails fetched at the end
    return messagesList;
  }
}
