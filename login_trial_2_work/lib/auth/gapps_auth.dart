import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

class GmailAuthScreen extends StatefulWidget {
  @override
  _GmailAuthScreenState createState() => _GmailAuthScreenState();
}

class _GmailAuthScreenState extends State<GmailAuthScreen> {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'https://www.googleapis.com/auth/gmail.readonly',
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Authorize Gmail Access')),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            try {
              final GoogleSignInAccount? account = await _googleSignIn.signIn();
              if (account != null) {
                final GoogleSignInAuthentication auth =
                    await account.authentication;
                final String? token = auth.accessToken;

                // Use this token to make authorized API requests to Gmail
                final response = await http.get(
                  Uri.parse(
                      'https://www.googleapis.com/gmail/v1/users/me/messages'),
                  headers: {
                    'Authorization': 'Bearer $token',
                  },
                );

                // Process the Gmail data
                print(response.body);

                // Navigate to the home screen or wherever you want to go next
                Navigator.pushReplacementNamed(context, '/home');
              }
            } catch (error) {
              print('Error during sign-in: $error');
            }
          },
          child: Text('Authorize Gmail Access'),
        ),
      ),
    );
  }
}
