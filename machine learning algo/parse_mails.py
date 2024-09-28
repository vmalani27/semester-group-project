import mailbox
import bs4
import lxml
import pandas as pd
import csv

def get_plain_text(msg):
    """Extract plain text content from a message, handling both text/plain and text/html."""
    try:
        return bs4.BeautifulSoup(msg, 'lxml').get_text(' ', strip=True)
    except Exception as e:
        return str(msg)

class GmailMboxMessage:
    def __init__(self, email_data):
        if not isinstance(email_data, mailbox.mboxMessage):
            raise TypeError('Variable must be type mailbox.mboxMessage')
        self.email_data = email_data

    def parse_email(self):
        email_labels = self.email_data['X-Gmail-Labels']
        email_date = self.email_data['Date']
        email_from = self.email_data['From']
        email_to = self.email_data['To']
        email_subject = self.email_data['Subject']
        email_text = self.read_email_payload()

        # Return the relevant information
        return {
            "from": email_from,
            "to": email_to,
            "subject": email_subject,
            "date": email_date,
            "labels": email_labels,
            "content": email_text
        }

    def read_email_payload(self):
        email_payload = self.email_data.get_payload()
        if self.email_data.is_multipart():
            email_messages = list(self._get_email_messages(email_payload))
        else:
            email_messages = [email_payload]
        return self._extract_text_content(email_messages)

    def _get_email_messages(self, email_payload):
        for msg in email_payload:
            if isinstance(msg, (list, tuple)):
                for submsg in self._get_email_messages(msg):
                    yield submsg
            elif msg.is_multipart():
                for submsg in self._get_email_messages(msg.get_payload()):
                    yield submsg
            else:
                yield msg

    def _extract_text_content(self, email_messages):
        text_content = []
        for msg in email_messages:
            content_type = 'NA' if isinstance(msg, str) else msg.get_content_type()
            if content_type in ('text/plain', 'text/html'):
                msg_text = get_plain_text(msg.get_payload())
                if msg_text:
                    text_content.append(msg_text)
        return ' '.join(text_content).strip()  # Combine all text parts into a single string and strip leading/trailing whitespace

# Specify the path to your mailbox file
mbox_file = 'your_mailbox.mbox'

# Open the mailbox file
mbox_obj = mailbox.mbox(mbox_file)

# Get the number of entries in the mailbox
num_entries = len(mbox_obj)

# List to hold all parsed email data
email_list = []

# Iterate over each email in the mailbox
for idx, email_obj in enumerate(mbox_obj):
    email_data = GmailMboxMessage(email_obj)
    parsed_email = email_data.parse_email()

    # Add parsed email data to list
    email_list.append(parsed_email)

    # Print email data to console
    print(f"Email {idx + 1} of {num_entries}")
    print("From:", parsed_email['from'])
    print("To:", parsed_email['to'])
    print("Subject:", parsed_email['subject'])
    print("Date:", parsed_email['date'])
    print("Labels:", parsed_email['labels'])
    print("Content:", parsed_email['content'])
    print("-" * 80)  # Print a separator line

# Create DataFrame from list of emails
email_df = pd.DataFrame(email_list)

# Clean DataFrame: Remove any newline or excessive whitespace
email_df.replace('\n', ' ', regex=True, inplace=True)
email_df.replace('\r', ' ', regex=True, inplace=True)

# Export DataFrame to CSV file using Python's CSV quoting
email_df.to_csv('emails.csv', index=False, encoding='utf-8', quoting=csv.QUOTE_MINIMAL)

print('Email data exported to emails.csv')
