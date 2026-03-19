import 'dart:developer';

import 'package:fast_bridge_front/data/models/ui_hierarchy.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NodePreviewData extends StatelessWidget {
  const NodePreviewData({super.key, required this.node});
  final UiNode? node;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        previewData(lable: 'Index', value: node?.index.toString() ?? 'No data'),
        previewData(lable: 'Text', value: node?.text ?? 'No data'),
        previewData(lable: 'Resource Id', value: node?.resourceId ?? 'No data'),
        previewData(lable: 'Class Name', value: node?.className ?? 'No data'),
        previewData(
          lable: 'Package Name',
          value: node?.packageName ?? 'No data',
        ),
        previewData(
          lable: 'Content Desc',
          value: node?.contentDesc ?? 'No data',
        ),
        previewData(
          lable: 'Checkable',
          value: node?.checkable.toString() ?? 'No data',
        ),
        previewData(
          lable: 'Checked',
          value: node?.checked.toString() ?? 'No data',
        ),
        previewData(
          lable: 'Clickable',
          value: node?.clickable.toString() ?? 'No data',
        ),
        previewData(
          lable: 'Enabled',
          value: node?.enabled.toString() ?? 'No data',
        ),
        previewData(
          lable: 'Focusable',
          value: node?.focusable.toString() ?? 'No data',
        ),
        previewData(
          lable: 'Focused',
          value: node?.focused.toString() ?? 'No data',
        ),
        previewData(
          lable: 'Scrollable',
          value: node?.scrollable.toString() ?? 'No data',
        ),
        previewData(
          lable: 'Long Clickable',
          value: node?.longClickable.toString() ?? 'No data',
        ),
        previewData(
          lable: 'Password',
          value: node?.password.toString() ?? 'No data',
        ),
        previewData(
          lable: 'Selected',
          value: node?.selected.toString() ?? 'No data',
        ),
        previewData(
          lable: 'Visible To User',
          value: node?.visibleToUser.toString() ?? 'No data',
        ),
        previewData(
          lable: 'Bounds',
          value:
              '[${node?.bounds.x1}, ${node?.bounds.y1}][${node?.bounds.x2}, ${node?.bounds.y2}]',
        ),
        previewData(
          lable: 'Drawing Order',
          value: node?.drawingOrder.toString() ?? 'No data',
        ),
        previewData(lable: 'Hint', value: node?.hint ?? 'No data'),
        previewData(
          lable: 'Display Id',
          value: node?.displayId.toString() ?? 'No data',
        ),
      ],
    );
  }
}

Widget previewData({required String lable, required String value}) {
  return Row(
    children: [
      SizedBox(width: 100, child: Text(lable)),
      IconButton(
        color: Colors.white,
        onPressed: () async {
          await Clipboard.setData(ClipboardData(text: value));
          log('Copied: $value');
        },
        icon: Icon(Icons.file_copy_outlined),
        iconSize: 16.0,
      ),
      Expanded(
        child: SelectableText(value, style: TextStyle(overflow: .ellipsis)),
      ),
    ],
  );
}
