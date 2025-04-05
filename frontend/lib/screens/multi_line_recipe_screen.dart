import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MultiLineRecipeScreen extends StatefulWidget {
  const MultiLineRecipeScreen({super.key});

  @override
  State<MultiLineRecipeScreen> createState() => _MultiLineRecipeScreenState();
}

class _MultiLineRecipeScreenState extends State<MultiLineRecipeScreen> {
  final TextEditingController _recipeController = TextEditingController();
  List<List<String>> tableData = [];

  Future<void> convertRecipe() async {
    final recipeText = _recipeController.text.trim();
    if (recipeText.isEmpty) {
      setState(() => tableData = []);
      return;
    }

    final url = Uri.parse('http://localhost:5000/convert-multiline');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"recipe_text": recipeText}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['result'] != null) {
          List<String> lines = data['result'].split("\n");
          List<List<String>> parsedTable = [];

          for (var line in lines.skip(3)) {
            if (line.contains("|")) {
              var cells = line.split("|").map((cell) => cell.trim()).toList();
              if (cells.length > 4) {
                parsedTable.add([cells[1], cells[2], cells[3], cells[4]]);
              }
            }
          }
          setState(() => tableData = parsedTable);
        }
      }
    } catch (e) {
      setState(() => tableData = []);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Multiline Recipe', style: GoogleFonts.dmSans(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFFF9BB3),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Expanded(
              child: TextField(
                controller: _recipeController,
                maxLines: null,
                expands: true,
                decoration: InputDecoration(
                  hintText: 'Type your recipe here(1 in each line)...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: convertRecipe,
              child: Text('CONVERT RECIPE', style: GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFFD4A373))),
            ),
            const SizedBox(height: 20),
            tableData.isNotEmpty
                ? Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        border: TableBorder.all(),
                        columns: const [
                          DataColumn(label: Text('Ingredient')),
                          DataColumn(label: Text('Qty')),
                          DataColumn(label: Text('Unit')),
                          DataColumn(label: Text('Grams')),
                        ],
                        rows: tableData
                            .map((row) => DataRow(
                                  cells: row.map((cell) => DataCell(Text(cell))).toList(),
                                ))
                            .toList(),
                      ),
                    ),
                  )
                : const SizedBox(),
          ],
        ),
      ),
    );
  }
}
