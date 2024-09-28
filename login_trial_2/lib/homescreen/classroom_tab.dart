import 'package:flutter/material.dart';
import 'package:googleapis/classroom/v1.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';
import 'package:login_trial_2/auth/firebase/class_service.dart'; // Your ClassService
import 'package:login_trial_2/auth/firebase/auth_service.dart'; // GoogleAccountService

class ClassroomTab extends StatefulWidget {
  @override
  _ClassroomTabState createState() => _ClassroomTabState();
}

class _ClassroomTabState extends State<ClassroomTab> {
  List<Announcement> classroomAnnouncements = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchClassroomAnnouncements();
  }

  // Fetch classroom announcements with teacher names
  Future<void> _fetchClassroomAnnouncements() async {
    try {
      print('Fetching classroom announcements...');

      // Access the Google account service and refresh the token if needed
      final googleAccountService =
          Provider.of<AuthService>(context, listen: false);
      await googleAccountService.refreshTokenIfNeeded(context);

      // Create an authenticated client using the Google Account's token
      final authClient = authenticatedClient(
        Client(),
        AccessCredentials(
          AccessToken('Bearer', googleAccountService.accessToken!,
              googleAccountService.accessTokenExpiry!),
          null,
          [
            'https://www.googleapis.com/auth/classroom.announcements.readonly',
            'https://www.googleapis.com/auth/classroom.courses.readonly',
            'https://www.googleapis.com/auth/classroom.profile.emails',
            'https://www.googleapis.com/auth/classroom.profile.photos',
            'https://www.googleapis.com/auth/classroom.rosters',
            'https://www.googleapis.com/auth/classroom.rosters.readonly',
            'https://www.googleapis.com/auth/classroom.profile.emails',
            'https://www.googleapis.com/auth/classroom.profile.photos',
            'https://www.googleapis.com/auth/homeroom'
          ],
        ),
      );

      // Initialize ClassService to interact with Google Classroom API
      ClassService apiService = ClassService(ClassroomApi(authClient));

      // Fetch all course announcements
      List<Announcement> announcements =
          await apiService.fetchAllCourseAnnouncements();

      // Fetch teacher profiles for each announcement's creatorUserId
      List<Announcement> announcementsWithTeacherNames = [];
      for (var announcement in announcements) {
        // Fetch user profile based on creatorUserId
        final userProfile =
            await apiService.fetchUserProfile(announcement.creatorUserId!);
        announcement.creatorUserId = userProfile?.name?.fullName ??
            'Unknown Teacher'; // Replace with full name
        announcementsWithTeacherNames.add(announcement); // Add to list
      }

      setState(() {
        classroomAnnouncements = announcementsWithTeacherNames;
        isLoading = false;
      });

      print('Fetched ${classroomAnnouncements.length} announcements.');
    } catch (e) {
      print('Error fetching announcements: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? Center(child: CircularProgressIndicator())
        : classroomAnnouncements.isEmpty
            ? Center(child: Text('No announcements found.'))
            : ListView.builder(
                itemCount: classroomAnnouncements.length,
                itemBuilder: (context, index) {
                  final announcement = classroomAnnouncements[index];
                  return _buildAnnouncementCard(announcement);
                },
              );
  }

  // Build a card widget for each announcement
  Widget _buildAnnouncementCard(Announcement announcement) {
    final teacherName = announcement.creatorUserId ??
        'Unknown Teacher'; // Display teacher's full name
    final announcementText =
        announcement.text ?? 'No Content'; // Show announcement text
    final courseTitle =
        announcement.courseId ?? 'Unknown Course'; // Show course name

    return Card(
      margin: EdgeInsets.all(10),
      color: _generateCourseColor(courseTitle), // Unique color for each course
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Course: $courseTitle',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            SizedBox(height: 6),
            Text(
              'Teacher: $teacherName',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 6),
            Text(
              'Announcement: $announcementText',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  // Function to generate a unique color for each course based on its ID
  Color _generateCourseColor(String courseId) {
    int hash = courseId.hashCode;
    return Color((hash & 0xFFFFFF) | 0xFF000000); // Ensure it's a valid color
  }
}
