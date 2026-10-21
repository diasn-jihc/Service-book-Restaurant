import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

InputDecoration fieldDecoration(String label, IconData icon, {String? hint}) {
  OutlineInputBorder border(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color),
      );

  return InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: Icon(icon),
    labelStyle: const TextStyle(color: Colors.white),
    hintStyle: const TextStyle(color: Colors.white54),
    filled: true,
    fillColor: cardColor,
    border: border(Colors.white24),
    enabledBorder: border(Colors.white24),
    focusedBorder: border(Colors.white),
  );
}
