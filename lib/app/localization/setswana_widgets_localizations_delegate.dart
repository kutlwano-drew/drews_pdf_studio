import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class SetswanaWidgetsLocalizationsDelegate
    extends LocalizationsDelegate<WidgetsLocalizations> {
  const SetswanaWidgetsLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'tn';

  @override
  Future<WidgetsLocalizations> load(Locale locale) =>
      GlobalWidgetsLocalizations.delegate.load(const Locale('en', 'GB'));

  @override
  bool shouldReload(SetswanaWidgetsLocalizationsDelegate old) => false;
}
