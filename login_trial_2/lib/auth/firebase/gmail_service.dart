import 'dart:convert'; // For decoding email content
import 'package:googleapis/gmail/v1.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http; // Import HTTP package for API calls
import 'dart:async'; // For TimeoutException handling

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
      print('ApiService initialized successfully.');
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
      print('Starting to fetch the last 30 emails...');
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
            if (emailContent.isEmpty) {
              print('No content found for message ID: ${messageInfo.id}');
              continue; // Skip this message if no content
            }
            print('Email Content: $emailContent');

            double prediction = await classifyEmail(emailContent);
            print('Spam Probability for Email ID ${message.id}: $prediction');

            // Use the prediction to categorize the email
            // Assuming 1 is for spam (priority) and 0 is for optional
            String category = (prediction >= 0.5) ? 'Priority' : 'Optional';
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
    try {
      if (message.payload != null) {
        // If body is directly available
        if (message.payload!.body?.data != null) {
          print('Extracting body content from email.');
          return utf8.decode(base64Url.decode(message.payload!.body!.data!));
        }

        // If the message is multipart, handle the parts
        if (message.payload!.parts != null) {
          print('Multipart email detected. Extracting content from parts.');
          for (var part in message.payload!.parts!) {
            // Check if it's a text part and has data
            if (part.mimeType == 'text/plain' && part.body?.data != null) {
              return utf8.decode(base64Url.decode(part.body!.data!));
            }
          }
        }
      }
      print('No content found for the email.');
      return ''; // Return empty string if no content is found
    } catch (e) {
      print('Error extracting email content: $e');
      return ''; // Return empty string on error
    }
  }

  // Classify the email content by sending it to the Flask API
  Future<double> classifyEmail(String emailContent) async {
    try {
      print('Sending email content to Flask API for classification.');
      final url = Uri.parse('http://172.22.176.87:5000/predict');
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'email_content': emailContent}),
          )
          .timeout(Duration(seconds: 10)); // Set a 10-second timeout

      if (response.statusCode == 200) {
        print('Classification successful, parsing response.');
        final prediction = json.decode(response.body);
        print('Prediction response: $prediction'); // Debugging line

        // Access the first element of the nested prediction list
        if (prediction['prediction'] is List &&
            prediction['prediction'].isNotEmpty) {
          var nestedPrediction =
              prediction['prediction'][0]; // Get the first list
          if (nestedPrediction is List && nestedPrediction.isNotEmpty) {
            // Access the first element of the nested list
            double spamPrediction = (nestedPrediction[0] as num).toDouble();
            return spamPrediction; // Return the spam prediction
          } else {
            print('Unexpected format in nested prediction: $nestedPrediction');
            return 0.0; // Default probability if nested format is unexpected
          }
        } else {
          print('Unexpected prediction format: ${prediction['prediction']}');
          return 0.0; // Default probability in case of unexpected format
        }
      } else {
        print(
            'Failed to classify email. Status code: ${response.statusCode}. Response: ${response.body}');
        return 0.0; // Default probability if response isn't successful
      }
    } on TimeoutException catch (e) {
      print('Request to Flask API timed out: $e');
      return 0.0; // Default probability on timeout
    } catch (e) {
      print('Error during classification: $e');
      return 0.0; // Default probability in case of error
    }
  }
}
