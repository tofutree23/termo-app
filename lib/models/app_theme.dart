// lib/models/app_theme.dart
import 'package:flutter/material.dart';

class TerminalTheme {
  final String name;
  final Color background;
  final Color foreground;
  final Color cursor;
  final Color selection;
  final Color black;
  final Color red;
  final Color green;
  final Color yellow;
  final Color blue;
  final Color magenta;
  final Color cyan;
  final Color white;

  const TerminalTheme({
    required this.name,
    required this.background,
    required this.foreground,
    required this.cursor,
    required this.selection,
    required this.black,
    required this.red,
    required this.green,
    required this.yellow,
    required this.blue,
    required this.magenta,
    required this.cyan,
    required this.white,
  });
}

class AppThemes {
  static const termoDark = TerminalTheme(
    name: 'Termo Dark',
    background: Color(0xFF1A1A1A),
    foreground: Color(0xFFE0E0E0),
    cursor: Color(0xFFE0E0E0),
    selection: Color(0xFF404040),
    black: Color(0xFF000000),
    red: Color(0xFFFF5555),
    green: Color(0xFF50FA7B),
    yellow: Color(0xFFF1FA8C),
    blue: Color(0xFF6272A4),
    magenta: Color(0xFFFF79C6),
    cyan: Color(0xFF8BE9FD),
    white: Color(0xFFFFFFFF),
  );

  static const termoLight = TerminalTheme(
    name: 'Termo Light',
    background: Color(0xFFFAFAFA),
    foreground: Color(0xFF2E3440),
    cursor: Color(0xFF2E3440),
    selection: Color(0xFFD8DEE9),
    black: Color(0xFF3B4252),
    red: Color(0xFFBF616A),
    green: Color(0xFFA3BE8C),
    yellow: Color(0xFFEBCB8B),
    blue: Color(0xFF5E81AC),
    magenta: Color(0xFFB48EAD),
    cyan: Color(0xFF88C0D0),
    white: Color(0xFFECEFF4),
  );

  static const dracula = TerminalTheme(
    name: 'Dracula',
    background: Color(0xFF282A36),
    foreground: Color(0xFFF8F8F2),
    cursor: Color(0xFFF8F8F2),
    selection: Color(0xFF44475A),
    black: Color(0xFF21222C),
    red: Color(0xFFFF5555),
    green: Color(0xFF50FA7B),
    yellow: Color(0xFFF1FA8C),
    blue: Color(0xFF6272A4),
    magenta: Color(0xFFFF79C6),
    cyan: Color(0xFF8BE9FD),
    white: Color(0xFFF8F8F2),
  );

  static const List<TerminalTheme> all = [termoDark, termoLight, dracula];
}
