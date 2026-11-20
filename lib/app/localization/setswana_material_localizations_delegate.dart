import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class SetswanaMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const SetswanaMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'tn';

  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      GlobalMaterialLocalizations.delegate.load(const Locale('en', 'GB'));

  @override
  bool shouldReload(SetswanaMaterialLocalizationsDelegate old) => false;
}
