import os
import pandas as pd
from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import InstalledAppFlow
from google.auth.transport.requests import Request
from googleapiclient.discovery import build

# Define the scopes for accessing Google Classroom and Gmail APIs
SCOPES = [
    'https://www.googleapis.com/auth/classroom.courses.readonly',
    'https://www.googleapis.com/auth/classroom.student-submissions.me.readonly',
    'https://www.googleapis.com/auth/classroom.announcements.readonly',
    'https://www.googleapis.com/auth/gmail.readonly'
]

def authenticate_google_services():
    """Authenticate and return the Classroom and Gmail API services"""
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
    # Build the Gmail API service
    gmail_service = build('gmail', 'v1', credentials=creds)
    return classroom_service, gmail_service

def list_courses(service):
    """Fetches a list of courses from Google Classroom"""
    courses = service.courses().list().execute()
    return courses.get('courses', [])

def list_coursework(service, course_id):
    """Fetches coursework (assignments) for a specific course"""
    coursework = service.courses().courseWork().list(courseId=course_id).execute()
    return coursework.get('courseWork', [])

def list_announcements(service, course_id):
    """Fetches announcements for a specific course"""
    announcements = service.courses().announcements().list(courseId=course_id).execute()
    return announcements.get('announcements', [])

def save_assignments_to_csv(assignments):
    """Save the assignments to a CSV file"""
    assignment_data = [{'Sr No': i+1,
                        'Course Name': assignment['courseName'],
                        'Assignment': assignment['title'],
                        'Date Published': assignment['creationTime'],
                        'Deadline': assignment.get('dueDate', 'No deadline')}
                       for i, assignment in enumerate(assignments)]
    df = pd.DataFrame(assignment_data)
    df.to_csv('assignments.csv', index=False)
    print('Assignments saved to assignments.csv')

def save_announcements_to_csv(announcements):
    """Save the announcements to a CSV file"""
    announcement_data = [{'Sr No': i+1,
                          'Course Name': announcement['courseName'],
                          'Announcement': announcement['text'],
                          'Date Published': announcement['creationTime']}
                         for i, announcement in enumerate(announcements)]
    df = pd.DataFrame(announcement_data)
    df.to_csv('announcements.csv', index=False)
    print('Announcements saved to announcements.csv')

def fetch_gmail_messages(service):
    """Fetches the latest Gmail messages"""
    results = service.users().messages().list(userId='me', maxResults=10).execute()
    messages = results.get('messages', [])
    
    email_data = []
    for message in messages:
        msg = service.users().messages().get(userId='me', id=message['id']).execute()
        email_data.append({
            'id': message['id'],
            'snippet': msg['snippet'],
            'subject': msg['payload']['headers'][0]['value'] if 'headers' in msg['payload'] else 'No subject'
        })
    
    return email_data

# Main logic: Authenticate, fetch data, and save to CSV
if __name__ == '__main__':
    # Authenticate and get the Classroom and Gmail services
    classroom_service, gmail_service = authenticate_google_services()
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

    # Save assignments and announcements to CSV
    save_assignments_to_csv(all_assignments)
    save_announcements_to_csv(all_announcements)

    # Fetch Gmail messages
    print("Fetching Gmail messages...")
    gmail_messages = fetch_gmail_messages(gmail_service)
    print("Gmail messages fetched:")
    for message in gmail_messages:
        print(f"Subject: {message['subject']}, Snippet: {message['snippet']}")
