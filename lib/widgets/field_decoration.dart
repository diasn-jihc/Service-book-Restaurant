import 'package:flutter/material.dart';

/// Единый вид полей ввода (цвета берутся из темы).
InputDecoration fieldDecoration(String label, IconData icon, {String? hint}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: Icon(icon),
  );
}
