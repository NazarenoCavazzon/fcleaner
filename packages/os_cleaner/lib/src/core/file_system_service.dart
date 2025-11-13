import 'dart:io';

import 'package:path/path.dart' as p;

class FileSystemService {
  static int calculateSize(String path) {
    try {
      final type = _safeTypeOf(path);

      if (type == FileSystemEntityType.notFound) return 0;

      if (type == FileSystemEntityType.file) {
        return File(path).lengthSync();
      }

      if (type == FileSystemEntityType.directory) {
        var totalSize = 0;

        for (final entity in Directory(path).listSync(
          recursive: true,
          followLinks: false,
        )) {
          if (entity is File) {
            try {
              totalSize += entity.lengthSync();
            } catch (_) {}
          }
        }

        return totalSize;
      }

      return 0;
    } catch (_) {
      return 0;
    }
  }

  static bool exists(String path) =>
      _safeTypeOf(path) != FileSystemEntityType.notFound;

  static void delete(String path) {
    final type = _safeTypeOf(path);

    if (type == FileSystemEntityType.notFound) return;

    try {
      if (type == FileSystemEntityType.file) {
        File(path).deleteSync();
      } else if (type == FileSystemEntityType.directory) {
        Directory(path).deleteSync(recursive: true);
      } else if (type == FileSystemEntityType.link) {
        Link(path).deleteSync();
      }
    } catch (e) {
      throw FileSystemException(
        path,
        'Failed to delete: $e',
      );
    }
  }

  static List<String> findFiles(String pattern) {
    try {
      final expandedPattern = expandPath(pattern);

      if (!_hasWildcards(expandedPattern)) {
        return exists(expandedPattern) ? [expandedPattern] : <String>[];
      }

      final directory = p.dirname(expandedPattern);
      final filePattern = p.basename(expandedPattern);

      final dir = Directory(directory);
      if (!dir.existsSync()) {
        return <String>[];
      }

      final matches = <String>[];
      for (final entity in dir.listSync(followLinks: false)) {
        final baseName = p.basename(entity.path);
        if (_matchesSimpleGlob(baseName, filePattern)) {
          matches.add(entity.path);
        }
      }

      return matches;
    } catch (_) {
      return <String>[];
    }
  }

  static bool _hasWildcards(String pattern) =>
      pattern.contains('*') || pattern.contains('?');

  static bool _matchesSimpleGlob(String text, String pattern) {
    if (!_hasWildcards(pattern)) {
      final caseSensitive = !(Platform.isWindows || Platform.isMacOS);
      return caseSensitive
          ? text == pattern
          : text.toLowerCase() == pattern.toLowerCase();
    }

    final regexPattern = RegExp.escape(
      pattern,
    ).replaceAll(r'\*', '.*').replaceAll(r'\?', '.');

    final caseSensitive = !(Platform.isWindows || Platform.isMacOS);

    return RegExp(
      '^$regexPattern\$',
      caseSensitive: caseSensitive,
    ).hasMatch(text);
  }

  static Stream<FileSystemEntity> listDirectory(
    String path, {
    bool recursive = false,
    bool followLinks = false,
  }) {
    try {
      final dir = Directory(path);
      if (!dir.existsSync()) {
        return const Stream<FileSystemEntity>.empty();
      }

      return dir
          .list(recursive: recursive, followLinks: followLinks)
          .handleError((_) {});
    } catch (_) {
      return const Stream<FileSystemEntity>.empty();
    }
  }

  static DateTime? getLastModified(String path) {
    try {
      final type = _safeTypeOf(path);

      if (type == FileSystemEntityType.file) {
        return File(path).lastModifiedSync();
      }

      if (type == FileSystemEntityType.directory) {
        return Directory(path).statSync().modified;
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<List<String>> listDirectoryPaths(
    String path, {
    bool recursive = false,
  }) async {
    final entities = await listDirectory(path, recursive: recursive).toList();
    return entities.map((e) => e.path).toList();
  }

  static String expandPath(String path) {
    if (!path.startsWith('~')) return path;

    final home =
        Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];

    if (home == null || home.isEmpty) {
      return path;
    }

    return path.replaceFirst('~', home);
  }

  static String getFileName(String path) => p.basename(path);

  static String getDirectoryName(String path) => p.dirname(path);

  static Future<bool> isDirectory(String path) async =>
      _safeTypeOf(path) == FileSystemEntityType.directory;

  static Future<bool> isFile(String path) async =>
      _safeTypeOf(path) == FileSystemEntityType.file;

  static FileSystemEntityType _safeTypeOf(String path) {
    try {
      return FileSystemEntity.typeSync(path);
    } catch (_) {
      return FileSystemEntityType.notFound;
    }
  }
}
