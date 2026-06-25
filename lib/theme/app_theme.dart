import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const paper = Color(0xFFFAFAF7);
  static const paperSoft = Color(0xFFF2F0E9);
  static const ink = Color(0xFF16181D);
  static const inkMedium = Color(0xFF3F4248);
  static const orange = Color(0xFFFF5A1F);
  static const green = Color(0xFF0F7C6C);
  static const greenSoft = Color(0xFFDCECE8);
  static const red = Color(0xFFB42318);
  static const redSoft = Color(0xFFFDE3DF);
  static const inkSoft = Color(0xFFE6E4DC);
  static const asphalt = Color(0xFF6B7079);
  static const hairline = Color(0xFFECEAE3);
  static const display = Color(0xE316181D);
  static const modal = Color(0xFFF2EFE7);
  static const modalField = Color(0xFFFAFAF7);
}

class AppRadius {
  static const card = 26.0;
  static const field = 24.0;
  static const pill = 22.0;
}

class AppDateStrings {
  static const weekdaysShort = ['seg', 'ter', 'qua', 'qui', 'sex', 'sáb', 'dom'];
  static const weekdays = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
  static const weekdaysFull = [
    'segunda',
    'terça',
    'quarta',
    'quinta',
    'sexta',
    'sábado',
    'domingo',
  ];
  static const months = [
    'janeiro',
    'fevereiro',
    'março',
    'abril',
    'maio',
    'junho',
    'julho',
    'agosto',
    'setembro',
    'outubro',
    'novembro',
    'dezembro',
  ];

  static String twoDigits(int value) => value.toString().padLeft(2, '0');
}

class AppStrings {
  static const selectPlaceholder = 'Toque para escolher';
}

class AppGaps {
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 18.0;
  static const lg = 24.0;
  static const section = 26.0;
  static const bottom = 96.0;
}

class AppTheme {
  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.orange,
      brightness: Brightness.light,
      surface: AppColors.paper,
      primary: AppColors.orange,
      secondary: AppColors.green,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.paper,
      textTheme: _textTheme(),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.paper,
        elevation: 0,
        centerTitle: false,
        foregroundColor: AppColors.ink,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.orange,
        inactiveTrackColor: AppColors.hairline,
        thumbColor: AppColors.orange,
        overlayColor: AppColors.orange.withValues(alpha: 0.12),
        trackHeight: 4,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.paperSoft,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.modal,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.modal,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: AppColors.modal,
        dialBackgroundColor: AppColors.modalField,
        hourMinuteColor: AppColors.modalField,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: AppColors.modal,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
      ),
    );
  }

  static TextTheme _textTheme() {
    return TextTheme(
      displayLarge: GoogleFonts.archivo(
        fontSize: 52,
        height: 0.85,
        fontWeight: FontWeight.w900,
        letterSpacing: -2.0,
        color: AppColors.display,
      ),
      displayMedium: GoogleFonts.archivo(
        fontSize: 30,
        height: 0.98,
        fontWeight: FontWeight.w900,
        letterSpacing: -1.0,
        color: AppColors.display,
      ),
      headlineLarge: GoogleFonts.archivo(
        fontWeight: FontWeight.w900,
        letterSpacing: -1.2,
        color: AppColors.display,
      ),
      headlineMedium: GoogleFonts.archivo(
        fontSize: 26,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.8,
        color: AppColors.display,
      ),
      titleLarge: GoogleFonts.inter(
        fontWeight: FontWeight.w900,
        color: AppColors.ink,
      ),
      titleMedium: GoogleFonts.inter(
        fontWeight: FontWeight.w800,
        color: AppColors.ink,
      ),
      bodyLarge: GoogleFonts.inter(height: 1.35, color: AppColors.ink),
      bodyMedium: GoogleFonts.inter(height: 1.35, color: AppColors.ink),
      labelLarge: GoogleFonts.inter(
        fontWeight: FontWeight.w900,
        color: AppColors.ink,
      ),
    );
  }
}
