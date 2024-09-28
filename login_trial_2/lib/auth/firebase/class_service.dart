import 'package:googleapis/classroom/v1.dart';

class ClassService {
  final ClassroomApi _classroomApi;

  ClassService(this._classroomApi);

  // Fetch announcements for all courses
  Future<List<Announcement>> fetchAllCourseAnnouncements() async {
    List<Announcement> allAnnouncements = [];

    try {
      // Fetch all courses the user is enrolled in
      var coursesResponse = await _classroomApi.courses.list();
      if (coursesResponse.courses != null &&
          coursesResponse.courses!.isNotEmpty) {
        print(
            'Found ${coursesResponse.courses!.length} courses.'); // Debug line

        // Loop through each course to fetch its announcements
        for (var course in coursesResponse.courses!) {
          var courseId = course.id!;
          var courseName = course.name ?? 'Unnamed Course';
          print(
              'Fetching announcements for course: $courseName (ID: $courseId)');

          // Fetch announcements for this specific course
          var announcementsResponse =
              await _classroomApi.courses.announcements.list(courseId);
          if (announcementsResponse.announcements != null &&
              announcementsResponse.announcements!.isNotEmpty) {
            print(
                'Found ${announcementsResponse.announcements!.length} announcements in $courseName.');

            // Loop through announcements and fetch teacher names
            for (var announcement in announcementsResponse.announcements!) {
              // Fetch the user profile for the creatorUserId (teacher)
              var teacherProfile =
                  await fetchUserProfile(announcement.creatorUserId!);
              String teacherName =
                  teacherProfile?.name?.fullName ?? 'Unknown Teacher';

              // Tag the course name and teacher name for UI
              announcement.courseId = courseName;
              announcement.creatorUserId = teacherName;

              // Add announcement to the list
              allAnnouncements.add(announcement);
            }
          } else {
            print('No announcements found for course: $courseName');
          }
        }
      } else {
        print('No courses found.');
      }
    } catch (e) {
      print('Error fetching announcements: $e');
    }

    return allAnnouncements;
  }

  // Fetch user profile to get teacher name
  Future<UserProfile?> fetchUserProfile(String userId) async {
    try {
      // Fetch user profile by userId
      var userProfile = await _classroomApi.userProfiles.get(userId);
      return userProfile;
    } catch (e) {
      print('Error fetching user profile for userId $userId: $e');
      return null;
    }
  }
}
