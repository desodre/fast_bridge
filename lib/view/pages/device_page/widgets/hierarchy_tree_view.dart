import 'package:fast_bridge_front/data/models/ui_hierarchy.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

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
    return Container(
      color: Colors.white60,
      child: ListView.builder(itemCount: hierarchy.nodes.length,itemBuilder:(context, index){
        return NodeTiles(node: hierarchy.nodes[index], selectedUiNode: selectedNode,onNodeSelected:onNodeSelected );
      } ),
    );
  }
}


// ignore: must_be_immutable
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

    return Column(
      children: [
        InkWell(
          onHover: (value) {
            if (value) {
              setState(() {
              });
              widget.onNodeSelected(widget.node);
            }
          },
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
              

            });
          },
          child: Padding(
            padding: .only(left: widget.depth * 20.0, top: 4, bottom: 4),
            child: Row(
              children: [
                Icon(
                  hasChildren
                      ? (_isExpanded ? Icons.expand_less : Icons.expand_more)
                      : Icons.check_box_outline_blank,
                  size: 16,
                  color: Colors.grey,
                ),
                SizedBox(width: 4),
                HugeIcon(icon:
                  hasChildren
                      ? HugeIcons.strokeRoundedFolder01
                      : HugeIcons.strokeRoundedFile01,
                  color: Colors.blueGrey,
                  size: 20,
                ),
                SizedBox(width: 8),
                Flexible(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '${widget.node.index} ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text: widget.node.className
                              .split('.')
                              .last, // Apenas o nome da classe
                          style: const TextStyle(
                            color: Colors.teal,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (widget.node.resourceId.isNotEmpty)
                          TextSpan(
                            text: ' id=${widget.node.resourceId.split('/').last}',
                            style: const TextStyle(color: Colors.blueAccent),
                          ),
                      ],
                    ),
                    overflow: .ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_isExpanded && hasChildren)
        ...widget.node.children.map((child) {
          return NodeTiles(node: child, depth: widget.depth + 1, onNodeSelected: widget.onNodeSelected, selectedUiNode: widget.selectedUiNode,);
        })
      ],
    );
  }
}