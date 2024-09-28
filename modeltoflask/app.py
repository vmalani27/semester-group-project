import joblib
from flask import Flask, request, jsonify
from bs4 import BeautifulSoup
import os
print("Current working directory:", os.getcwd())

app = Flask(__name__)

# Load your trained model with the integrated vectorizer
model = joblib.load("model.pkl")  # Replace with your model file

def extract_plain_text(html_content):
    # Use Beautiful Soup to parse the HTML and extract the text
    soup = BeautifulSoup(html_content, "lxml")
    plain_text = soup.get_text(separator=' ', strip=True)
    return plain_text

@app.route('/predict', methods=['POST'])
def predict():
    data = request.get_json()
    email_content_list = data['input']  # Assuming input is a list of email HTML content
    
    # Process each email content to extract plain text
    processed_emails = [extract_plain_text(email) for email in email_content_list]
    
    # Make predictions directly on the processed plain text
    predictions = model.predict(processed_emails)
    
    # Convert predictions to a list (if not already)
    predictions = predictions.tolist()

    return jsonify({"predictions": predictions})

if __name__ == '__main__':
    app.run(debug=True)
