import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextStyle {
  static String? get fontFamily => GoogleFonts.openSans().fontFamily;

  // Google font
  static TextStyle get defaultFontStyle => GoogleFonts.openSans();

  // Headline 1
  static TextStyle get headline1 => GoogleFonts.openSans(
    fontSize: 28.0,
    fontWeight: FontWeight.w700,
    color: Colors.lightBlueAccent,
  );
  // Headline 2
  static TextStyle get headline2 => GoogleFonts.openSans(
    fontSize: 16.0,
    fontWeight: FontWeight.w600,
  );
  // Headline 3
  static TextStyle get headline3 => GoogleFonts.openSans(
    fontSize: 14.0,
    fontWeight: FontWeight.w700,
  );
  // Bodytext 1
  static TextStyle get bodytext1 => GoogleFonts.roboto(
    fontSize: 16.0,
    color: Colors.black,
  );
  // Caption
  static TextStyle get caption => GoogleFonts.openSans(
    fontSize: 16.0,
    fontWeight: FontWeight.w600,
  );

  static TextTheme get textTheme => TextTheme(
    headlineLarge: headline1,
    headlineMedium: headline2,
    headlineSmall: headline3,
    bodyLarge: bodytext1,
    bodySmall: caption,
  );
}