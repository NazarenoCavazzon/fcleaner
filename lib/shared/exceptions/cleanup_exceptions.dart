class CleanupException implements Exception {
  CleanupException(
    this.message, {
    this.originalError,
    this.stackTrace,
  });

  final String message;
  final dynamic originalError;
  final StackTrace? stackTrace;

  @override
  String toString() => 'CleanupException: $message';
}

class PermissionDeniedException extends CleanupException {
  PermissionDeniedException(this.path) : super('Permission denied: $path');

  final String path;
}

class SudoRequiredException extends CleanupException {
  SudoRequiredException(this.operation)
    : super('Sudo access required for: $operation');

  final String operation;
}

class UnsupportedPlatformException extends CleanupException {
  UnsupportedPlatformException(this.platform)
    : super('Platform not supported: $platform');

  final String platform;
}

class FileSystemException extends CleanupException {
  FileSystemException(this.path, String message)
    : super('File system error at $path: $message');
  final String path;
}

class WhitelistException extends CleanupException {
  WhitelistException(super.message);
}
