import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ConverterScreen extends StatefulWidget {
  const ConverterScreen({super.key});

  @override
  State<ConverterScreen> createState() => _ConverterScreenState();
}

class _ConverterScreenState extends State<ConverterScreen> {
  final TextEditingController _controller = TextEditingController();
  List<dynamic> _results = [];

  Future<void> convertRecipe() async {
    final String input = _controller.text.trim();
    if (input.isEmpty) return;

    final response = await http.post(
      Uri.parse('http://localhost:5000/convert-recipe'), // Adjust for emulator/device
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"recipe": input}),
    );

    if (response.statusCode == 200) {
      setState(() {
        _results = jsonDecode(response.body);
      });
    } else {
      setState(() {
        _results = [{"ingredient": "Error", "quantity": "", "unit": "", "grams": "Conversion failed"}];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF9BB3),
        title: Text(
          'Recipe Converter',
          style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                maxLines: null,
                expands: true,
                keyboardType: TextInputType.multiline,
                decoration: InputDecoration(
                  hintText: 'Paste your recipe here (in paragraph)...',
                  hintStyle: GoogleFonts.dmSans(),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFFFF9BB3)),
                    borderRadius: BorderRadius.circular(15),
                  ),
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
                style: GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),
            if (_results.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    final item = _results[index];
                    return Card(
                      color: const Color(0xFFFFF3E2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        title: Text(
                          item['ingredient'],
                          style: GoogleFonts.dmSans(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${item['quantity']} ${item['unit']} = ${item['grams']}',
                          style: GoogleFonts.dmSans(),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
