import cv2
import pytesseract
import pandas as pd
from PIL import Image

# Path to the tesseract executable
pytesseract.pytesseract.tesseract_cmd = r'C:\Program Files\Tesseract-OCR\tesseract.exe'  # Update this path

def preprocess_image(image_path):
    # Load the image using OpenCV
    image = cv2.imread(image_path)
    
    # Rotate the image if necessary
    # image = cv2.rotate(image, cv2.ROTATE_90_CLOCKWISE)

    # Convert image to grayscale
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)

    # Apply thresholding
    _, thresh = cv2.threshold(gray, 150, 255, cv2.THRESH_BINARY_INV)

    # Return the preprocessed image
    return thresh

def extract_text_from_image(image_path):
    # Preprocess the image
    preprocessed_image = preprocess_image(image_path)

    # Use Tesseract to perform OCR on the preprocessed image
    text = pytesseract.image_to_string(preprocessed_image, config='--psm 6')
    
    # Return the extracted text
    return text

def parse_timetable(text):
    # Split the text into lines
    lines = text.split('\n')

    # Initialize a list to store timetable entries
    timetable_entries = []

    # Initialize variables for time slots and days
    time_slots = []
    current_day = None
    current_slot = None

    # Iterate over each line to extract relevant information
    for line in lines:
        # Strip whitespace
        line = line.strip()

        # Skip empty lines
        if not line:
            continue

        # Check for day headers
        if line in ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]:
            current_day = line
            continue

        # Check for time slot headers
        if any(keyword in line for keyword in ["Slot", "08:30 to 09:20", "09:20 to 10:10", "10:10 to 11:00", "11:00 to 11:50", "11:50 to 12:40", "12:40 to 01:30", "02:10 to 03:00", "03:00 to 03:50", "03:50 to 04:40"]):
            current_slot = line
            time_slots.append(current_slot)
            continue

        # Check if the line contains subject information
        if current_day and current_slot:
            timetable_entries.append({
                'Day': current_day,
                'Time Slot': current_slot,
                'Details': line
            })

    # Create a DataFrame from the entries
    df = pd.DataFrame(timetable_entries)

    return df

# Example usage
image_path = '3CSE1.jpg'
extracted_text = extract_text_from_image(image_path)
timetable_df = parse_timetable(extracted_text)


print(extract_text_from_image(preprocess_image(cv2.imread(image_path))))
# Print the extracted timetable
print(timetable_df)
