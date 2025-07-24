from flask import Flask, request, jsonify
from flask_cors import CORS  # Import CORS
import pickle
import numpy as np

app = Flask(__name__)
# CORS(app)  # Enable CORS
CORS(app, resources={r"/predict": {"origins": "*"}})

# # Load trained model
# with open("model.pkl", "rb") as model_file:
#     model = pickle.load(model_file)
try:
    with open("model.pkl", "rb") as model_file:
        model = pickle.load(model_file)
except Exception as e:
    print(f"Failed to load model: {e}")
    model = None

# Define anxiety level mapping
anxiety_levels = {0: "Mild", 1: "Moderate", 2: "Severe"}

@app.route('/predict', methods=['POST'])
def predict():
    try:
        data = request.get_json()
        if not data:
            return jsonify({"error": "No data received"}), 400

        # Convert input data to array
        input_data = np.array(list(data.values())).reshape(1, -1)

        # Predict using the trained model
        prediction = model.predict(input_data)[0]

        return jsonify({"anxiety_level": anxiety_levels.get(prediction, "Unknown")})
    
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=6000)

