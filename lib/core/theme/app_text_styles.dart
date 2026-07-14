import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static TextStyle get screenTitle => GoogleFonts.nunitoSans(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static TextStyle get sectionTitle => GoogleFonts.nunitoSans(
    fontSize: 18,
    fontWeight:
        FontWeight.bold, // semibold is usually 600 or bold in Google Fonts
    color: AppColors.textPrimary,
  );

  static TextStyle get body => GoogleFonts.nunitoSans(
    fontSize: 15,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );

  static TextStyle get captionLabel => GoogleFonts.nunitoSans(
    fontSize: 13,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );
}
