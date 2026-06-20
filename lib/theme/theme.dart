import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primary = Color(0xFF6B9AC4); // Soft Blue
  static const Color primaryDark = Color(0xFF4059AD);
  static const Color background = Color(0xFFF7F9FC); // Soft White/Gray
  static const Color surface = Color(0xFFFFFFFF); // White
  static const Color surfaceLight = Color(0xFFF0F4F8);

  static const Color pastelGreen = Color(0xFFB5EAD7);
  static const Color pastelRed = Color(0xFFFF9AA2);
  static const Color pastelBlue = Color(0xFFC7CEEA);
  static const Color pastelYellow = Color(0xFFFDFD96);
  static const Color pastelOrange = Color(0xFFFFB347);
  
  static const Color textDark = Color(0xFF1A1A1A); // Almost Black
  static const Color textMuted = Color(0xFF5A5A5A); // Dark Gray

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      colorScheme: const ColorScheme.light(
        primary: primary,
        surface: surface,
        onSurface: textDark,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme).copyWith(
        displayLarge: GoogleFonts.inter(color: textDark, fontWeight: FontWeight.bold),
        bodyLarge: GoogleFonts.inter(color: textDark),
        bodyMedium: GoogleFonts.inter(color: textMuted),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          color: textDark,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: textDark),
      ),
    );
  }
}