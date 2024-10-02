import joblib
from flask import Flask, request, jsonify
import tensorflow as tf
import logging
import numpy as np

app = Flask(__name__)
logging.basicConfig(level=logging.DEBUG)

# Load the saved TF-IDF vectorizer and TensorFlow Lite model
tfidf = joblib.load('tfidf_vectorizer.pkl')

# Load the TFLite model
interpreter = tf.lite.Interpreter(model_path="model.tflite")
interpreter.allocate_tensors()

# Function to predict email classification using TFLite model
def predict_email_classification(text):
    input_data = tfidf.transform([text]).toarray()  # Transform input text using the fitted vectorizer
    logging.debug(f'Transformed input data: {input_data}, Type: {type(input_data)}')  # Log the transformed data
    
    input_tensor_index = interpreter.get_input_details()[0]['index']
    output_tensor_index = interpreter.get_output_details()[0]['index']

    interpreter.set_tensor(input_tensor_index, input_data.astype('float32'))
    interpreter.invoke()

    prediction = interpreter.get_tensor(output_tensor_index)
    logging.debug(f'Raw prediction output: {prediction}, Type: {type(prediction)}')  # Log the prediction output
    
    return (prediction > 0.5).astype(int)

@app.route('/predict', methods=['POST'])
def predict():
    try:
        # Extract the email content from the POST request
        data = request.get_json()

        # Log the incoming request data
        logging.debug(f'Received data: {data}, Type: {type(data)}')

        # Check if 'email_content' key exists in the request
        if 'email_content' not in data:
            logging.error("Missing 'email_content' key in request")
            return jsonify({'error': 'Missing email_content key'}), 400

        email_content = data['email_content']

        # Log the received email content and its type
        logging.debug(f'Email content: {email_content}, Type: {type(email_content)}')

        # Predict the classification using the model
        prediction = predict_email_classification(email_content)
        
        # Log the prediction result
        logging.debug(f'Prediction result: {prediction}, Type: {type(prediction)}')

        # Convert the NumPy prediction result to a serializable type (list or float)
        return jsonify({'prediction': prediction.tolist()})  # Convert ndarray to list

    except Exception as e:
        # Log the exception
        logging.error(f"Error occurred: {e}")
        # If there is an error, return a 500 error response
        return str(e), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
