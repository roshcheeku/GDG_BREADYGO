from flask import Flask, request, jsonify
import google.generativeai as genai
import json
import re
from pymongo import MongoClient
from fractions import Fraction
from tabulate import tabulate

app = Flask(__name__)

# Configure Gemini API
genai.configure(api_key="AIzaSyCQIi7JQhrwOZqt6JNS1kvz9hxsrRs2PgA")  # Replace with your actual key
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
    unit = unit.lower().replace("_", " ").strip()
    for standard, variants in unit_mappings.items():
        if unit in variants:
            return standard
    return unit

def convert_to_float(quantity):
    try:
        return float(sum(Fraction(part) for part in quantity.split()))
    except ValueError:
        return 0.0

def extract_ingredients_list(ingredient_lines):
    ingredients = []
    for line in ingredient_lines:
        line = line.lstrip("- ")
        match = re.match(r"([\d/\s]+)\s*([a-zA-Z_]+)?\s*(.*)", line.strip())
        if match:
            quantity, unit, ingredient = match.groups()
            ingredients.append({
                "ingredient": ingredient.strip().replace("_", " "),
                "quantity": convert_to_float(quantity),
                "unit": normalize_unit(unit)
            })
    return ingredients

def get_ingredient_in_grams(ingredient_name, unit, quantity):
    if not unit:
        return "N/A"

    try:
        quantity = float(quantity)
    except ValueError:
        return "Invalid quantity"

    normalized_unit = normalize_unit(unit)

    # Create search variants for ingredient (space ↔ underscore)
    variants = {ingredient_name, ingredient_name.replace(" ", "_"), ingredient_name.replace("_", " ")}

    for collection_name in db.list_collection_names():
        coll = db[collection_name]
        for variant in variants:
            query = {
                "ingredient": {"$regex": f"^{re.escape(variant)}$", "$options": "i"},
                f"conversions_to_grams.{normalized_unit}": {"$exists": True}
            }
            result = coll.find_one(query)
            if result:
                conversion = result["conversions_to_grams"].get(normalized_unit)
                if conversion:
                    try:
                        return round(float(conversion) * quantity, 2)
                    except ValueError:
                        continue

    return "Not found"

@app.route("/convert-multiline", methods=["POST"])
def convert_multiline():
    data = request.get_json()
    recipe_text = data.get("recipe_text", "")
    lines = recipe_text.strip().split("\n")

    ingredients = extract_ingredients_list(lines)
    if not ingredients:
        return jsonify({"result": "No valid ingredients found."})

    table_data = []
    for item in ingredients:
        name = item.get("ingredient", "")
        qty = item.get("quantity", 0)
        unit = item.get("unit", "")
        grams = get_ingredient_in_grams(name, unit, qty)
        table_data.append([name, qty, unit if unit else "N/A", f"{grams}g" if isinstance(grams, (int, float)) else grams])

    output_table = tabulate(table_data, headers=["Ingredient", "Qty", "Unit", "Grams"], tablefmt="grid")
    return jsonify({"result": output_table})

if __name__ == "__main__":
    app.run(debug=True)