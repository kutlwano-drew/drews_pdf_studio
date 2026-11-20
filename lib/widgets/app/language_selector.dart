import 'package:country_flags/country_flags.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'language_option.dart';

class LanguageSelector extends StatefulWidget {
  const LanguageSelector({super.key, this.compact = false});

  final bool compact;

  @override
  State<LanguageSelector> createState() => _LanguageSelectorState();
}

class _LanguageSelectorState extends State<LanguageSelector> {
  @override
  Widget build(BuildContext context) {
    final current = LanguageOption.all.firstWhere(
      (option) => option.locale.languageCode == context.locale.languageCode,
      orElse: () => LanguageOption.all.first,
    );
    return PopupMenuButton<LanguageOption>(
      tooltip: 'menu.language'.tr(),
      onSelected: (option) async {
        await context.setLocale(option.locale);
        if (mounted) setState(() {});
      },
      itemBuilder: (context) => [
        for (final option in LanguageOption.all)
          PopupMenuItem<LanguageOption>(
            value: option,
            child: Row(
              children: [
                CountryFlag.fromCountryCode(
                  option.countryCode,
                  theme: const ImageTheme(width: 24, height: 16),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(option.label)),
                if (option.locale.languageCode == context.locale.languageCode)
                  const Icon(Icons.check_rounded, size: 17),
              ],
            ),
          ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CountryFlag.fromCountryCode(
              current.countryCode,
              theme: const ImageTheme(width: 24, height: 16),
            ),
            if (!widget.compact) ...[
              const SizedBox(width: 7),
              Text(current.label, style: const TextStyle(fontSize: 12)),
              const SizedBox(width: 2),
              const Icon(Icons.expand_more, size: 16),
            ],
          ],
        ),
      ),
    );
  }
}
