from flask import Flask, request, jsonify
from flask_cors import CORS
from werkzeug.utils import secure_filename
import os
import pandas as pd
import numpy as np
import joblib
import re
import string
from PIL import Image
from pymongo import MongoClient
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.linear_model import LogisticRegression
from sklearn.metrics.pairwise import cosine_similarity
import google.generativeai as genai
import speech_recognition as sr
import pyttsx3

app = Flask(__name__)
CORS(app)  # Enable CORS for all routes

# === Configuration ===
UPLOAD_FOLDER = 'uploads'
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'pdf', 'docx', 'wav', 'mp3'}
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER
app.config['MAX_CONTENT_LENGTH'] = 16 * 1024 * 1024  # 16MB

os.makedirs(UPLOAD_FOLDER, exist_ok=True)

# === Gemini API Config ===
genai.configure(api_key="your gemini api key")
text_model = genai.GenerativeModel("gemini-1.5-pro-latest")
vision_model = genai.GenerativeModel("gemini-1.5-flash")

# === Voice Tools ===
recognizer = sr.Recognizer()
engine = pyttsx3.init()

# === Load Dataset ===
df = pd.read_csv(r"C:\gsd\final_substitution.csv")
df.columns = df.columns.str.lower()
df.rename(columns={'food label': 'ingredient', 'substitution label': 'substitute'}, inplace=True)
if 'ingredient' not in df.columns or 'substitute' not in df.columns:
    raise ValueError("CSV must contain 'ingredient' and 'substitute' columns.")

# === Preprocessing & Model Training ===
def preprocess_text(text):
    if isinstance(text, str):
        text = text.lower()
        text = re.sub(r'\d+', '', text)
        text = text.translate(str.maketrans('', '', string.punctuation))
        text = text.strip()
    return text

df['ingredient_clean'] = df['ingredient'].apply(preprocess_text)
df['substitute_clean'] = df['substitute'].apply(preprocess_text)

vectorizer = TfidfVectorizer()
X = vectorizer.fit_transform(df['ingredient_clean'])
y = df['substitute_clean']

model_ml = LogisticRegression()
model_ml.fit(X, y)

# Save models
joblib.dump(model_ml, "ingredient_substitution_model.pkl")
joblib.dump(vectorizer, "tfidf_vectorizer.pkl")

# === MongoDB for Recipe Scaling ===
client = MongoClient("mongodb://localhost:27017/")
db = client.recipe_db

# === In-memory conversation history ===
conversation_history = []

# === Allowed File Types ===
def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

# === Helper: Ask Gemini Bot ===
def ask_baking_bot(user_input):
    prompt = f"""
    You are a professional pastry chef and baking expert.
    Only answer questions about baking, pastry, and cooking.
    User's Question: {user_input}
    """
    response = text_model.generate_content(prompt)
    return response.text

# === Helper: Suggest Substitute ===
def suggest_substitute(query):
    query = preprocess_text(query)
    query_vec = vectorizer.transform([query])
    try:
        predicted_substitute = model_ml.predict(query_vec)[0]
        ai_verification = ask_baking_bot(f"Is {predicted_substitute} a valid substitute for {query}?")
        if query.lower() in ai_verification.lower():
            return f"✅ ML & Gemini Verified Substitute: {predicted_substitute}"
    except:
        pass
    similarity_scores = cosine_similarity(query_vec, X)
    best_match_idx = np.argmax(similarity_scores)
    return f"🔍 Suggested Substitute (Similarity-Based): {df.iloc[best_match_idx]['substitute_clean']}"

# === Endpoint: Ask Question ===
@app.route('/api/ask', methods=['POST'])
def ask_question():
    data = request.get_json()
    if not data or 'question' not in data:
        error_response = {"error": "Missing 'question' in request"}
        print("❌ Error:", error_response)
        return jsonify(error_response), 400

    question = data['question']
    response = ask_baking_bot(question)

    conversation_history.append({"user": question, "assistant": response})
    response_data = {"question": question, "response": response}

    print("✅ Response to frontend:", response_data)
    return jsonify(response_data)

# === Endpoint: Analyze Image ===
@app.route('/api/analyze-image', methods=['POST'])
def analyze_image_endpoint():
    if 'file' not in request.files:
        error_response = {"error": "No file uploaded"}
        print("❌ Error:", error_response)
        return jsonify(error_response), 400

    file = request.files['file']
    if file.filename == '':
        error_response = {"error": "No selected file"}
        print("❌ Error:", error_response)
        return jsonify(error_response), 400

    if file and allowed_file(file.filename):
        filename = secure_filename(file.filename)
        filepath = os.path.join(app.config['UPLOAD_FOLDER'], filename)
        file.save(filepath)

        try:
            analysis = analyze_food_image(filepath)
            os.unlink(filepath)
            response_data = {"image": filename, "analysis": analysis}
            print("📷 Image Analysis Response:", response_data)
            return jsonify(response_data)
        except Exception as e:
            error_response = {"error": str(e)}
            print("❌ Error:", error_response)
            return jsonify(error_response), 500

    error_response = {"error": "Invalid file type"}
    print("❌ Error:", error_response)
    return jsonify(error_response), 400

# === Helper: Analyze Image with Gemini ===
def analyze_food_image(image_path):
    try:
        image = Image.open(image_path)
        if image.mode != "RGB":
            image = image.convert("RGB")
        prompt = """
        You are a professional chef and baking expert.
        Analyze this food image and provide:
        1. Likely food item
        2. Key ingredients visible
        3. Comments on preparation and doneness
        4. Tip for improvement if needed
        """
        response = vision_model.generate_content([prompt, image])
        return response.text
    except Exception as e:
        return f"Error analyzing image: {str(e)}"

# === Run App ===
if __name__ == '__main__':
    app.run(debug=True)
