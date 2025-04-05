# 🍞 BreadyGo – Smart Recipe Converter App

**BreadyGo** is an intelligent recipe conversion app that transforms everyday cooking into a smarter experience. With multi-format input support, voice commands, ingredient substitution, and precise unit-to-gram conversion, BreadyGo makes recipe preparation accurate, intuitive, and effortless.

---

## 🚀 Features

- 🤖 **AI-Powered Chatbot**  
  Extracts ingredients from PDFs, DOCX, images, and voice commands using the Gemini API.

- 📋 **Multiple Input Options**  
  Supports single ingredient, multiline ingredients, and full paragraph recipes.

- 🧠 **Context-Aware Ingredient Extraction**  
  Uses Gemini to understand and extract ingredients from unstructured recipe formats.

- 🧾 **Custom MongoDB Integration**  
  Maps ingredients (e.g., sugar, vanilla extract) to precise gram values based on user-specified quantity.

- 🔄 **Ingredient Alternatives with Logistic Regression**  
  Chatbot intelligently suggests substitutes when ingredients are missing or unavailable.

- 🎤 **Voice Command Support**  
  Converts spoken recipes into structured ingredients and processes them instantly.

- 📱 **User-Friendly Interface**  
  Built with Flutter for a smooth, clean, and intuitive mobile experience.

---

## 🛠 Technologies Used

| Layer        | Technology         |
|--------------|--------------------|
| Frontend     | Flutter             |
| Backend      | Python (Flask)      |
| AI/ML        | Gemini API, Logistic Regression |
| Database     | MongoDB Atlas       |
| Tools        | Google IDX, VS Code |

---

## 📦 Project Structure

\`\`\`
BreadyGo/
├── backend/                  # Flask Backend
│   ├── app.py               # Main Flask app
│   ├── full_para.py         # Full recipe paragraph processing
│   ├── multi_line.py        # Multiline ingredient processing
│   └── single_line.py       # Single ingredient processing
│
├── bakery/                  # Flutter Frontend Root
│   └── lib/
│       └── screens/
│           ├── home_screen.dart
│           ├── chat_screen.dart
│           ├── multi_line_recipe_screen.dart
│           ├── single_line_recipe_screen.dart
│           └── converter_screen.dart
│       └── main.dart        # App entry point
│
├── android/, ios/, web/     # Flutter platform-specific folders
├── .gitignore, pubspec.yaml # Config files
└── test/                    # (Optional) Testing folder
\`\`\`

---

## ✅ How to Run the Project

### 🔹 Step 1: Start the Flask Backend

📁 Navigate to the `backend/` folder in your terminal.

Run each backend script in separate terminals:

\`\`\`bash
python app.py
python full_para.py
python multi_line.py
python single_line.py
\`\`\`

✅ This will:
- Start all required backend services
- Allow ingredient extraction from all input types
- Connect to MongoDB for unit-to-gram conversion

> ⚠️ Make sure each Flask service runs on a unique port.

---

### 🔹 Step 2: Run the Flutter Frontend

📁 Navigate to the Flutter project directory (e.g., `bakery/`) and run:

\`\`\`bash
flutter run
\`\`\`

Your app will:
- Present options: Chatbot, Single Input, Multiline, Full Recipe
- Interact with the appropriate backend service
- Return structured ingredient data with precise measurements and substitutes

---

## 🔮 Further Development

- 📷 OCR support for handwritten recipes  
- 🌐 Multi-language translation for ingredients  
- 📊 Nutritional breakdown per recipe  
- 🧂 Custom user-defined ingredient profiles  
- 🧑‍🍳 Integration with smart kitchen devices  

---

## 👨‍💻 Authors

Made with 💙 by Triple Helix

---

## 📃 License

MIT License – Free to use, modify, and distribute.
