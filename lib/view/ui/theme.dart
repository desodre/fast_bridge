// ignore_for_file: unused_element

import 'package:flutter/material.dart';

/// Global theme mode notifier — shared across the app.
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);

// ── Dark Mode ────────────────────────────────────────────────
const _bg = Color(0xFF0F172A);
const _surface = Color(0xFF1E293B);
const _border = Color(0xFF334155);
const _accent = Color(0xFF60A5FA);
const _success = Color(0xFF34D399);
const _error = Color(0xFFF87171);
const _textTitle = Color(0xFFF1F5F9);
const _textBody = Color(0xFFCBD5E1);
const _textDisabled = Color(0xFF64748B);

final ThemeData customTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  scaffoldBackgroundColor: _bg,
  primaryColor: _accent,
  colorScheme: const ColorScheme.dark(
    primary: _accent,
    onPrimary: Color(0xFF0F172A),
    secondary: _accent,
    surface: _surface,
    onSurface: _textTitle,
    error: _error,
    onError: Colors.white,
    surfaceTint: Colors.transparent,
    surfaceContainerHighest: _border,
    surfaceContainerHigh: _surface,
    surfaceContainerLow: _bg,
    surfaceContainerLowest: _bg,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: _surface,
    foregroundColor: _textTitle,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: TextStyle(
      fontFamily: 'Inter',
      fontSize: 17,
      fontWeight: FontWeight.w600,
      color: _textTitle,
      letterSpacing: 0.3,
    ),
    iconTheme: IconThemeData(color: _textBody, size: 22),
  ),
  cardTheme: CardThemeData(
    color: _surface,
    elevation: 0,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(14)),
      side: BorderSide(color: _border, width: 1),
    ),
  ),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: _accent,
    foregroundColor: Color(0xFF0F172A),
    elevation: 4,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
  ),
  iconButtonTheme: IconButtonThemeData(
    style: IconButton.styleFrom(foregroundColor: _textBody),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: _accent,
      foregroundColor: Color(0xFF0F172A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: _border,
    hintStyle: TextStyle(color: _textDisabled),
    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)),
      borderSide: BorderSide(color: _border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)),
      borderSide: BorderSide(color: _accent, width: 1.5),
    ),
  ),
  dividerTheme: const DividerThemeData(color: _border, thickness: 1),
  snackBarTheme: SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
    insetPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  ),
  textTheme: const TextTheme(
    headlineMedium: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, color: _textTitle),
    titleLarge: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, color: _textTitle),
    titleMedium: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500, color: _textTitle),
    bodyLarge: TextStyle(fontFamily: 'Inter', color: _textTitle),
    bodyMedium: TextStyle(fontFamily: 'Inter', color: _textBody),
    bodySmall: TextStyle(fontFamily: 'Inter', color: _textBody, fontSize: 12),
    labelLarge: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, color: _textTitle),
  ),
);

// ── Light Mode ───────────────────────────────────────────────
const _lightBg = Color(0xFFF8FAFC);
const _lightSurface = Color(0xFFFFFFFF);
const _lightBorder = Color(0xFFE2E8F0);
const _lightAccent = Color(0xFF3B82F6);
const _lightSuccess = Color(0xFF10B981);
const _lightError = Color(0xFFEF4444);
const _lightTextTitle = Color(0xFF1E293B);
const _lightTextBody = Color(0xFF475569);
const _lightTextDisabled = Color(0xFF94A3B8);

final ThemeData customLightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  scaffoldBackgroundColor: _lightBg,
  primaryColor: _lightAccent,
  colorScheme: const ColorScheme.light(
    primary: _lightAccent,
    onPrimary: Colors.white,
    secondary: _lightAccent,
    surface: _lightSurface,
    onSurface: _lightTextTitle,
    error: _lightError,
    onError: Colors.white,
    surfaceTint: Colors.transparent,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: _lightSurface,
    foregroundColor: _lightTextTitle,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: TextStyle(
      fontFamily: 'Inter',
      fontSize: 17,
      fontWeight: FontWeight.w600,
      color: _lightTextTitle,
      letterSpacing: 0.3,
    ),
    iconTheme: IconThemeData(color: _lightTextBody, size: 22),
  ),
  cardTheme: CardThemeData(
    color: _lightSurface,
    elevation: 0,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(14)),
      side: BorderSide(color: _lightBorder, width: 1),
    ),
  ),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: _lightAccent,
    foregroundColor: Colors.white,
    elevation: 4,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
  ),
  iconButtonTheme: IconButtonThemeData(
    style: IconButton.styleFrom(foregroundColor: _lightTextBody),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: _lightAccent,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: _lightBg,
    hintStyle: TextStyle(color: _lightTextDisabled),
    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)),
      borderSide: BorderSide(color: _lightBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)),
      borderSide: BorderSide(color: _lightAccent, width: 1.5),
    ),
  ),
  dividerTheme: const DividerThemeData(color: _lightBorder, thickness: 1),
  snackBarTheme: SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
    insetPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  ),
  textTheme: const TextTheme(
    headlineMedium: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, color: _lightTextTitle),
    titleLarge: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, color: _lightTextTitle),
    titleMedium: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500, color: _lightTextTitle),
    bodyLarge: TextStyle(fontFamily: 'Inter', color: _lightTextTitle),
    bodyMedium: TextStyle(fontFamily: 'Inter', color: _lightTextBody),
    bodySmall: TextStyle(fontFamily: 'Inter', color: _lightTextBody, fontSize: 12),
    labelLarge: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, color: _lightTextTitle),
  ),
);