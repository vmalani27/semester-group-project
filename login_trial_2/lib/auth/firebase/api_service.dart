import 'package:googleapis/classroom/v1.dart';
import 'package:googleapis/gmail/v1.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart';

class ApiService {
  final AuthClient authClient;

  ApiService(this.authClient);

  // Fetch user emails using Gmail API
  Future<List<Message>> fetchUserEmails(
      {String? nextPageToken, int maxResults = 10}) async {
    List<Message> messagesList = [];
    try {
      final gmailApi = GmailApi(authClient);

      var messagesResponse = await gmailApi.users.messages.list(
        'me',
        maxResults: maxResults,
        pageToken: nextPageToken,
      );

      if (messagesResponse.messages != null &&
          messagesResponse.messages!.isNotEmpty) {
        for (var messageInfo in messagesResponse.messages!) {
          var message =
              await gmailApi.users.messages.get('me', messageInfo.id!);
          messagesList.add(message);
        }
      } else {
        print('No emails found.');
      }

      return messagesList;
    } catch (e) {
      print('Error fetching emails: $e');
      return messagesList;
    }
  }

  // Fetch user courses using Classroom API
  Future<void> fetchUserCourses() async {
    try {
      final classroomApi = ClassroomApi(authClient);
      var coursesResponse = await classroomApi.courses.list();
      if (coursesResponse.courses != null &&
          coursesResponse.courses!.isNotEmpty) {
        for (var course in coursesResponse.courses!) {
          print('Course: ${course.name}');

          // Fetch announcements for the course
          var announcementsResponse = await classroomApi.courses.announcements
              .list(course.id!, pageSize: 5); // Fetch up to 5 announcements

          if (announcementsResponse.announcements != null &&
              announcementsResponse.announcements!.isNotEmpty) {
            for (var announcement in announcementsResponse.announcements!) {
              print('Announcement: ${announcement.text}');
            }
          } else {
            print('No announcements found for course: ${course.name}');
          }
        }
      } else {
        print('No courses found.');
      }
    } catch (e) {
      print('Error fetching courses or announcements: $e');
    }
  }

  // Fetch user profile using Classroom API (for teacher or student names)
  Future<UserProfile?> fetchUserProfile(String userId) async {
    try {
      final classroomApi = ClassroomApi(authClient);
      var userProfile = await classroomApi.userProfiles.get(userId);
      return userProfile;
    } catch (e) {
      print('Error fetching user profile: $e');
      return null;
    }
  }
}
