import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../core/models/tool_category.dart';
import '../common/brand_mark.dart';
import 'nav_item.dart';

class SideNavigation extends StatelessWidget {
  const SideNavigation({
    super.key,
    required this.selected,
    required this.activeView,
    required this.onSelect,
    required this.onHome,
    required this.onWorkspace,
    this.compact = false,
  });

  final ToolCategory? selected;
  final String activeView;
  final ValueChanged<ToolCategory?> onSelect;
  final VoidCallback onHome;
  final VoidCallback onWorkspace;
  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
        width: compact ? 72 : 238,
        color: Colors.black,
        padding: EdgeInsets.fromLTRB(compact ? 10 : 18, 22, compact ? 10 : 12, 18),
        child: Column(
          crossAxisAlignment: compact
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.start,
          children: [
            BrandMark(compact: compact),
            SizedBox(height: compact ? 24 : 34),
            NavItem(
              icon: Icons.grid_view_rounded,
              label: 'navigation.all_tools'.tr(),
              selected: selected == null && activeView == 'home',
              onTap: onHome,
              compact: compact,
            ),
            NavItem(
              icon: Icons.picture_as_pdf_outlined,
              label: 'navigation.workspace'.tr(),
              selected: activeView == 'workspace',
              onTap: onWorkspace,
              compact: compact,
            ),
            if (!compact) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(),
              ),
              Text(
                'navigation.pdf_tools'.tr(),
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.3,
                  color: Colors.white54,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
            ] else
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(),
              ),
            Expanded(
              child: ListView(
                children: [
                  for (final category in ToolCategory.values)
                    NavItem(
                      icon: _icon(category),
                      label: category.titleKey.tr(),
                      selected: selected == category,
                      onTap: () => onSelect(category),
                      compact: compact,
                    ),
                ],
              ),
            ),
            if (!compact) ...[
              const Divider(),
              Text(
                'navigation.local_processing'.tr(),
                style: TextStyle(fontSize: 11, color: Colors.white54),
              ),
            ],
          ],
        ),
      );

  IconData _icon(ToolCategory category) => switch (category) {
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
