import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_screen.dart';
import 'screens/single_line_recipe_screen.dart'; // ✅ Import the screen

void main() {
  runApp(const BreadyGoApp());
}

class BreadyGoApp extends StatelessWidget {
  const BreadyGoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BreadyGo',
      debugShowCheckedModeBanner: false,
      theme: _buildBakeryTheme(),
      home: const HomeScreen(),

      // ✅ Add route for navigation
      routes: {
        '/single': (context) => const SingleLineRecipeScreen(),
      },
    );
  }

  ThemeData _buildBakeryTheme() {
    final baseTheme = ThemeData.light(useMaterial3: true);

    return baseTheme.copyWith(
      colorScheme: ColorScheme.light(
        primary: const Color(0xFFFF9BB3),  // Strawberry Pink
        secondary: const Color(0xFFD4A373),  // Vanilla Cream
        surface: const Color(0xFFF8F0E3),  // Marshmallow White
      ),
      textTheme: GoogleFonts.dmSansTextTheme(baseTheme.textTheme).copyWith(
        displayLarge: GoogleFonts.pacifico(
          fontSize: 32,
          color: const Color(0xFFD65780),  // Raspberry Dark
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFFF9BB3),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFFD4A373),
      ),
    );
  }
}
