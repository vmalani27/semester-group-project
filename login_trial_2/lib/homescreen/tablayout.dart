import 'package:flutter/material.dart';
import 'package:googleapis_auth/src/auth_client.dart';
import 'package:login_trial_2/auth/firebase/gmail_service.dart';
import 'package:login_trial_2/auth/firebase/auth_service.dart';
import 'package:login_trial_2/homescreen/classroom_tab.dart';
import 'package:login_trial_2/homescreen/gmail_tab.dart';
import 'package:login_trial_2/homescreen/useraccountpage.dart'; // Import UserAccountPage
import 'package:login_trial_2/homescreen/gemini_tab.dart'; // Import GeminiTab
import 'package:provider/provider.dart';
import 'package:login_trial_2/auth/firebase/gemini_service.dart'; // Import GeminiSummaryService

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late GeminiSummaryService geminiService; // Declare the GeminiSummaryService

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Home Screen"),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const UserAccountPage()),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Gmail"),
            Tab(text: "Gemini"),
            Tab(text: "Classroom"),
          ],
        ),
      ),
      body: FutureBuilder<AuthClient?>(
        future: authService.getAuthClient(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Unable to authenticate'));
          } else {
            final apiService =
                ApiService(snapshot.data!); // AuthClient is ready

            // Initialize the GeminiSummaryService with the apiService
            geminiService =
                GeminiSummaryService('YOUR_API_KEY_HERE', apiService);
            geminiService.init(); // Call init to set up the service

            return TabBarView(
              controller: _tabController,
              children: [
                GmailTab(apiService: apiService), // Pass ApiService instance
                GeminiTab(
                    geminiService:
                        geminiService), // Pass the initialized geminiService
                ClassroomTab(),
              ],
            );
          }
        },
      ),
    );
  }
}
