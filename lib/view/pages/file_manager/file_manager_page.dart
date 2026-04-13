import 'package:fast_bridge_front/view/pages/file_manager/widgets/file_tree_node.dart';
import 'package:fast_bridge_front/view/widgets/device_nav_dropdown.dart';
import 'package:fast_bridge_front/view/widgets/empty_state.dart';
import 'package:fast_bridge_front/view/widgets/loading_indicator.dart';
import 'package:fast_bridge_front/viewmodel/file_manager_viewmodel.dart';
import 'package:flutter/material.dart';

class FileManagerPage extends StatefulWidget {
  const FileManagerPage({super.key, required this.serial});

  final String serial;

  @override
  State<FileManagerPage> createState() => _FileManagerPageState();
}

class _FileManagerPageState extends State<FileManagerPage> {
  late final FileManagerViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = FileManagerViewModel(serial: widget.serial);
    // rebuild whenever tree state changes
    _viewModel.cache.addListener(_rebuild);
    _viewModel.expanded.addListener(_rebuild);
    _viewModel.loading.addListener(_rebuild);
    _viewModel.init();
  }

  void _rebuild() => setState(() {});

  @override
  void dispose() {
    _viewModel.cache.removeListener(_rebuild);
    _viewModel.expanded.removeListener(_rebuild);
    _viewModel.loading.removeListener(_rebuild);
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isRootLoading = _viewModel.isLoading(FileManagerViewModel.root);
    final rootChildren = _viewModel.childrenOf(FileManagerViewModel.root);
    final erro = _viewModel.erro.value;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_rounded, color: cs.primary, size: 22),
            const SizedBox(width: 8),
            Text(
              widget.serial,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              // clear cache for expanded paths and reload
              final toRefresh = Set<String>.from(_viewModel.expanded.value);
              _viewModel.cache.value = {};
              _viewModel.expanded.value = {};
              for (final path in toRefresh) {
                _viewModel.toggle(path);
              }
            },
          ),
          DeviceNavDropdown(
            serial: widget.serial,
            current: DeviceSection.fileManager,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _buildBody(isRootLoading, rootChildren, erro),
    );
  }

  Widget _buildBody(
    bool isRootLoading,
    List<dynamic>? rootChildren,
    String erro,
  ) {
    if (isRootLoading) {
      return const LoadingIndicator(message: 'Loading file system...');
    }

    if (erro.isNotEmpty && rootChildren == null) {
      return Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  color: Theme.of(context).colorScheme.error,
                  size: 48,
                ),
                const SizedBox(height: 14),
                Text(erro, textAlign: TextAlign.center),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _viewModel.init,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (rootChildren == null || rootChildren.isEmpty) {
      return const EmptyState(
        icon: Icons.folder_off_rounded,
        title: 'Empty directory',
      );
    }

    return Column(
      children: [
        _PathHeader(path: FileManagerViewModel.root),
        const Divider(height: 1),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 4),
            children: rootChildren
                .map(
                  (node) => FileTreeNode(
                    node: node,
                    path: node.fullPath(FileManagerViewModel.root),
                    viewModel: _viewModel,
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _PathHeader extends StatelessWidget {
  const _PathHeader({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.storage_rounded, size: 14, color: cs.primary),
          const SizedBox(width: 6),
          Text(
            path,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: cs.onSurface.withAlpha(180),
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
