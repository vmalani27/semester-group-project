import os
import pandas as pd
from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import InstalledAppFlow
from google.auth.transport.requests import Request
from googleapiclient.discovery import build

# Define the scopes for accessing Google Classroom API
SCOPES = [
    'https://www.googleapis.com/auth/classroom.courses.readonly',
    'https://www.googleapis.com/auth/classroom.announcements.readonly',
    'https://www.googleapis.com/auth/classroom.student-submissions.me.readonly'
]

def authenticate_google_services():
    """Authenticate and return the Classroom API service."""
    creds = None
    if os.path.exists('token.json'):
        creds = Credentials.from_authorized_user_file('token.json', SCOPES)
    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            creds.refresh(Request())
        else:
            flow = InstalledAppFlow.from_client_secrets_file('client_secret.json', SCOPES)
            creds = flow.run_local_server(port=0)
        with open('token.json', 'w') as token:
            token.write(creds.to_json())

    # Build the Classroom API service
    classroom_service = build('classroom', 'v1', credentials=creds)
    return classroom_service

def list_courses(service):
    """Fetches a list of courses from Google Classroom."""
    courses = service.courses().list().execute()
    return courses.get('courses', [])

def list_coursework(service, course_id):
    """Fetches coursework (assignments) for a specific course."""
    coursework = service.courses().courseWork().list(courseId=course_id).execute()
    return coursework.get('courseWork', [])

def list_announcements(service, course_id):
    """Fetches announcements for a specific course."""
    announcements = service.courses().announcements().list(courseId=course_id).execute()
    return announcements.get('announcements', [])

def save_data_to_csv(assignments, announcements):
    """Save assignments and announcements to a CSV file."""
    # Combine assignments and announcements into one dataset
    all_data = [{'Sr No': i+1,
                 'Course Name': assignment['courseName'],
                 'Assignment/Announcement': 'Assignment',
                 'Title': assignment['title'],
                 'Date Published': assignment['creationTime'],
                 'Deadline': assignment.get('dueDate', 'No deadline')}
                for i, assignment in enumerate(assignments)]

    all_data += [{'Sr No': len(all_data) + i + 1,
                  'Course Name': announcement['courseName'],
                  'Assignment/Announcement': 'Announcement',
                  'Title': announcement['text'],
                  'Date Published': announcement['creationTime']}
                 for i, announcement in enumerate(announcements)]

    df = pd.DataFrame(all_data)
    df.to_csv('classroom_data.csv', index=False)
    print('Data saved to classroom_data.csv')

if __name__ == '__main__':
    # Authenticate and get the Classroom service
    classroom_service = authenticate_google_services()
    print("Authentication complete")

    # Fetch courses
    print("Fetching courses...")
    courses = list_courses(classroom_service)
    print(f"{len(courses)} courses fetched")

    # Initialize lists for assignments and announcements
    all_assignments = []
    all_announcements = []

    for course_index, course in enumerate(courses, start=1):
        course_id = course['id']
        course_name = course['name']
        print(f"Processing course {course_index}/{len(courses)}: {course_name}")

        # Fetch coursework (assignments)
        coursework = list_coursework(classroom_service, course_id)
        print(f"  {len(coursework)} assignments fetched for {course_name}")

        for work in coursework:
            assignment = {
                'courseName': course_name,
                'title': work['title'],
                'creationTime': work['creationTime'],
                'dueDate': work.get('dueDate', 'No deadline'),
            }
            all_assignments.append(assignment)

        # Fetch announcements
        announcements = list_announcements(classroom_service, course_id)
        print(f"  {len(announcements)} announcements fetched for {course_name}")

        for ann in announcements:
            announcement = {
                'courseName': course_name,
                'text': ann['text'],
                'creationTime': ann['creationTime'],
            }
            all_announcements.append(announcement)

    # Save data to CSV
    save_data_to_csv(all_assignments, all_announcements)
