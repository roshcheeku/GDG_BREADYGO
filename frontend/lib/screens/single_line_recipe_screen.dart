import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SingleLineRecipeScreen extends StatefulWidget {
  const SingleLineRecipeScreen({super.key});

  @override
  State<SingleLineRecipeScreen> createState() => _SingleLineRecipeScreenState();
}

class _SingleLineRecipeScreenState extends State<SingleLineRecipeScreen> {
  final TextEditingController _ingredientController = TextEditingController();
  final TextEditingController _measurementController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();

  String result = "";

  Future<void> convertRecipe() async {
    final ingredient = _ingredientController.text.trim();
    final measurement = _measurementController.text.trim();
    final quantityText = _quantityController.text.trim();
    final quantity = double.tryParse(quantityText);

    if (ingredient.isEmpty || measurement.isEmpty || quantity == null || quantity <= 0) {
      setState(() {
        result = "Please enter a valid ingredient, measurement, and quantity.";
      });
      return;
    }

    final url = Uri.parse('http://localhost:5000/convert'); // Replace with real IP if needed

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "ingredient_name": ingredient,
        "measurement": measurement,
        "quantity": quantity
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        result = data['success']
            ? data['message']
            : data['error'] ?? "Unknown error.";
      });
    } else {
      setState(() {
        result = "Failed to connect to backend.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF9BB3),
        centerTitle: true,
        title: Text(
          'Ingredient Converter',
          style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        leading: IconButton(  // ✅ Explicitly added back button
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context); // Go back to the previous screen
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: _ingredientController,
              decoration: InputDecoration(
                labelText: 'Ingredient Name',
                hintText: 'e.g. sugar',
                hintStyle: GoogleFonts.dmSans(),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xFFFF9BB3)),
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _measurementController,
              decoration: InputDecoration(
                labelText: 'Measurement',
                hintText: 'e.g. cups, teaspoons, fluid ounces',
                hintStyle: GoogleFonts.dmSans(),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xFFFF9BB3)),
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _quantityController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Quantity',
                hintText: 'e.g. 2',
                hintStyle: GoogleFonts.dmSans(),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xFFFF9BB3)),
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4A373),
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              onPressed: convertRecipe,
              child: Text(
                'CONVERT RECIPE',
                style: GoogleFonts.dmSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              result,
              style: GoogleFonts.dmSans(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
