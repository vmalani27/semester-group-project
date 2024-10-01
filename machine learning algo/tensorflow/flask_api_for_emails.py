import tensorflow as tf
import numpy as np
from flask import Flask, request, jsonify
from sklearn.feature_extraction.text import TfidfVectorizer
import joblib  # To load the TF-IDF vectorizer

app = Flask(__name__)

# Load the TFLite model
interpreter = tf.lite.Interpreter(model_path="model.tflite")
interpreter.allocate_tensors()

# Load the TF-IDF vectorizer
tfidf = joblib.load('tfidf_vectorizer.pkl')  # Assuming you saved your vectorizer

# Define a function to make predictions
def predict_email_classification(text):
    input_data = tfidf.transform([text]).toarray()

    # Get input and output tensors.
    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()

    # Set the value of the input tensor
    interpreter.set_tensor(input_details[0]['index'], input_data.astype(np.float32))

    # Run inference
    interpreter.invoke()

    # Get the prediction result
    output_data = interpreter.get_tensor(output_details[0]['index'])
    prediction = (output_data[0] > 0.5).astype(int)  # Binary classification: 0 or 1
    return prediction

# API route to accept POST requests
@app.route('/predict', methods=['POST'])
def predict():
    data = request.get_json()
    email_content = data.get('content')
    if email_content:
        prediction = predict_email_classification(email_content)
        return jsonify({'prediction': int(prediction[0])})
    else:
        return jsonify({'error': 'No email content provided'}), 400

if __name__ == '__main__':
    app.run(debug=True)
