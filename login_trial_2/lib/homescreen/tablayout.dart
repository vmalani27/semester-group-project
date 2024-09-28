import 'package:flutter/material.dart';
import 'package:googleapis_auth/src/auth_client.dart';
import 'package:login_trial_2/auth/firebase/api_service.dart';
import 'package:login_trial_2/auth/firebase/auth_service.dart';
import 'package:login_trial_2/homescreen/classroom_tab.dart';
import 'package:login_trial_2/homescreen/gmail_tab.dart';
import 'package:login_trial_2/homescreen/whatsapp_tab.dart';
import 'package:login_trial_2/homescreen/useraccountpage.dart'; // Import UserAccountPage
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
    final apiService =
        ApiService(authService.getAuthClient()); // Ensure you have this method

    return Scaffold(
      appBar: AppBar(
        title: Text("Home Screen"),
        actions: [
          IconButton(
            icon: Icon(Icons.account_circle),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => UserAccountPage()),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: "Gmail"),
            Tab(text: "WhatsApp"),
            Tab(text: "Classroom"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          GmailTab(apiService: apiService), // Pass the ApiService instance
          WhatsAppTab(),
          ClassroomTab(),
        ],
      ),
    );
  }
}
