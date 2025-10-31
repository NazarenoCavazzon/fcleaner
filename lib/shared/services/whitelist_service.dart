import 'dart:io';
import 'package:fcleaner/shared/constants/cleanup_constants.dart';
import 'package:fcleaner/shared/exceptions/cleanup_exceptions.dart';

class WhitelistService {
  WhitelistService();

  final List<String> _patterns = [];
  bool _isLoaded = false;

  Future<void> loadWhitelist() async {
    if (_isLoaded) return;

    _patterns
      ..clear()
      ..addAll(CleanupConstants.defaultWhitelistPatterns);

    try {
      final configPath = _expandPath(CleanupConstants.configDirectory);
      final whitelistPath = '$configPath/${CleanupConstants.whitelistFileName}';
      final file = File(whitelistPath);

      if (file.existsSync()) {
        final lines = file.readAsLinesSync();

        for (final line in lines) {
          final trimmed = line.trim();

          if (trimmed.isEmpty || trimmed.startsWith('#')) {
            continue;
          }

          if (_isValidPattern(trimmed)) {
            _patterns.add(_expandPath(trimmed));
          }
        }
      }

      _isLoaded = true;
    } catch (e) {
      throw WhitelistException('Failed to load whitelist: $e');
    }
  }

  bool isWhitelisted(String path) {
    if (!_isLoaded) {
      throw WhitelistException(
        'Whitelist not loaded. Call loadWhitelist() first.',
      );
    }

    final expandedPath = _expandPath(path);

    for (final pattern in _patterns) {
      if (_matchesPattern(expandedPath, pattern)) {
        return true;
      }
    }

    return false;
  }

  Future<void> addToWhitelist(String pattern) async {
    if (!_isValidPattern(pattern)) {
      throw WhitelistException('Invalid whitelist pattern: $pattern');
    }

    final expandedPattern = _expandPath(pattern);

    if (!_patterns.contains(expandedPattern)) {
      _patterns.add(expandedPattern);
      await _saveWhitelist();
    }
  }

  Future<void> removeFromWhitelist(String pattern) async {
    final expandedPattern = _expandPath(pattern);
    _patterns.remove(expandedPattern);
    await _saveWhitelist();
  }

  List<String> getWhitelistPatterns() {
    return List.unmodifiable(_patterns);
  }

  List<String> getCustomPatterns() {
    return _patterns
        .where((p) => !CleanupConstants.defaultWhitelistPatterns.contains(p))
        .toList();
  }

  Future<void> _saveWhitelist() async {
    try {
      final configPath = _expandPath(CleanupConstants.configDirectory);
      final configDir = Directory(configPath);

      if (!configDir.existsSync()) {
        await configDir.create(recursive: true);
      }

      final whitelistPath = '$configPath/${CleanupConstants.whitelistFileName}';
      final file = File(whitelistPath);

      final customPatterns = getCustomPatterns();
      final lines = [
        '# FCleaner Whitelist Configuration',
        '# Add patterns to protect files/directories from cleanup',
        '# Supports glob patterns: *, ?, [abc]',
        '# Lines starting with # are comments',
        '',
        ...customPatterns,
      ];

      await file.writeAsString(lines.join('\n'));
    } catch (e) {
      throw WhitelistException('Failed to save whitelist: $e');
    }
  }

  bool _matchesPattern(String path, String pattern) {
    if (pattern.contains('*') || pattern.contains('?')) {
      final regexPattern = pattern
          .replaceAll('.', r'\.')
          .replaceAll('*', '.*')
          .replaceAll('?', '.');

      try {
        return RegExp('^$regexPattern').hasMatch(path);
      } catch (_) {
        return path == pattern;
      }
    }

    return path.startsWith(pattern) || path == pattern;
  }

  bool _isValidPattern(String pattern) {
    if (pattern.isEmpty) return false;

    final expandedPattern = _expandPath(pattern);

    if (expandedPattern.startsWith('/System/') ||
        expandedPattern.startsWith('/bin/') ||
        expandedPattern.startsWith('/sbin/') ||
        expandedPattern.startsWith('/usr/bin/') ||
        expandedPattern.startsWith('/usr/sbin/')) {
      return false;
    }

    final validChars = RegExp(r'^[a-zA-Z0-9/_.\*\?~\[\] @-]+$');
    return validChars.hasMatch(expandedPattern);
  }

  String _expandPath(String path) {
    if (path.startsWith('~')) {
      final home = Platform.environment['HOME'] ?? '';
      return path.replaceFirst('~', home);
    }
    return path;
  }

  Future<void> reset() async {
    _patterns
      ..clear()
      ..addAll(CleanupConstants.defaultWhitelistPatterns);
    await _saveWhitelist();
  }
}
