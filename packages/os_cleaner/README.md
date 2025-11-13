# OS Cleaner

[![style: very good analysis][very_good_analysis_badge]][very_good_analysis_link]
[![License: MIT][license_badge]][license_link]

A platform-aware system cleaning package for Flutter applications. Provides unified APIs for system cleanup, app uninstallation, and disk analysis across different operating systems.

## Features ✨

- **System Cleanup**: Scan and clean 12+ categories of system files (caches, logs, temporary files, etc.)
- **App Uninstaller**: Detect installed applications and remove them with all related files
- **Disk Analyzer**: Analyze disk usage with configurable depth and find large files
- **Whitelist Management**: Protect important files and directories from cleanup
- **Platform-Aware**: Automatically selects the correct implementation based on OS
- **Type-Safe**: Strong typing with domain models throughout
- **Streaming Support**: Real-time progress updates for long-running operations

## Platform Support

- ✅ **macOS** (arm64 and x86_64)
- ⏳ **Windows** (architecture ready)
- ⏳ **Linux** (architecture ready)

---

## Installation 💻

Add to your `pubspec.yaml`:

```yaml
dependencies:
  os_cleaner:
    path: packages/os_cleaner
```

---

## Usage 🚀

### Basic Setup

```dart
import 'package:os_cleaner/os_cleaner.dart';

void main() {
  final osCleaner = OsCleaner();
  
  // Use the unified API
}
```

### System Cleanup

```dart
// Analyze system
final analysis = await osCleaner.analyzeCleanup();
print('Found ${analysis.totalItems} items');
print('Total size: ${ByteFormatter.format(analysis.totalSize)}');

// Perform cleanup
final result = await osCleaner.performCleanupSync(
  analysis: analysis,
  categoryIds: ['system_essentials', 'browsers'],
);

print('Cleaned ${result.itemsCleaned} items');
print('Freed ${ByteFormatter.format(result.bytesFreed)}');
```

### App Uninstaller

```dart
// Get installed apps
final apps = await osCleaner.getInstalledApps();

// Uninstall an app
final result = await osCleaner.uninstallAppSync(apps.first);
print('Uninstalled ${result.appName}');
```

### Disk Analysis

```dart
// Analyze a directory
final diskItem = await osCleaner.analyzeDiskSync(
  '/Users/you/Documents',
  maxDepth: 3,
);

// Find large files
final largeFiles = await osCleaner.findLargeFiles(
  '/Users/you',
  minSizeInMB: 100,
);
```

### Whitelist Management

```dart
// Add to whitelist
await osCleaner.addToWhitelist('~/my-important-cache/*');

// Get patterns
final patterns = osCleaner.getWhitelistPatterns();

// Reset to defaults
await osCleaner.resetWhitelist();
```

---

## Architecture 🏗️

The package follows a layered architecture:

- **Domain Layer**: Models, repository interfaces, utilities
- **Application Layer**: Service orchestrators
- **Infrastructure Layer**: Platform-specific implementations
- **Public API**: Unified `OsCleaner` façade

See [BACKEND_README.md](../../BACKEND_README.md) for detailed architecture documentation.

---

## Running Tests 🧪

```sh
dart test --coverage=coverage
```

---

## Contributing 🤝

Contributions are welcome! To add support for a new platform:

1. Create platform-specific repository implementations in `lib/src/infrastructure/<platform>/`
2. Update `PlatformResolver` to detect and wire the new platform
3. Add tests for the new implementation

---

## License 📄

MIT License

[license_badge]: https://img.shields.io/badge/license-MIT-blue.svg
[license_link]: https://opensource.org/licenses/MIT
[very_good_analysis_badge]: https://img.shields.io/badge/style-very_good_analysis-B22C89.svg
[very_good_analysis_link]: https://pub.dev/packages/very_good_analysis
