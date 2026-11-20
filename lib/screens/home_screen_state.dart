import 'package:country_flags/country_flags.dart';
import 'package:drews_desktop_menu/drews_desktop_menu.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../core/models/tool_category.dart';
import '../core/models/pdf_document_asset.dart';
import '../core/state/studio_scope.dart';
import '../services/app/app_download_manager.dart';
import '../services/app/app_preferences.dart';
import '../widgets/app/desktop_menu_bar.dart';
import '../widgets/app/app_keyboard_shortcuts.dart';
import '../widgets/app/language_option.dart';
import '../widgets/common/app_error_dialog.dart';
import '../widgets/home/side_navigation.dart';
import 'dashboard_screen.dart';
import 'tool_library_screen.dart';
import 'workspace_screen.dart';
import 'home_screen.dart';

class HomeScreenState extends State<HomeScreen> {
  ToolCategory? _category;
  String _view = 'home';
  final _preferences = AppPreferences();
  late final DesktopMenuController _menuController = DesktopMenuController();
  late final AppDownloadManager _downloads = AppDownloadManager();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _showFirstLaunchLanguagePicker(),
    );
  }

  @override
  void dispose() {
    _menuController.dispose();
    _downloads.dispose();
    super.dispose();
  }

  Future<void> _showFirstLaunchLanguagePicker() async {
    if (!mounted || !await _preferences.isFirstLaunch()) return;
    if (!mounted) return;
    var selected = LanguageOption.all.first;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('onboarding.title'.tr()),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('onboarding.body'.tr()),
                const SizedBox(height: 12),
                for (final option in LanguageOption.all)
                  RadioListTile<LanguageOption>(
                    value: option,
                    groupValue: selected,
                    onChanged: (value) =>
                        setDialogState(() => selected = value!),
                    title: Row(
                      children: [
                        CountryFlag.fromCountryCode(
                          option.countryCode,
                          theme: const ImageTheme(width: 28, height: 18),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text(option.label)),
                      ],
                    ),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
              ],
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () async {
                await context.setLocale(selected.locale);
                await _preferences.completeFirstLaunch();
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              },
              child: Text('onboarding.continue'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveCurrent() async {
    final controller = StudioScope.read(context);
    if (controller.currentDocument == null) return;
    await controller.runTask('Saving PDF…', () async {
      if (controller.hasWorkingCopy) {
        await controller.exportWorkingCopy();
      } else {
        final document = controller.currentDocument;
        if (document != null)
          await controller.files.savePdf(document.name, document.bytes);
      }
    });
    if (!mounted) return;
    if (controller.errorMessage != null) {
      await AppErrorDialog.show(
        context,
        title: 'Could not save PDF',
        message: controller.errorMessage!,
      );
      controller.clearMessages();
    }
  }

  Future<void> _openRecent(PdfDocumentAsset document) async {
    await StudioScope.read(context).openBytes(document.name, document.bytes);
    if (mounted) setState(() => _view = 'workspace');
  }

  Future<void> _openPdf() async {
    StudioScope.read(context).clearMessages();
    await StudioScope.read(context).openPdf();
    if (!mounted) return;
    final controller = StudioScope.read(context);
    if (controller.errorMessage != null) {
      await AppErrorDialog.show(
        context,
        title: 'Could not open PDF',
        message: controller.errorMessage!,
      );
      controller.clearMessages();
      return;
    }
    if (controller.currentDocument != null) setState(() => _view = 'workspace');
  }

  @override
  Widget build(BuildContext context) {
    final controller = StudioScope.watch(context);
    return AppKeyboardShortcuts(
      onUndo: () {
        if (controller.canUndo) controller.undo();
      },
      onRedo: () {
        if (controller.canRedo) controller.redo();
      },
      onOpen: _openPdf,
      onSave: _saveCurrent,
      child: Scaffold(
        body: Column(
          children: [
            DesktopMenuBar(
              menuController: _menuController,
              controller: controller,
              downloads: _downloads,
              onOpen: _openPdf,
              onOpenRecent: _openRecent,
              onSave: _saveCurrent,
            ),
            if (controller.isBusy) const LinearProgressIndicator(minHeight: 2),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compactNavigation = constraints.maxWidth < 880;
                  return Row(
                    children: [
                      SideNavigation(
                        selected: _category,
                        activeView: _view,
                        compact: compactNavigation,
                        onHome: () => setState(() {
                          _category = null;
                          _view = 'home';
                        }),
                        onWorkspace: () => setState(() {
                          _category = null;
                          _view = 'workspace';
                        }),
                        onSelect: (category) => setState(() {
                          _category = category;
                          _view = 'category';
                        }),
                      ),
                      Expanded(
                        child: switch (_view) {
                          'workspace' => const WorkspaceScreen(),
                          'category' => ToolLibraryScreen(category: _category!),
                          _ => DashboardScreen(onOpen: _openPdf),
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
