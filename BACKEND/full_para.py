from flask import Flask, request, jsonify
import google.generativeai as genai
import json
import re
from pymongo import MongoClient
from fractions import Fraction
from flask_cors import CORS

app = Flask(__name__)
CORS(app)  # Allow frontend to connect

# Configure Gemini API
genai.configure(api_key="your own gemini api key")  # Replace with your key
model = genai.GenerativeModel("gemini-1.5-pro-latest")

# Connect to MongoDB
client = MongoClient("mongodb://localhost:27017/")
db = client["bakery_ingridents"]

unit_mappings = {
    "kilograms": ["kilogram", "kilograms", "kg"],
    "grams": ["gram", "grams", "g"],
    "cups": ["cup", "cups", "c"],
    "ounces": ["ounce", "ounces", "oz"],
    "pounds": ["pound", "pounds", "lb", "lbs"],
    "pieces": ["piece", "pieces", "pcs"],
    "tablespoons": ["tablespoon", "tablespoons", "tbsp", "tbs"],
    "milliliters": ["milliliter", "milliliters", "ml"],
    "liters": ["liter", "liters", "l"],
    "teaspoons": ["teaspoon", "teaspoons", "tsp"],
    "pints": ["pint", "pints", "pt"],
    "quarts": ["quart", "quarts", "qt"],
    "gallons": ["gallon", "gallons", "gal"],
    "fluid_ounces": ["fluid ounce", "fluid ounces", "fl oz"],
    "drops": ["drop", "drops"],
    "drams": ["dram", "drams"],
    "scoops": ["scoop", "scoops"],
    "pinches": ["pinch", "pinches"],
    "dashes": ["dash", "dashes"],
    "smidgens": ["smidgen", "smidgens"],
    "sticks": ["stick", "sticks"],
    "packets": ["packet", "packets"],
    "bars": ["bar", "bars"],
    "cans": ["can", "cans"],
    "sheets": ["sheet", "sheets"]
}

def normalize_unit(unit):
    if not unit:
        return ""
    unit = unit.lower().strip()
    unit_variants = {unit, unit.replace(" ", "_"), unit.replace("_", " ")}
    for standard, variants in unit_mappings.items():
        if unit in variants or any(v in variants for v in unit_variants):
            return standard
    return unit

def convert_to_float(quantity):
    try:
        if isinstance(quantity, (int, float)):
            return float(quantity)
        quantity = str(quantity).strip()
        if ' ' in quantity:
            parts = quantity.split()
            if len(parts) == 2:
                return float(parts[0]) + float(Fraction(parts[1]))
        return float(Fraction(quantity))
    except:
        return 0.0

def extract_ingredients_gemini(recipe_text):
    prompt = f"""
    Extract structured ingredients from this recipe:
    "{recipe_text}"

    Return a JSON list where each ingredient has:
    - "ingredient": Name of the ingredient
    - "quantity": Amount of the ingredient (as float)
    - "unit": Measurement unit (if applicable)
    """
    try:
        response = model.generate_content(prompt)
        cleaned_response = re.sub(r"json\n|\n|```", "", response.text.strip())
        ingredients = json.loads(cleaned_response)
        for item in ingredients:
            item['quantity'] = convert_to_float(item['quantity'])
        return ingredients
    except Exception as e:
        print(f"Gemini error: {e}")
        return []

def get_ingredient_in_grams(ingredient_name, unit, quantity):
    if not unit:
        return "N/A"
    quantity = convert_to_float(quantity)
    unit = normalize_unit(unit)
    ingredient_variants = {
        ingredient_name,
        ingredient_name.replace(" ", "_"),
        ingredient_name.replace("_", " ")
    }

    for collection_name in db.list_collection_names():
        coll = db[collection_name]
        for ing in ingredient_variants:
            for u in {unit, unit.replace(" ", "_"), unit.replace("_", " ")}:
                query = {
                    "ingredient": {"$regex": f"^{re.escape(ing)}$", "$options": "i"},
                    f"conversions_to_grams.{u}": {"$exists": True}
                }
                result = coll.find_one(query)
                if result:
                    conversion = result["conversions_to_grams"].get(u)
                    if conversion:
                        try:
                            return round(float(conversion) * quantity, 2)
                        except:
                            return "Conversion error"
    return "Not found"

@app.route('/convert-recipe', methods=['POST'])
def convert_recipe():
    data = request.get_json()
    recipe_text = data.get("recipe", "")
    ingredients = extract_ingredients_gemini(recipe_text)

    if not ingredients:
        return jsonify({"error": "No ingredients found"}), 400

    result = []
    for item in ingredients:
        name = item.get("ingredient", "")
        qty = convert_to_float(item.get("quantity", 0))
        unit = normalize_unit(item.get("unit", ""))
        grams = get_ingredient_in_grams(name, unit, qty)
        result.append({
            "ingredient": name,
            "quantity": qty,
            "unit": unit if unit else "N/A",
            "grams": f"{grams}g" if isinstance(grams, (int, float)) else grams
        })

    return jsonify(result)

if __name__ == '__main__':
    app.run(debug=True)
