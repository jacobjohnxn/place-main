from flask import Flask, request, jsonify
import joblib
from sklearn.tree import DecisionTreeClassifier
from sklearn.preprocessing import OneHotEncoder
import logging
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

# Placeholder for the loaded model and encoder
loaded_model = joblib.load(r'D:\projexct\flutter projects\student_pp-main\place-main\decision_tree_model.pkl')
encoder = joblib.load(r'D:\projexct\flutter projects\student_pp-main\place-main\encoder.pkl')

# Set up logging
logging.basicConfig(filename='server.log', level=logging.INFO)

@app.route('/load_model', methods=['POST'])
def load_model():
    return jsonify({'message': 'Model and encoder are already loaded'}), 200

@app.route('/predict', methods=['POST'])
def predict():
    global loaded_model, encoder

    try:
        # Get the input data from the request
        data = request.json

        # Validate input data
        if 'course' not in data:
            return jsonify({'error': 'Missing input data: "course" field is required.'}), 400
        
        # Extract the course from the input data
        course = data['course'].strip()

        # Encode the input course
        course_encoded = encoder.transform([[course]])

        # Make prediction using the loaded model
        predicted_score = loaded_model.predict(course_encoded)[0]

        logging.info(f'Predicted score for course "{course}" is {predicted_score}')
        return jsonify({'predicted_score': int(predicted_score)}), 200
    except ValueError as e:
        error_message = f'Error predicting score: {str(e)}'
        logging.error(error_message)
        return jsonify({'error': error_message}), 422
    except Exception as e:
        error_message = f'Unexpected error: {str(e)}'
        logging.error(error_message)
        return jsonify({'error': error_message}), 500

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0')
