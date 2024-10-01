import 'dart:convert'; // For decoding email content
import 'package:googleapis/gmail/v1.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http; // Import HTTP package for API calls

class ClassifiedMessage {
  final Message message;
  final double spamProbability;

  ClassifiedMessage({required this.message, required this.spamProbability});
}

class ApiService {
  late final AuthClient authClient;
  bool isInitialized = false; // Track initialization status

  ApiService(this.authClient);

  // Initialize the ApiService
  Future<void> init() async {
    try {
      isInitialized = true; // Set initialized flag
    } catch (e) {
      print('Error during initialization: $e');
    }
  }

  // Fetch the last 30 user emails using Gmail API and classify them
  Future<List<ClassifiedMessage>> fetchAndClassifyEmails() async {
    if (!isInitialized) {
      print('ApiService not initialized. Please call init() first.');
      return []; // Early exit if not initialized
    }

    List<ClassifiedMessage> classifiedMessages = [];
    try {
      print('Starting to fetch last 30 emails...');
      final gmailApi = GmailApi(authClient);

      // Fetch the last 30 message IDs
      var messagesResponse = await gmailApi.users.messages.list(
        'me',
        maxResults: 30, // Set maxResults to 30
      );
      print(
          'Fetched message response: ${messagesResponse.messages?.length ?? 0} messages found.');

      // Check if we have messages
      if (messagesResponse.messages != null &&
          messagesResponse.messages!.isNotEmpty) {
        // Fetch each message using its ID and classify
        for (var messageInfo in messagesResponse.messages!) {
          print('Fetching message with ID: ${messageInfo.id}');
          var message =
              await gmailApi.users.messages.get('me', messageInfo.id!);

          // Ensure email content extraction and classification is wrapped in try-catch
          try {
            String emailContent = _extractEmailContent(message);
            print('Email Content: $emailContent');

            double prediction = await classifyEmail(emailContent);
            print('Spam Probability for Email ID ${message.id}: $prediction');

            // Create a ClassifiedMessage object with the message and spam probability
            classifiedMessages.add(ClassifiedMessage(
              message: message,
              spamProbability: prediction,
            ));
          } catch (e) {
            print('Error processing message ID ${messageInfo.id}: $e');
          }
        }
      } else {
        print('No emails found.');
      }
    } catch (e) {
      print('Error fetching emails: $e');
    }
    print('Finished fetching emails.');
    return classifiedMessages; // Return the list of classified messages
  }

  // Extract the email content from Gmail message
  String _extractEmailContent(Message message) {
    if (message.payload != null) {
      if (message.payload!.body?.data != null) {
        // Direct body data if it's present
        return utf8.decode(base64Url.decode(message.payload!.body!.data!));
      } else if (message.payload!.parts != null) {
        // Multipart message, extract parts
        for (var part in message.payload!.parts!) {
          if (part.body?.data != null) {
            return utf8.decode(base64Url.decode(part.body!.data!));
          }
        }
      }
    }
    return ''; // Return empty string if no content found
  }

  // Classify the email content by sending it to the Flask API
  Future<double> classifyEmail(String emailContent) async {
    try {
      final url = Uri.parse('http://127.0.0.1:5000/predict');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'content': emailContent}),
      );

      if (response.statusCode == 200) {
        final prediction = json.decode(response.body);
        return prediction['spam_probability'] ??
            0.0; // Adjust based on your Flask response
      } else {
        print('Failed to classify email. Status code: ${response.statusCode}');
        return 0.0; // Default probability
      }
    } catch (e) {
      print('Error during classification for email: $emailContent. Error: $e');
      return 0.0; // Default probability in case of error
    }
  }
}
