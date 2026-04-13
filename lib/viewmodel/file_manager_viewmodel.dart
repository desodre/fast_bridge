import 'package:fast_bridge_front/data/models/file_node.dart';
import 'package:fast_bridge_front/data/repositories/device_repository.dart';
import 'package:flutter/foundation.dart';

class FileManagerViewModel {
  final String serial;
  final DeviceRepository _repository = DeviceRepository();

  static const String root = 'sdcard/';

  FileManagerViewModel({required this.serial});

  // cache: path → children
  final ValueNotifier<Map<String, List<FileNode>>> cache = ValueNotifier({});
  // paths currently expanded
  final ValueNotifier<Set<String>> expanded = ValueNotifier({});
  // paths currently loading
  final ValueNotifier<Set<String>> loading = ValueNotifier({});
  final ValueNotifier<String> erro = ValueNotifier('');

  Future<void> init() => _toggleExpand(root);

  Future<void> toggle(String path) => _toggleExpand(path);

  bool isExpanded(String path) => expanded.value.contains(path);

  bool isLoading(String path) => loading.value.contains(path);

  List<FileNode>? childrenOf(String path) => cache.value[path];

  Future<void> _toggleExpand(String path) async {
    if (isExpanded(path)) {
      expanded.value = {...expanded.value}..remove(path);
      return;
    }

    if (!cache.value.containsKey(path)) {
      await _load(path);
    }

    expanded.value = {...expanded.value, path};
  }

  Future<void> _load(String path) async {
    loading.value = {...loading.value, path};
    erro.value = '';
    try {
      final response = await _repository.listFiles(
        serial: serial,
        path: path,
      );
      // dirs first, then files, both sorted alphabetically
      final sorted = [...response.entries]..sort((a, b) {
          if (a.isDir == b.isDir) return a.name.compareTo(b.name);
          return a.isDir ? -1 : 1;
        });
      cache.value = {...cache.value, path: sorted};
    } catch (e) {
      erro.value = e.toString();
    } finally {
      loading.value = {...loading.value}..remove(path);
    }
  }

  void dispose() {
    cache.dispose();
    expanded.dispose();
    loading.dispose();
    erro.dispose();
  }
}
