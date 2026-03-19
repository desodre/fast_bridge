import 'package:flutter/material.dart';

final ThemeData customTheme = ThemeData(
  useMaterial3: true,
  primaryColor: const Color.fromARGB(255, 53, 88, 114),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: Color.fromARGB(255, 122, 170, 206),
    extendedTextStyle: TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
    )
  ),
  textTheme: ThemeData.dark()
  .textTheme.apply(
    bodyColor: Colors.white,
    displayColor: Colors.white,
  )
  .apply(
    bodyColor: Colors.white,
    displayColor: Colors.white,
  )
);


final ThemeData customDarkTheme = ThemeData.dark(
  useMaterial3: true,
).copyWith(
  primaryColor: const Color.fromARGB(255, 60, 83, 106),
  secondaryHeaderColor: Color.fromARGB(255, 35, 76, 106),
  
);