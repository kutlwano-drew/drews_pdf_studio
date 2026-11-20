import 'dart:async';

import 'package:drews_desktop_menu/drews_desktop_menu.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/catalog/tool_catalog.dart';
import '../../core/models/pdf_document_asset.dart';
import '../../core/models/tool_category.dart';
import '../../core/state/studio_controller.dart';
import '../../services/app/app_download_manager.dart';
import '../../widgets/tools/tool_workflow_dialog.dart';
import '../workspace/workspace_action_overlay.dart';
import '../workspace/image_tools_dialog.dart';
import '../workspace/visual_crop_dialog.dart';
import '../workspace/annotation_drawing_dialog.dart';
import 'app_update_dialogs.dart';
import 'download_status_button.dart';
import 'language_selector.dart';
import 'markdown_document_dialog.dart';

class DesktopMenuBar extends StatelessWidget {
  const DesktopMenuBar({
    super.key,
    required this.menuController,
    required this.controller,
    required this.downloads,
    required this.onOpen,
    required this.onOpenRecent,
    required this.onSave,
  });

  final DesktopMenuController menuController;
  final StudioController controller;
  final AppDownloadManager downloads;
  final Future<void> Function() onOpen;
  final Future<void> Function(PdfDocumentAsset document) onOpenRecent;
  final Future<void> Function() onSave;

  DesktopMenuTheme get _theme => const DesktopMenuTheme(
    appBar: DesktopAppBarStyle(
      height: 42,
      backgroundColor: Color(0xFF141923),
      foregroundColor: Colors.white,
      borderColor: Color(0xFF2C3442),
      padding: EdgeInsets.symmetric(horizontal: 12),
      itemSpacing: 2,
    ),
    menu: DesktopMenuStyle(
      width: 244,
      backgroundColor: Color(0xFF1B2230),
      foregroundColor: Colors.white,
      hoverColor: Color(0xFF303B4D),
      borderColor: Color(0xFF394457),
      textStyle: TextStyle(fontSize: 12.5),
    ),
    triggerTextStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
  );

  @override
  Widget build(BuildContext context) => DesktopAppBar(
    controller: menuController,
    style: _theme,
    interactionMode: DesktopMenuInteractionMode.hover,
    children: [
      DesktopAppBarMenu(
        label: 'menu.file'.tr(),
        controllerKey: 'file',
        style: _theme.menu,
        children: [
          _item(context, Icons.folder_open_outlined, 'menu.open'.tr(), onOpen),
          if (controller.recentDocuments.isNotEmpty)
            DesktopSubmenu(
              label: 'Recent files',
              icon: const Icon(Icons.history_rounded),
              children: [
                for (final document in controller.recentDocuments.take(8))
                  _item(
                    context,
                    Icons.picture_as_pdf_outlined,
                    document.name,
                    () => onOpenRecent(document),
                  ),
              ],
            ),
          _item(
            context,
            Icons.save_alt_rounded,
            'menu.save_copy'.tr(),
            onSave,
            enabled: controller.currentDocument != null,
          ),
          const DesktopMenuDivider(),
          _item(
            context,
            Icons.close_rounded,
            'menu.close_document'.tr(),
            () => controller.closeDocument(),
          ),
        ],
      ),
      DesktopAppBarMenu(
        label: 'menu.edit'.tr(),
        controllerKey: 'edit',
        style: _theme.menu,
        children: [
          _item(
            context,
            Icons.undo_rounded,
            'menu.undo'.tr(),
            controller.undo,
            enabled: controller.canUndo,
          ),
          _item(
            context,
            Icons.redo_rounded,
            'menu.redo'.tr(),
            controller.redo,
            enabled: controller.canRedo,
          ),
        ],
      ),
      DesktopAppBarMenu(
        label: 'menu.view'.tr(),
        controllerKey: 'view',
        style: _theme.menu,
        children: [
          _item(
            context,
            Icons.bolt_rounded,
            'menu.quick_actions'.tr(),
            () => WorkspaceActionOverlay.show(context),
          ),
          _item(
            context,
            Icons.compare_arrows_rounded,
            'menu.compare'.tr(),
            () => WorkspaceActionOverlay.show(context),
          ),
        ],
      ),
      DesktopAppBarMenu(
        label: 'menu.tools'.tr(),
        controllerKey: 'tools',
        style: _theme.menu,
        width: 270,
        children: [
          _item(
            context,
            Icons.image_outlined,
            'Image tools',
            () => ImageToolsDialog.show(context),
          ),
          _item(
            context,
            Icons.crop,
            'Visual crop',
            () => VisualCropDialog.show(context),
            enabled: controller.currentDocument != null,
          ),
          _item(
            context,
            Icons.draw_outlined,
            'Draw annotation',
            () => AnnotationDrawingDialog.show(context),
            enabled: controller.currentDocument != null,
          ),
          const DesktopMenuDivider(),
          for (final category in ToolCategory.values)
            DesktopSubmenu(
              label: category.titleKey.tr(),
              icon: Icon(_categoryIcon(category)),
              children: [
                SizedBox(
                  height: 440,
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      for (final tool in ToolCatalog.inCategory(category))
                        _item(
                          context,
                          IconData(tool.iconCode, fontFamily: 'MaterialIcons'),
                          tool.title,
                          () async {
                            await ToolWorkflowDialog.open(context, tool);
                          },
                          enabled:
                              !tool.requiresDocument ||
                              controller.currentDocument != null,
                        ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      DesktopAppBarMenu(
        label: 'menu.about'.tr(),
        controllerKey: 'about',
        style: _theme.menu,
        children: [
          DesktopSubmenu(
            label: 'menu.app'.tr(),
            icon: const Icon(Icons.info_outline),
            children: [
              _item(
                context,
                Icons.description_outlined,
                'menu.app'.tr(),
                () => _showAsset(context, 'About app', 'assets/docs/readme.md'),
              ),
            ],
          ),
          DesktopSubmenu(
            label: 'menu.developer'.tr(),
            icon: const Icon(Icons.person_outline),
            children: [
              _item(
                context,
                Icons.code_rounded,
                'menu.github'.tr(),
                () => _openUrl('https://github.com/kutlwano-drew'),
              ),
              _item(
                context,
                Icons.alternate_email_rounded,
                'X',
                () => _openUrl('https://x.com/kutlwano_drew'),
              ),
            ],
          ),
          DesktopSubmenu(
            label: 'menu.license'.tr(),
            icon: const Icon(Icons.gavel_outlined),
            children: [
              _item(
                context,
                Icons.article_outlined,
                'menu.view_license'.tr(),
                () => _showAsset(context, 'Licence', 'assets/docs/license.md'),
              ),
            ],
          ),
          DesktopSubmenu(
            label: 'menu.whats_new'.tr(),
            icon: const Icon(Icons.new_releases_outlined),
            children: [
              _item(
                context,
                Icons.article_outlined,
                'menu.view_whats_new'.tr(),
                () => _showAsset(
                  context,
                  'What’s new',
                  'assets/docs/whats_new.md',
                ),
              ),
            ],
          ),
          DesktopSubmenu(
            label: 'menu.update'.tr(),
            icon: const Icon(Icons.system_update_alt_rounded),
            children: [
              _item(
                context,
                Icons.refresh_rounded,
                'menu.check_updates'.tr(),
                () => AppUpdateDialogs.check(context, downloads),
              ),
            ],
          ),
          const DesktopMenuDivider(),
          DesktopSubmenu(
            label: 'menu.linux_gui'.tr(),
            icon: const Icon(Icons.desktop_windows_outlined),
            children: [
              _item(
                context,
                Icons.language_rounded,
                'menu.view_website'.tr(),
                () => _openUrl('https://lgui.web.app'),
              ),
              _item(
                context,
                Icons.code_rounded,
                'menu.github'.tr(),
                () => _openUrl(
                  'https://github.com/kutlwano-drew/linux_gui_project',
                ),
              ),
              _item(
                context,
                Icons.play_circle_outline,
                'menu.youtube'.tr(),
                () => _openUrl('https://www.youtube.com/@linuxguiproject'),
              ),
            ],
          ),
        ],
      ),
      DesktopAppBarMenu(
        label: 'menu.support'.tr(),
        controllerKey: 'support',
        style: _theme.menu,
        children: [
          _item(
            context,
            Icons.favorite_border_rounded,
            'menu.support_kofi'.tr(),
            () => _openUrl('https://ko-fi.com/kutlwanodrew'),
          ),
        ],
      ),
    ],
    trailing: [
      DownloadStatusButton(manager: downloads),
      const LanguageSelector(compact: false),
      const SizedBox(width: 4),
    ],
  );

  Widget _item(
    BuildContext context,
    IconData icon,
    String label,
    FutureOr<void> Function() action, {
    bool enabled = true,
  }) => DesktopMenuItem(
    label: label,
    icon: Icon(icon),
    enabled: enabled,
    onPressed: enabled
        ? () {
            menuController.closeAll();
            unawaited(Future<void>.sync(action));
          }
        : null,
  );

  Future<void> _showAsset(
    BuildContext context,
    String title,
    String path,
  ) async {
    final markdown = await rootBundle.loadString(path);
    if (!context.mounted) return;
    await MarkdownDocumentDialog.show(
      context,
      title: title,
      markdown: markdown,
    );
  }

  Future<void> _openUrl(String url) async {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  IconData _categoryIcon(ToolCategory category) => switch (category) {
    ToolCategory.organize => Icons.dashboard_customize_outlined,
    ToolCategory.edit => Icons.edit_note,
    ToolCategory.convert => Icons.swap_horiz,
    ToolCategory.security => Icons.shield_outlined,
    ToolCategory.optimize => Icons.compress,
    ToolCategory.read => Icons.manage_search,
    ToolCategory.forms => Icons.assignment_outlined,
    ToolCategory.create => Icons.note_add_outlined,
    ToolCategory.standards => Icons.verified_outlined,
  };
}
