import 'package:fast_bridge_front/data/models/ui_hierarchy.dart';
import 'package:flutter/material.dart';

class HierarchyTreeView extends StatelessWidget {
  final UiHierarchy hierarchy;
  final UiNode? selectedNode;
  final ValueChanged<UiNode?> onNodeSelected;

  const HierarchyTreeView({
    super.key,
    required this.hierarchy,
    required this.selectedNode,
    required this.onNodeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: hierarchy.nodes.length,
      itemBuilder: (context, index) {
        return NodeTiles(
          node: hierarchy.nodes[index],
          selectedUiNode: selectedNode,
          onNodeSelected: onNodeSelected,
        );
      },
    );
  }
}

class NodeTiles extends StatefulWidget {
  final UiNode node;
  final ValueChanged<UiNode?> onNodeSelected;
  final UiNode? selectedUiNode;
  final int depth;

  const NodeTiles({
    super.key,
    required this.node,
    required this.onNodeSelected,
    required this.selectedUiNode,
    this.depth = 0,
  });

  @override
  State<NodeTiles> createState() => _NodeTilesState();
}

class _NodeTilesState extends State<NodeTiles> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final hasChildren = widget.node.children.isNotEmpty;
    final isSelected = widget.selectedUiNode == widget.node;
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: () {
            setState(() {
              widget.onNodeSelected(widget.node);
              _isExpanded = !_isExpanded;
            });
          },
          child: Container(
            padding: EdgeInsets.only(left: widget.depth * 18.0 + 6, top: 5, bottom: 5, right: 6),
            decoration: BoxDecoration(
              color: isSelected ? cs.primary.withAlpha(30) : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: isSelected ? Border.all(color: cs.primary.withAlpha(60)) : null,
            ),
            child: Row(
              children: [
                Icon(
                  hasChildren
                      ? (_isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded)
                      : Icons.remove_rounded,
                  size: 16,
                  color: cs.primary.withAlpha(150),
                ),
                const SizedBox(width: 4),
                Icon(
                  hasChildren ? Icons.folder_outlined : Icons.description_outlined,
                  color: cs.primary,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '${widget.node.index} ',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: cs.onSurface.withAlpha(220)),
                        ),
                        TextSpan(
                          text: widget.node.className.split('.').last,
                          style: TextStyle(color: cs.primary, fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        if (widget.node.resourceId.isNotEmpty)
                          TextSpan(
                            text: ' ${widget.node.resourceId.split('/').last}',
                            style: TextStyle(color: cs.secondary, fontSize: 12),
                          ),
                      ],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_isExpanded && hasChildren)
          ...widget.node.children.map((child) {
            return NodeTiles(
              node: child,
              depth: widget.depth + 1,
              onNodeSelected: widget.onNodeSelected,
              selectedUiNode: widget.selectedUiNode,
            );
          }),
      ],
    );
  }
}