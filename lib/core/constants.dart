import 'package:flutter/material.dart';

/// Strict minimalist palette — exact 30/30/30/10 distribution.
class AppColors {
  AppColors._();

  static const Color black = Color(0xFF000000); // Primary background (30%)
  static const Color blackAlt = Color(0xFF080808); // Primary background alt
  static const Color white = Color(0xFFFFFFFF); // Primary text / borders (30%)
  static const Color red = Color(0xFFFF003C); // Accent / action (30%)
  static const Color gray = Color(0xFF1A1C20); // Secondary bg / disabled (10%)
  static const Color whiteMuted = Color(0x8AFFFFFF); // 54% white, hints/labels
}

class HiveBoxes {
  HiveBoxes._();

  static const String wallet = 'wallet_box';
  static const String chatSessions = 'chat_sessions_box';
  static const String messages = 'messages_box';
  static const String settings = 'settings_box';
}

class AppConstants {
  AppConstants._();

  static const int startingCredits = 3;
  static const int splashVideoCount = 7;
  static const String lastPlayedIndexKey = 'last_played_index';
}
