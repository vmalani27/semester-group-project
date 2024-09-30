from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import InstalledAppFlow
from google.auth.transport.requests import Request
from googleapiclient.discovery import build
import os

# Define the scopes
SCOPES = ['https://www.googleapis.com/auth/classroom.courses.readonly',
          'https://www.googleapis.com/auth/classroom.student-submissions.me.readonly',
          'https://www.googleapis.com/auth/classroom.announcements.readonly']

def authenticate_google_classroom():
    """Authenticate and return the Classroom API service"""
    creds = None
    # Load saved credentials, if they exist
    if os.path.exists('token.json'):
        creds = Credentials.from_authorized_user_file('token.json', SCOPES)
    # If there are no valid credentials, authenticate
    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            creds.refresh(Request())
        else:
            # Use client_secret.json (or credentials.json)
            flow = InstalledAppFlow.from_client_secrets_file('client_secret.json', SCOPES)
            creds = flow.run_local_server(port=0)
        # Save the credentials for next time
        with open('token.json', 'w') as token:
            token.write(creds.to_json())
    
    service = build('classroom', 'v1', credentials=creds)
    return service

# Authenticate and create service
service = authenticate_google_classroom()

# Now you can use the 'service' to interact with the Classroom API
