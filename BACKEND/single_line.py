from flask import Flask, request, jsonify
from pymongo import MongoClient
import re

app = Flask(__name__)

# Connect to MongoDB
client = MongoClient("mongodb://localhost:27017/")
db_name = "bakery_ingridents"  # Make sure this matches Compass
db = client[db_name]

# Function to normalize measurement (handle singular/plural & spaces/underscores)
def normalize_measurement(measurement):
    measurement = measurement.lower().strip()
    
    # Convert singular to plural and vice versa
    if measurement.endswith('s'):
        singular = measurement[:-1]  # teaspoons -> teaspoon
        plural = measurement
    else:
        singular = measurement
        plural = measurement + 's'  # teaspoon -> teaspoons

    # Handle spaces and underscores (fluid ounces <-> fluid_ounces)
    space_version = measurement.replace("_", " ")
    underscore_version = measurement.replace(" ", "_")

    return {singular, plural, space_version, underscore_version}

@app.route('/convert', methods=['POST'])
def convert_ingredient():
    data = request.json

    ingredient_name = data.get("ingredient_name", "").strip()
    measurement = data.get("measurement", "").strip()
    quantity = data.get("quantity", 0)

    if not ingredient_name or not measurement or quantity <= 0:
        return jsonify({"success": False, "error": "Invalid input. Please provide ingredient, measurement, and a valid quantity."})

    # Modify ingredient_name to match both underscores and spaces
    ingredient_pattern = re.compile(f"^{ingredient_name.replace(' ', '[_ ]')}$", re.IGNORECASE)

    # Normalize measurement (handle singular/plural & space/underscore variations)
    possible_measurements = normalize_measurement(measurement)

    # Search in all collections
    for coll in db.list_collection_names():
        for unit in possible_measurements:
            result = db[coll].find_one({
                "ingredient": ingredient_pattern,
                f"conversions_to_grams.{unit}": {"$exists": True}
            })

            if result:
                conversion_value = result["conversions_to_grams"].get(unit, None)

                if conversion_value is not None:
                    total_grams = conversion_value * quantity
                    message = f"Success: {quantity} {measurement} of {ingredient_name} is equal to {total_grams:.2f} grams."
                    return jsonify({"success": True, "message": message})

    return jsonify({"success": False, "error": f"No matching ingredient '{ingredient_name}' with the measurement '{measurement}' was found."})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
