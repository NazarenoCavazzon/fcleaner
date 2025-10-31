import 'dart:io';

import 'package:fcleaner/disk_analyzer/models/disk_item.dart';
import 'package:fcleaner/shared/services/file_system_service.dart';

class MacOSDiskDatasource {
  MacOSDiskDatasource(this._fileSystemService);

  final FileSystemService _fileSystemService;

  Stream<DiskItem> analyzePath(
    String path, {
    int maxDepth = 3,
    void Function(double)? onProgress,
  }) async* {
    try {
      final rootItem = await _analyzePathRecursive(path, maxDepth, 0);
      if (rootItem != null) {
        yield rootItem;
      }
    } catch (_) {}
  }

  Future<DiskItem?> _analyzePathRecursive(
    String path,
    int maxDepth,
    int currentDepth,
  ) async {
    try {
      if (currentDepth > maxDepth) {
        return null;
      }

      final isDir = await _fileSystemService.isDirectory(path);
      final isFile = await _fileSystemService.isFile(path);

      if (!isDir && !isFile) {
        return DiskItem(
          path: path,
          name: _fileSystemService.getFileName(path),
          sizeBytes: 0,
          type: DiskItemType.symlink,
        );
      }

      if (isFile) {
        final size = await _fileSystemService.calculateSize(path);
        return DiskItem(
          path: path,
          name: _fileSystemService.getFileName(path),
          sizeBytes: size,
          type: DiskItemType.file,
        );
      }

      final children = <DiskItem>[];
      final dir = Directory(path);

      if (!dir.existsSync()) {
        return null;
      }

      await for (final entity in dir.list(followLinks: false)) {
        if (_shouldSkip(entity.path)) {
          continue;
        }

        try {
          final child = await _analyzePathRecursive(
            entity.path,
            maxDepth,
            currentDepth + 1,
          );

          if (child != null && child.sizeBytes > 0) {
            children.add(child);
          }
        } catch (_) {}
      }

      children.sort((a, b) => b.sizeBytes.compareTo(a.sizeBytes));

      final totalSize = children.fold<int>(
        0,
        (sum, child) => sum + child.sizeBytes,
      );

      return DiskItem(
        path: path,
        name: _fileSystemService.getFileName(path),
        sizeBytes: totalSize,
        type: DiskItemType.directory,
        children: children,
      );
    } catch (_) {
      return null;
    }
  }

  Future<DiskItem?> analyzePathSync(
    String path, {
    int maxDepth = 3,
  }) async {
    return _analyzePathRecursive(path, maxDepth, 0);
  }

  bool _shouldSkip(String path) {
    final skipPatterns = [
      '.Trash',
      'node_modules',
      '.git',
      '.svn',
      'System',
      'Library/Logs',
      'Volumes',
    ];

    for (final pattern in skipPatterns) {
      if (path.contains(pattern)) {
        return true;
      }
    }

    return false;
  }

  Future<List<DiskItem>> getTopLargestItems(
    String path, {
    int limit = 10,
  }) async {
    final rootItem = await analyzePathSync(path, maxDepth: 2);

    if (rootItem == null || rootItem.children == null) {
      return [];
    }

    final allItems = <DiskItem>[];
    _flattenItems(rootItem, allItems);

    allItems.sort((a, b) => b.sizeBytes.compareTo(a.sizeBytes));

    return allItems.take(limit).toList();
  }

  void _flattenItems(DiskItem item, List<DiskItem> result) {
    result.add(item);

    if (item.children != null) {
      for (final child in item.children!) {
        _flattenItems(child, result);
      }
    }
  }
}
