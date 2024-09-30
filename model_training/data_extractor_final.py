import os
import re
import pandas as pd
from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import InstalledAppFlow
from google.auth.transport.requests import Request
from googleapiclient.discovery import build

# Define the scopes for accessing Gmail and Google Classroom APIs
GMAIL_SCOPES = ['https://www.googleapis.com/auth/gmail.readonly']
CLASSROOM_SCOPES = ['https://www.googleapis.com/auth/classroom.courses.readonly',
                    'https://www.googleapis.com/auth/classroom.announcements.readonly',
                    'https://www.googleapis.com/auth/classroom.student-submissions.me.readonly']

def authenticate_gmail():
    """Authenticate and return the Gmail API service"""
    creds = None
    if os.path.exists('gmail_token.json'):
        creds = Credentials.from_authorized_user_file('gmail_token.json', GMAIL_SCOPES)
    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            creds.refresh(Request())
        else:
            flow = InstalledAppFlow.from_client_secrets_file('client_secret.json', GMAIL_SCOPES)
            creds = flow.run_local_server(port=0)
        with open('gmail_token.json', 'w') as token:
            token.write(creds.to_json())
    
    # Build the Gmail API service
    return build('gmail', 'v1', credentials=creds)

def authenticate_google_classroom():
    """Authenticate and return the Classroom API service"""
    creds = None
    if os.path.exists('classroom_token.json'):
        creds = Credentials.from_authorized_user_file('classroom_token.json', CLASSROOM_SCOPES)
    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            creds.refresh(Request())
        else:
            flow = InstalledAppFlow.from_client_secrets_file('client_secret.json', CLASSROOM_SCOPES)
            creds = flow.run_local_server(port=0)
        with open('classroom_token.json', 'w') as token:
            token.write(creds.to_json())
    
    # Build the Classroom API service
    return build('classroom', 'v1', credentials=creds)

def list_courses(service):
    """Fetches a list of courses from Google Classroom"""
    courses = service.courses().list().execute()
    return courses.get('courses', [])

def list_announcements(service, course_id):
    """Fetches announcements for a specific course"""
    announcements = service.courses().announcements().list(courseId=course_id).execute()
    return announcements.get('announcements', [])

def list_coursework(service, course_id):
    """Fetches coursework (assignments) for a specific course"""
    coursework = service.courses().courseWork().list(courseId=course_id).execute()
    return coursework.get('courseWork', [])

def get_gmail_messages(service):
    """Fetch Gmail messages from Google Classroom"""
    query = 'from:googleclassroom@google.com'
    result = service.users().messages().list(userId='me', q=query).execute()
    messages = result.get('messages', [])
    return messages
def get_email_details(service, msg_id):
    """Fetch the details of a specific email"""
    msg = service.users().messages().get(userId='me', id=msg_id).execute()
    payload = msg['payload']
    
    # Extract the subject and sender
    headers = payload['headers']
    subject = next(header['value'] for header in headers if header['name'] == 'Subject')
    sender = next(header['value'] for header in headers if header['name'] == 'From')

    # Extract the email body
    if 'parts' in payload:
        body = ''.join(part['body']['data'] for part in payload['parts'] if 'data' in part['body'])
    else:
        body = payload['body']['data']
    
    return {
        'subject': subject,
        'sender': sender,
        'body': body
    }

def cross_reference_assignments_announcements(courses, announcements, coursework, email_details):
    """Cross-reference assignments and announcements with email details"""
    assignments_with_assignee = []
    announcements_with_assignee = []

    # Create a dictionary for easy access to email information
    email_map = {email['subject']: email for email in email_details}
    
    # Debugging: Print out email subjects and senders
    print("Fetched Email Details:")
    for email in email_details:
        print(f"Subject: {email['subject']}, Sender: {email['sender']}")

    for course in courses:
        course_name = course['name']
        course_id = course['id']

        # Process assignments
        for work in coursework.get(course_id, []):
            title = work['title']
            print(f"Processing Assignment: {title}")  # Debugging line
            assignee = email_map.get(title, {}).get('sender', 'Unknown')  # Use email sender as assignee
            print(f"Assigned Email: {assignee}")  # Debugging line
            assignment_info = {
                'Course Name': course_name,
                'Assignment Title': title,
                'Assignee': assignee
            }
            assignments_with_assignee.append(assignment_info)

        # Process announcements
        for ann in announcements.get(course_id, []):
            text = ann['text']
            print(f"Processing Announcement: {text}")  # Debugging line
            assignee = email_map.get(text, {}).get('sender', 'Unknown')  # Use email sender as assignee
            print(f"Assigned Email: {assignee}")  # Debugging line
            announcement_info = {
                'Course Name': course_name,
                'Announcement': text,
                'Assignee': assignee
            }
            announcements_with_assignee.append(announcement_info)

    return assignments_with_assignee, announcements_with_assignee


def save_to_csv(data, filename):
    """Save data to a CSV file"""
    df = pd.DataFrame(data)
    df.to_csv(filename, index=False)
    print(f'Data saved to {filename}')

# Main logic
if __name__ == '__main__':
    # Authenticate and get services
    gmail_service = authenticate_gmail()
    classroom_service = authenticate_google_classroom()
    
    print("Authenticated successfully.")
    
    # Fetch courses and their announcements and coursework
    courses = list_courses(classroom_service)
    announcements = {course['id']: list_announcements(classroom_service, course['id']) for course in courses}
    coursework = {course['id']: list_coursework(classroom_service, course['id']) for course in courses}
    
    print("Courses, announcements, and coursework fetched.")
    
    # Fetch Gmail messages
    gmail_messages = get_gmail_messages(gmail_service)
    email_details = [get_email_details(gmail_service, msg['id']) for msg in gmail_messages]

    print(f"Fetched {len(email_details)} emails from Google Classroom.")
    
    # Cross-reference assignments and announcements
    assignments_with_assignee, announcements_with_assignee = cross_reference_assignments_announcements(courses, announcements, coursework, email_details)

    # Save results to CSV
    save_to_csv(assignments_with_assignee, 'assignments_with_assignees.csv')
    save_to_csv(announcements_with_assignee, 'announcements_with_assignees.csv')

    print("Cross-referencing complete and results saved.")
