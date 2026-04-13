class FileListResponse {
  final String path;
  final List<FileNode> entries;

  FileListResponse({required this.path, required this.entries});

  factory FileListResponse.fromJson(Map<String, dynamic> json) {
    return FileListResponse(
      path: json['path'] as String,
      entries: (json['entries'] as List<dynamic>)
          .map((e) => FileNode.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class FileNode {
  final String name;
  final String permissions;
  final bool isDir;
  final bool isSymlink;
  final String owner;
  final String group;
  final int size;
  final String modifiedAt;
  final String? symlinkTarget;

  FileNode({
    required this.name,
    required this.permissions,
    required this.isDir,
    required this.isSymlink,
    required this.owner,
    required this.group,
    required this.size,
    required this.modifiedAt,
    required this.symlinkTarget,
  });

  factory FileNode.fromJson(Map<String, dynamic> json) {
    return FileNode(
      name: json['name'] as String,
      permissions: json['permissions'] as String,
      isDir: json['is_dir'] as bool,
      isSymlink: json['is_symlink'] as bool,
      owner: json['owner'] as String,
      group: json['group'] as String,
      size: json['size'] as int,
      modifiedAt: json['modified_at'] as String,
      symlinkTarget: json['symlink_target'] as String?,
    );
  }

  String fullPath(String parentPath) =>
      '$parentPath$name${isDir ? '/' : ''}';

  String get formattedSize {
    if (isDir) return '—';
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    if (size < 1024 * 1024 * 1024) {
      return '${(size / 1024 / 1024).toStringAsFixed(1)} MB';
    }
    return '${(size / 1024 / 1024 / 1024).toStringAsFixed(1)} GB';
  }
}
