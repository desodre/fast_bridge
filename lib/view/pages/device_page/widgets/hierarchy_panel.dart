import 'package:fast_bridge_front/data/models/ui_hierarchy.dart';
import 'package:fast_bridge_front/view/pages/device_page/widgets/hierarchy_tree_view.dart';
import 'package:flutter/material.dart';

class HierarchyPanel extends StatelessWidget {
  const HierarchyPanel({
    super.key,
    required this.hierarchy,
    required this.isLoading,
    required this.selectedNode,
    required this.onNodeSelected,
  });

  final ValueNotifier<UiHierarchy?> hierarchy;
  final ValueNotifier<bool> isLoading;
  final ValueNotifier<UiNode?> selectedNode;
  final ValueChanged<UiNode?> onNodeSelected;

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
                Icon(Icons.account_tree_rounded, size: 18, color: cs.primary),
                const SizedBox(width: 6),
                Text('UI Hierarchy', style: theme.textTheme.titleMedium),
              ],
            ),
            const Divider(height: 20),
            Expanded(
              child: ValueListenableBuilder<bool>(
                valueListenable: isLoading,
                builder: (context, loading, _) {
                  if (loading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return ValueListenableBuilder<UiHierarchy?>(
                    valueListenable: hierarchy,
                    builder: (context, hier, _) {
                      if (hier == null) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      return ValueListenableBuilder<UiNode?>(
                        valueListenable: selectedNode,
                        builder: (context, node, _) {
                          return HierarchyTreeView(
                            hierarchy: hier,
                            selectedNode: node,
                            onNodeSelected: onNodeSelected,
                          );
                        },
                      );
                    },
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
