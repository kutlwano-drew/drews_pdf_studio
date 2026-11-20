import 'package:flutter/material.dart';

class LanguageOption {
  const LanguageOption({
    required this.locale,
    required this.countryCode,
    required this.label,
  });

  final Locale locale;
  final String countryCode;
  final String label;

  static const all = <LanguageOption>[
    LanguageOption(locale: Locale('en', 'GB'), countryCode: 'GB', label: 'English (British)'),
    LanguageOption(locale: Locale('tn', 'BW'), countryCode: 'BW', label: 'Setswana'),
    LanguageOption(locale: Locale('hi', 'IN'), countryCode: 'IN', label: 'हिन्दी'),
    LanguageOption(locale: Locale('zh', 'CN'), countryCode: 'CN', label: '普通话'),
    LanguageOption(locale: Locale('ar', 'SA'), countryCode: 'SA', label: 'العربية'),
  ];
}
