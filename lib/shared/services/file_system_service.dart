import 'dart:io';

import 'package:fcleaner/shared/exceptions/cleanup_exceptions.dart';
import 'package:path/path.dart' as p;

class FileSystemService {
  Future<int> calculateSize(String path) async {
    try {
      final entity = FileSystemEntity.typeSync(path);

      if (entity == FileSystemEntityType.notFound) {
        return 0;
      }

      if (entity == FileSystemEntityType.file) {
        final file = File(path);
        return await file.length();
      }

      if (entity == FileSystemEntityType.directory) {
        var totalSize = 0;
        final dir = Directory(path);

        await for (final entity in dir.list(
          recursive: true,
          followLinks: false,
        )) {
          if (entity is File) {
            try {
              totalSize += await entity.length();
            } catch (_) {}
          }
        }
        return totalSize;
      }

      return 0;
    } catch (e) {
      return 0;
    }
  }

  bool exists(String path) {
    try {
      return FileSystemEntity.typeSync(path) != FileSystemEntityType.notFound;
    } catch (_) {
      return false;
    }
  }

  Future<void> delete(String path) async {
    try {
      final entity = FileSystemEntity.typeSync(path);

      if (entity == FileSystemEntityType.notFound) {
        return;
      }

      if (entity == FileSystemEntityType.file) {
        File(path).deleteSync();
      } else if (entity == FileSystemEntityType.directory) {
        Directory(path).deleteSync(recursive: true);
      } else if (entity == FileSystemEntityType.link) {
        Link(path).deleteSync();
      }
    } catch (e) {
      throw FileSystemException(
        path,
        'Failed to delete: $e',
      );
    }
  }

  Future<List<String>> findFiles(String pattern) async {
    try {
      final expandedPattern = _expandPath(pattern);

      if (!expandedPattern.contains('*') && !expandedPattern.contains('?')) {
        if (exists(expandedPattern)) {
          return [expandedPattern];
        }
        return [];
      }

      final lastSlashIndex = expandedPattern.lastIndexOf('/');
      final directory = expandedPattern.substring(0, lastSlashIndex);
      final filePattern = expandedPattern.substring(lastSlashIndex + 1);

      final dir = Directory(directory);
      if (!dir.existsSync()) {
        return [];
      }

      final matches = <String>[];
      for (final entity in dir.listSync(followLinks: false)) {
        final baseName = p.basename(entity.path);
        if (_matchesSimpleGlob(baseName, filePattern)) {
          matches.add(entity.path);
        }
      }

      return matches;
    } catch (e) {
      return [];
    }
  }

  bool _matchesSimpleGlob(String text, String pattern) {
    if (!pattern.contains('*') && !pattern.contains('?')) {
      return text == pattern;
    }

    final regexPattern = pattern
        .replaceAll('.', r'\.')
        .replaceAll('*', '.*')
        .replaceAll('?', '.');

    return RegExp('^$regexPattern\$').hasMatch(text);
  }

  Stream<FileSystemEntity> listDirectory(
    String path, {
    bool recursive = false,
    bool followLinks = false,
  }) async* {
    try {
      final dir = Directory(path);
      if (!dir.existsSync()) {
        return;
      }

      for (final entity in dir.listSync(
        recursive: recursive,
        followLinks: followLinks,
      )) {
        yield entity;
      }
    } catch (_) {}
  }

  Future<DateTime?> getLastModified(String path) async {
    try {
      final entity = FileSystemEntity.typeSync(path);

      if (entity == FileSystemEntityType.file) {
        return File(path).lastModifiedSync();
      } else if (entity == FileSystemEntityType.directory) {
        return Directory(path).statSync().modified;
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  Future<List<String>> listDirectoryPaths(
    String path, {
    bool recursive = false,
  }) async {
    final paths = <String>[];

    await for (final entity in listDirectory(path, recursive: recursive)) {
      paths.add(entity.path);
    }

    return paths;
  }

  String _expandPath(String path) {
    if (path.startsWith('~')) {
      final home = Platform.environment['HOME'] ?? '';
      return path.replaceFirst('~', home);
    }
    return path;
  }

  String expandPath(String path) => _expandPath(path);

  String getFileName(String path) => p.basename(path);

  String getDirectoryName(String path) => p.dirname(path);

  Future<bool> isDirectory(String path) async {
    try {
      return FileSystemEntity.typeSync(path) == FileSystemEntityType.directory;
    } catch (_) {
      return false;
    }
  }

  Future<bool> isFile(String path) async {
    try {
      return FileSystemEntity.typeSync(path) == FileSystemEntityType.file;
    } catch (_) {
      return false;
    }
  }
}
