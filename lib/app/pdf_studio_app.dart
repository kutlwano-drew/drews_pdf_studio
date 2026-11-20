import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../core/state/studio_controller.dart';
import '../core/state/studio_scope.dart';
import '../core/theme/studio_theme.dart';
import '../screens/home_screen.dart';
import 'localization/setswana_material_localizations_delegate.dart';
import 'localization/setswana_widgets_localizations_delegate.dart';
import 'localization/setswana_cupertino_localizations_delegate.dart';
import 'pdf_studio_app_state.dart';

class PdfStudioApp extends StatefulWidget {
  const PdfStudioApp({super.key});

  @override
  PdfStudioAppState createState() => PdfStudioAppState();
}

StudioController createStudioController() => StudioController();

Widget buildPdfStudioApp(BuildContext context, StudioController controller) =>
    StudioScope(
      controller: controller,
      child: MaterialApp(
        title: 'Drew’s PDF Studio',
        debugShowCheckedModeBanner: false,
        theme: StudioTheme.light,
        darkTheme: StudioTheme.dark,
        themeMode: ThemeMode.light,
        locale: context.locale,
        supportedLocales: context.supportedLocales,
        localizationsDelegates: [
          ...context.localizationDelegates,
          const SetswanaMaterialLocalizationsDelegate(),
          const SetswanaWidgetsLocalizationsDelegate(),
          const SetswanaCupertinoLocalizationsDelegate(),
        ],
        home: const HomeScreen(),
      ),
    );
