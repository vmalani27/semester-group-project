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

            // Loop through announcements and tag the course name for UI
            for (var announcement in announcementsResponse.announcements!) {
              // Tag the course name for UI
              announcement.courseId = courseName;

              // Add announcement to the list
              allAnnouncements.add(announcement);
            }
          } else {
            print('No announcements found for course: $courseName');
          }
        }

        // Sort announcements by creation time (latest first)
        allAnnouncements.sort((a, b) {
          var aTime = a.creationTime != null
              ? DateTime.parse(a.creationTime!)
              : DateTime(0);
          var bTime = b.creationTime != null
              ? DateTime.parse(b.creationTime!)
              : DateTime(0);
          return bTime.compareTo(aTime); // Sort in descending order
        });
      } else {
        print('No courses found.');
      }
    } catch (e) {
      print('Error fetching announcements: $e');
    }

    return allAnnouncements;
  }
}
