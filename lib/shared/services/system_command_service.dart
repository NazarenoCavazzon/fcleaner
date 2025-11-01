import 'dart:io';

import 'package:disk_usage/disk_usage.dart';
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
      final results = await Future.wait([
        _getOSVersion(),
        _getArchitecture(),
        _getDiskInfo(),
      ]);

      return SystemInfo(
        osVersion: results[0] as String,
        architecture: results[1] as String,
        homeDirectory: Platform.environment['HOME'] ?? '',
        totalDiskSpace: (results[2] as Map<String, int>)['total'] ?? 0,
        freeDiskSpace: (results[2] as Map<String, int>)['free'] ?? 0,
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
      final totalSpace = await DiskUsage.space(DiskSpaceType.total);
      final freeSpace = await DiskUsage.space(DiskSpaceType.free);

      return {'total': totalSpace ?? 0, 'free': freeSpace ?? 0};
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
