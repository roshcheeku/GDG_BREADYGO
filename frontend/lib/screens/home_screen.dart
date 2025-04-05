import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'converter_screen.dart';
import 'chat_screen.dart';
import 'multi_line_recipe_screen.dart';
import 'single_line_recipe_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Gradient Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFFFF5E6),
                  Color(0xFFF8F0E3),
                ],
              ),
            ),
          ),
          
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.pink.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 3,
                      )
                    ],
                  ),
                  child: const Icon(
                    Icons.breakfast_dining,
                    size: 80,
                    color: Color(0xFFFF9BB3),
                  ),
                ),
                const SizedBox(height: 30),
                Text(
                  'BreadyGo',
                  style: GoogleFonts.pacifico(
                    fontSize: 42,
                    color: const Color(0xFFD65780),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Precision Baking Assistant',
                  style: GoogleFonts.dmSans(
                    fontSize: 16,
                    color: const Color(0xFFD4A373),
                  ),
                ),
                const SizedBox(height: 50),
                
                // Convert Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF9BB3),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40, 
                      vertical: 15
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ConverterScreen(),
                      ),
                    );
                  },
                  child: Text(
                    'CONVERT RECIPE',
                    style: GoogleFonts.dmSans(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Multiline Recipe Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF9BB3),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40, 
                      vertical: 15
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MultiLineRecipeScreen(),
                      ),
                    );
                  },
                  child: Text(
                    'MULTILINE RECIPE',
                    style: GoogleFonts.dmSans(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Single Line Recipe Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF9BB3),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40, 
                      vertical: 15
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SingleLineRecipeScreen(),
                      ),
                    );
                  },
                  child: Text(
                    'SINGLE LINE RECIPE',
                    style: GoogleFonts.dmSans(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Floating Chat Button
          Positioned(
            right: 20,
            bottom: 20,
            child: FloatingActionButton(
              heroTag: 'chatBtn',
              backgroundColor: const Color(0xFFD4A373),
              foregroundColor: Colors.white,
              shape: const CircleBorder(),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ChatScreen(),
                  ),
                );
              },
              child: const Icon(Icons.chat, size: 28),
            ),
          ),
        ],
      ),
    );
  }
}
