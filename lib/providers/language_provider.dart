import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _locale = const Locale('en', '');
  
  Locale get locale => _locale;
  
  // Language code to locale mapping
  static const Map<String, Locale> supportedLanguages = {
    'English': Locale('en', ''),
    'සිංහල': Locale('si', ''),
    'தமிழ்': Locale('ta', ''),
  };
  
  // Reverse mapping for getting language name from locale
  static const Map<String, String> localeToLanguageName = {
    'en': 'English',
    'si': 'සිංහල',
    'ta': 'தமிழ்',
  };

  LanguageProvider() {
    _loadLanguagePreference();
  }

  // Load saved language preference from local storage
  Future<void> _loadLanguagePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString('language_code') ?? 'en';
      _locale = Locale(languageCode, '');
      notifyListeners();
    } catch (e) {
      print('Error loading language preference: $e');
    }
  }

  // Change language
  Future<void> changeLanguage(String languageName) async {
    try {
      final newLocale = supportedLanguages[languageName];
      if (newLocale != null) {
        _locale = newLocale;
        
        // Save to local storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('language_code', newLocale.languageCode);
        
        notifyListeners();
      }
    } catch (e) {
      print('Error changing language: $e');
    }
  }

  // Change language by locale
  Future<void> changeLocale(Locale newLocale) async {
    try {
      _locale = newLocale;
      
      // Save to local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language_code', newLocale.languageCode);
      
      notifyListeners();
    } catch (e) {
      print('Error changing locale: $e');
    }
  }

  // Get current language name
  String get currentLanguageName {
    return localeToLanguageName[_locale.languageCode] ?? 'English';
  }

  // Get all supported language names
  static List<String> get allLanguages => supportedLanguages.keys.toList();
}

