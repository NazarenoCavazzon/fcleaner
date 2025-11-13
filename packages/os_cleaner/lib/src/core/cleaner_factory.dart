import 'dart:io' show Platform;
import 'package:os_cleaner/src/platforms/platforms.dart';

Future<PlatformCleaner> createPlatformCleaner() async {
  if (Platform.isMacOS) return MacOSCleaner();
  throw UnsupportedError(
    'Unsupported IO platform: ${Platform.operatingSystem}',
  );
}
