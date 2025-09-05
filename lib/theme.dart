import 'package:flutter/material.dart';

ThemeData buildTheme() {
  return ThemeData(
    useMaterial3: true,
    colorSchemeSeed: const Color(0xFF00796B),
    brightness: Brightness.light,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
    ),
  );
}

