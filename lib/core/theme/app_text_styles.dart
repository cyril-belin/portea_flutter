import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextStyles {
  AppTextStyles._();

  static TextStyle get screenTitle => GoogleFonts.nunitoSans(
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );

  static TextStyle get sectionTitle => GoogleFonts.nunitoSans(
    fontSize: 18,
    fontWeight:
        FontWeight.bold, // semibold is usually 600 or bold in Google Fonts
  );

  static TextStyle get body => GoogleFonts.nunitoSans(
    fontSize: 15,
    fontWeight: FontWeight.normal,
  );

  static TextStyle get captionLabel => GoogleFonts.nunitoSans(
    fontSize: 13,
    fontWeight: FontWeight.normal,
  );
}
