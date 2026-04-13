import 'package:fast_bridge_front/data/models/file_node.dart';
import 'package:fast_bridge_front/viewmodel/file_manager_viewmodel.dart';
import 'package:flutter/material.dart';

class FileTreeNode extends StatelessWidget {
  const FileTreeNode({
    super.key,
    required this.node,
    required this.path,
    required this.viewModel,
    this.depth = 0,
  });

  final FileNode node;
  final String path;
  final FileManagerViewModel viewModel;
  final int depth;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isExpanded = viewModel.isExpanded(path);
    final isLoading = viewModel.isLoading(path);
    final children = viewModel.childrenOf(path);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: node.isDir ? () => viewModel.toggle(path) : null,
          child: Padding(
            padding: EdgeInsets.only(
              left: depth * 20.0 + 8,
              top: 5,
              bottom: 5,
              right: 8,
            ),
            child: Row(
              children: [
                // expand / loading indicator
                SizedBox(
                  width: 18,
                  child: node.isDir
                      ? isLoading
                          ? SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                color: cs.primary,
                              ),
                            )
                          : Icon(
                              isExpanded
                                  ? Icons.expand_more_rounded
                                  : Icons.chevron_right_rounded,
                              size: 16,
                              color: cs.primary.withAlpha(160),
                            )
                      : const SizedBox.shrink(),
                ),
                const SizedBox(width: 4),
                // icon
                Icon(
                  _iconFor(node),
                  size: 16,
                  color: node.isDir
                      ? cs.primary
                      : cs.onSurface.withAlpha(160),
                ),
                const SizedBox(width: 8),
                // name
                Expanded(
                  child: Text(
                    node.name,
                    style: TextStyle(
                      fontSize: 13,
                      color: cs.onSurface,
                      fontWeight: node.isDir
                          ? FontWeight.w500
                          : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // size / modified
                Text(
                  node.formattedSize,
                  style: TextStyle(
                    fontSize: 11,
                    color: cs.onSurface.withAlpha(120),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  node.modifiedAt,
                  style: TextStyle(
                    fontSize: 11,
                    color: cs.onSurface.withAlpha(120),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isExpanded && children != null)
          ...children.map(
            (child) => FileTreeNode(
              node: child,
              path: child.fullPath(path),
              viewModel: viewModel,
              depth: depth + 1,
            ),
          ),
      ],
    );
  }

  IconData _iconFor(FileNode node) {
    if (node.isSymlink) return Icons.link_rounded;
    if (!node.isDir) {
      final ext = node.name.split('.').last.toLowerCase();
      return switch (ext) {
        'jpg' || 'jpeg' || 'png' || 'gif' || 'webp' =>
          Icons.image_rounded,
        'mp4' || 'mkv' || 'avi' || 'mov' => Icons.video_file_rounded,
        'mp3' || 'wav' || 'ogg' || 'flac' => Icons.audio_file_rounded,
        'apk' => Icons.android_rounded,
        'pdf' => Icons.picture_as_pdf_rounded,
        'zip' || 'tar' || 'gz' || 'rar' => Icons.folder_zip_rounded,
        _ => Icons.insert_drive_file_rounded,
      };
    }
    return Icons.folder_rounded;
  }
}
