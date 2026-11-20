import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';

import 'page_thumbnail_tile.dart';

class PageThumbnailGrid extends StatelessWidget {
  const PageThumbnailGrid({
    super.key,
    required this.pageOrder,
    required this.loadThumbnail,
    required this.onPreview,
    this.selectedPages = const <int>{},
    this.selectionEnabled = false,
    this.reorderEnabled = false,
    this.onPageTap,
    this.onReorder,
    this.tileWidth = 176,
  });

  final List<int> pageOrder;
  final Future<Uint8List> Function(int pageIndex) loadThumbnail;
  final ValueChanged<int> onPreview;
  final Set<int> selectedPages;
  final bool selectionEnabled;
  final bool reorderEnabled;
  final ValueChanged<int>? onPageTap;
  final ValueChanged<List<int>>? onReorder;
  final double tileWidth;

  @override
  Widget build(BuildContext context) {
    if (pageOrder.isEmpty) return Center(child: Text('workflow.no_pages'.tr()));
    return LayoutBuilder(builder: (context, constraints) {
      final columns = (constraints.maxWidth / tileWidth).floor().clamp(2, 8).toInt();
      final delegate = SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.70,
      );

      Widget tileAt(int position) {
        final pageIndex = pageOrder[position];
        return PageThumbnailTile(
          key: ValueKey<int>(pageIndex),
          pageNumber: position + 1,
          selected: selectedPages.contains(pageIndex),
          selectionEnabled: selectionEnabled,
          thumbnail: loadThumbnail(pageIndex),
          onTap: selectionEnabled && onPageTap != null ? () => onPageTap!(pageIndex) : null,
          onPreview: () => onPreview(pageIndex),
        );
      }

      if (reorderEnabled && onReorder != null) {
        return ReorderableGridView.builder(
          primary: false,
          padding: const EdgeInsets.fromLTRB(22, 4, 22, 24),
          gridDelegate: delegate,
          itemCount: pageOrder.length,
          dragStartDelay: const Duration(milliseconds: 280),
          restrictDragScope: true,
          itemBuilder: (context, position) => tileAt(position),
          onReorder: (oldIndex, newIndex) {
            final length = pageOrder.length;
            if (oldIndex < 0 || oldIndex >= length || newIndex < 0 || newIndex > length) return;
            final next = List<int>.of(pageOrder);
            final moved = next.removeAt(oldIndex);
            final target = newIndex.clamp(0, next.length).toInt();
            next.insert(target, moved);
            if (next.length != length || next.toSet().length != length || next.any((page) => page < 0)) return;
            onReorder!(next);
          },
        );
      }

      return GridView.builder(
        primary: false,
        padding: const EdgeInsets.fromLTRB(22, 4, 22, 24),
        itemCount: pageOrder.length,
        gridDelegate: delegate,
        itemBuilder: (context, position) => tileAt(position),
      );
    });
  }
}
