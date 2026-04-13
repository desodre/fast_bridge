import 'package:fast_bridge_front/data/models/ui_hierarchy.dart';
import 'package:fast_bridge_front/view/pages/device_page/widgets/node_preview_data.dart';
import 'package:flutter/material.dart';

class NodePropertiesPanel extends StatelessWidget {
  const NodePropertiesPanel({
    super.key,
    required this.selectedNode,
  });

  final ValueNotifier<UiNode?> selectedNode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 18, color: cs.primary),
                const SizedBox(width: 6),
                Text('Node Properties', style: theme.textTheme.titleMedium),
              ],
            ),
            const Divider(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: ValueListenableBuilder<UiNode?>(
                  valueListenable: selectedNode,
                  builder: (context, node, _) => NodePreviewData(node: node),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
