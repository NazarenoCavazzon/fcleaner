import 'dart:io';

import 'package:fcleaner/shared/exceptions/cleanup_exceptions.dart';
import 'package:fcleaner/shared/models/system_info.dart';

class SystemCommandService {
  Future<ProcessResult> run(
    String command,
    List<String> args, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    try {
      return await Process.run(command, args).timeout(timeout);
    } catch (e, stackTrace) {
      throw CleanupException(
        'Failed to run command: $command ${args.join(" ")}',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<bool> requestSudo() async {
    try {
      final result = await Process.run('sudo', ['-v']);
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  Future<ProcessResult> runWithSudo(
    String command,
    List<String> args, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    try {
      return await Process.run(
        'sudo',
        [command, ...args],
      ).timeout(timeout);
    } catch (e, stackTrace) {
      throw CleanupException(
        'Failed to run command with sudo: $command ${args.join(" ")}',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<SystemInfo> getSystemInfo() async {
    try {
      final osVersion = await _getOSVersion();
      final architecture = await _getArchitecture();
      final homeDirectory = Platform.environment['HOME'] ?? '';
      final diskInfo = await _getDiskInfo();

      return SystemInfo(
        osVersion: osVersion,
        architecture: architecture,
        homeDirectory: homeDirectory,
        totalDiskSpace: diskInfo['total'] ?? 0,
        freeDiskSpace: diskInfo['free'] ?? 0,
      );
    } catch (e, stackTrace) {
      throw CleanupException(
        'Failed to get system info',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<String> _getOSVersion() async {
    try {
      final result = await Process.run('sw_vers', ['-productVersion']);
      if (result.exitCode == 0) {
        return result.stdout.toString().trim();
      }
      return 'Unknown';
    } catch (_) {
      return 'Unknown';
    }
  }

  Future<String> _getArchitecture() async {
    try {
      final result = await Process.run('uname', ['-m']);
      if (result.exitCode == 0) {
        return result.stdout.toString().trim();
      }
      return 'Unknown';
    } catch (_) {
      return 'Unknown';
    }
  }

  Future<Map<String, int>> _getDiskInfo() async {
    try {
      final result = await Process.run('df', ['-k', '/']);
      if (result.exitCode == 0) {
        final lines = result.stdout.toString().split('\n');
        if (lines.length > 1) {
          final parts = lines[1].split(RegExp(r'\s+'));
          if (parts.length >= 4) {
            final total = int.tryParse(parts[1]) ?? 0;
            final available = int.tryParse(parts[3]) ?? 0;

            return {
              'total': total * 1024,
              'free': available * 1024,
            };
          }
        }
      }
      return {'total': 0, 'free': 0};
    } catch (_) {
      return {'total': 0, 'free': 0};
    }
  }

  Future<bool> checkSudoAccess() async {
    try {
      final result = await Process.run('sudo', ['-n', 'true']);
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  Future<void> deleteWithSudo(String path) async {
    final result = await runWithSudo('rm', ['-rf', path]);
    if (result.exitCode != 0) {
      throw FileSystemException(
        path,
        'Failed to delete with sudo: ${result.stderr}',
      );
    }
  }

  Future<String> getHomeDirectory() async {
    return Platform.environment['HOME'] ?? '';
  }
}
