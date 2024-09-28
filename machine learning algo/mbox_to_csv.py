import mailbox
import csv

def mbox_to_csv(mbox_file, csv_file):
    # Open the mbox file
    mbox = mailbox.mbox(mbox_file)

    # Define the headers for the CSV file
    fieldnames = ['subject', 'from', 'to', 'date', 'body']

    # Open the CSV file for writing
    with open(csv_file, 'w', newline='', encoding='utf-8') as csvfile:
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
        writer.writeheader()

        # Iterate through each message in the mbox file
        for message in mbox:
            # Extract the necessary fields from the email
            subject = message['subject']
            sender = message['from']
            recipient = message['to']
            date = message['date']
            body = message.get_payload(decode=True)

            # Convert body from bytes to string if necessary
            if isinstance(body, bytes):
                body = body.decode('utf-8', errors='replace')

            # Write the extracted fields to the CSV file
            writer.writerow({
                'subject': subject,
                'from': sender,
                'to': recipient,
                'date': date,
                'body': body
            })

# Replace 'your_mbox_file.mbox' and 'output.csv' with your actual file names
mbox_file = 'your_mailbox.mbox'
csv_file = 'output.csv'

mbox_to_csv(mbox_file, csv_file)
