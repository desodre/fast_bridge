import 'dart:developer';

import 'package:fast_bridge_front/data/models/ui_hierarchy.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NodePreviewData extends StatelessWidget {
  const NodePreviewData({super.key, required this.node});
  final UiNode? node;

  @override
  Widget build(BuildContext context) {
    if (node == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.touch_app_outlined, size: 40,
                  color: Theme.of(context).colorScheme.primary.withAlpha(100)),
              const SizedBox(height: 12),
              Text('Select a node in the hierarchy',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PropRow(label: 'Index', value: node!.index.toString()),
        _PropRow(label: 'Text', value: node!.text),
        _PropRow(label: 'Resource ID', value: node!.resourceId),
        _PropRow(label: 'Class', value: node!.className),
        _PropRow(label: 'Package', value: node!.packageName),
        _PropRow(label: 'Desc', value: node!.contentDesc),
        _PropRow(label: 'Bounds', value: '[${node!.bounds.x1},${node!.bounds.y1}][${node!.bounds.x2},${node!.bounds.y2}]'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            if (node!.clickable) _FlagChip('Clickable'),
            if (node!.longClickable) _FlagChip('LongClick'),
            if (node!.checkable) _FlagChip('Checkable'),
            if (node!.checked) _FlagChip('Checked'),
            if (node!.enabled) _FlagChip('Enabled'),
            if (node!.focusable) _FlagChip('Focusable'),
            if (node!.focused) _FlagChip('Focused'),
            if (node!.scrollable) _FlagChip('Scrollable'),
            if (node!.selected) _FlagChip('Selected'),
            if (node!.password) _FlagChip('Password'),
            if (node!.visibleToUser) _FlagChip('Visible'),
          ],
        ),
        const SizedBox(height: 8),
        _PropRow(label: 'Draw Order', value: node!.drawingOrder.toString()),
        _PropRow(label: 'Hint', value: node!.hint),
        _PropRow(label: 'Display', value: node!.displayId.toString()),
      ],
    );
  }
}

class _PropRow extends StatelessWidget {
  const _PropRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final displayValue = value.isEmpty ? '—' : value;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                color: cs.onSurface.withAlpha(200))),
          ),
          Expanded(
            child: SelectableText(
              displayValue,
              style: TextStyle(fontSize: 12, color: cs.onSurface),
            ),
          ),
          if (displayValue != '—')
            InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () async {
                await Clipboard.setData(ClipboardData(text: value));
                log('Copied: $value');
              },
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Icon(Icons.copy_rounded, size: 14, color: cs.primary.withAlpha(150)),
              ),
            ),
        ],
      ),
    );
  }
}

class _FlagChip extends StatelessWidget {
  const _FlagChip(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cs.primary.withAlpha(35),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: cs.primary.withAlpha(80)),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cs.primary)),
    );
  }
}
