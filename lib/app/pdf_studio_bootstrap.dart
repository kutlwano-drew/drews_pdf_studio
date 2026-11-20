import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

import 'pdf_studio_app.dart';

class PdfStudioBootstrap extends StatelessWidget {
  const PdfStudioBootstrap({super.key});

  static const supportedLocales = <Locale>[
    Locale('en', 'GB'),
    Locale('tn', 'BW'),
    Locale('hi', 'IN'),
    Locale('zh', 'CN'),
    Locale('ar', 'SA'),
  ];

  @override
  Widget build(BuildContext context) => EasyLocalization(
        supportedLocales: supportedLocales,
        path: 'assets/translations',
        fallbackLocale: const Locale('en', 'GB'),
        startLocale: const Locale('en', 'GB'),
        saveLocale: true,
        useFallbackTranslations: true,
        child: const PdfStudioApp(),
      );
}
