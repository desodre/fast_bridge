import 'package:adb_utils/adb_utils.dart' as adb;
import 'package:fast_bridge_front/view/pages/device_page/widgets/hierarchy_tree_view.dart';
import 'package:flutter/material.dart';

class HierarchyPanel extends StatelessWidget {
  const HierarchyPanel({
    super.key,
    required this.hierarchy,
    required this.isLoading,
    required this.erro,
    required this.selectedNode,
    required this.onNodeSelected,
  });

  final ValueNotifier<adb.UiHierarchy?> hierarchy;
  final ValueNotifier<bool> isLoading;
  final ValueNotifier<String> erro;
  final ValueNotifier<adb.UiNode?> selectedNode;
  final ValueChanged<adb.UiNode?> onNodeSelected;

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
                  return ValueListenableBuilder<adb.UiHierarchy?>(
                    valueListenable: hierarchy,
                    builder: (context, hier, _) {
                      if (hier == null) {
                        return ValueListenableBuilder<String>(
                          valueListenable: erro,
                          builder: (context, errorText, _) {
                            if (errorText.isEmpty) {
                              return const Center(
                                child: Text('No hierarchy loaded yet.'),
                              );
                            }
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.error_outline_rounded,
                                      color: cs.error,
                                      size: 42,
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      errorText,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: cs.error),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      }
                      return ValueListenableBuilder<adb.UiNode?>(
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
