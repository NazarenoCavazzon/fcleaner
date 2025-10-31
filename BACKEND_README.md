# FCleaner Backend Implementation

## Overview

A complete backend implementation for a macOS system cleaner inspired by Mole and CCleaner. Built with Flutter using a pragmatic, feature-first layered architecture.

## Architecture

### Feature-First Layered Architecture

```
lib/
├── shared/              # Cross-feature utilities
│   ├── models/         # SystemInfo, CleanupProgress
│   ├── services/       # FileSystem, SystemCommand, Whitelist
│   ├── utils/          # ByteFormatter
│   ├── constants/      # Configuration
│   └── exceptions/     # Custom exceptions
│
├── cleanup/            # System Cleanup Feature
│   ├── models/        # CleanupItem, CleanupCategory, AnalysisResult, CleanupResult
│   └── data/          # CleanupService, MacOSCleanupDatasource
│
├── uninstall/         # App Uninstaller Feature
│   ├── models/        # AppInfo, UninstallResult
│   └── data/          # UninstallService, MacOSUninstallDatasource
│
├── disk_analyzer/     # Disk Space Analyzer Feature
│   ├── models/        # DiskItem
│   └── data/          # DiskAnalyzerService, MacOSDiskDatasource
│
└── app/               # Application-wide
    └── service_provider.dart  # Dependency injection
```

## Features Implemented

### 1. System Cleanup (12 Categories)

Based on Mole's comprehensive cleanup approach:

1. **System Essentials** - Caches, logs, trash, crash reports
2. **macOS System Caches** - Spotlight, fonts, photo analysis
3. **Sandboxed Apps** - Container caches
4. **Browsers** - Safari, Chrome, Firefox, Arc, Brave, Edge, Opera, Vivaldi
5. **Cloud Storage** - Dropbox, Google Drive, OneDrive, Box
6. **Office Applications** - MS Office, iWork, Mail, Thunderbird
7. **Developer Tools** - npm, yarn, pip, go, docker, homebrew
8. **Extended Developer Tools** - Xcode, Android Studio, VS Code, JetBrains, Python tools
9. **Applications** - Discord, Slack, Spotify, Steam, and 40+ more apps
10. **Virtualization** - VMware, Parallels, VirtualBox, Vagrant
11. **Orphaned Data** - Leftover files from uninstalled apps (60+ days inactive)
12. **Apple Silicon** - Rosetta 2 caches (M-series Macs only)

**Key Features:**
- Smart whitelist system (protects Playwright, HuggingFace, Maven, Ollama by default)
- Parallel file scanning (up to 15 concurrent operations)
- Real-time progress tracking via Dart Streams
- Graceful error handling (continues on errors)

### 2. App Uninstaller

Comprehensive app removal scanning 22+ locations:

**Scanned Locations:**
- ~/Library/Preferences
- ~/Library/Application Support
- ~/Library/Caches
- ~/Library/Logs
- ~/Library/WebKit
- ~/Library/HTTPStorages
- ~/Library/Cookies
- ~/Library/Saved Application State
- ~/Library/Containers
- ~/Library/Group Containers
- ~/Library/LaunchAgents
- ~/Library/Application Scripts
- And 10+ more...

**Features:**
- Reads app bundle IDs from Info.plist
- Calculates total size including related files
- Safe app removal (moves to Trash using macOS APIs)
- Tracks install dates

### 3. Disk Space Analyzer

Recursive directory analysis with configurable depth:

**Features:**
- Builds tree structure of directories/files
- Sorts by size (largest first)
- Configurable max depth to avoid long scans
- Skip patterns (node_modules, .git, System, etc.)
- Find large files (configurable size threshold)
- Get top N largest items

## Usage

### Initialization

```dart
import 'package:fcleaner/app/service_provider.dart';

void main() {
  final serviceProvider = ServiceProvider();
  serviceProvider.initialize();
  
  // Access services
  final cleanupService = serviceProvider.cleanupService;
  final uninstallService = serviceProvider.uninstallService;
  final diskAnalyzerService = serviceProvider.diskAnalyzerService;
}
```

### Cleanup Service

```dart
// Analyze system
final analysisResult = await cleanupService.analyzeSystem();

print('Found ${analysisResult.totalItems} items in ${analysisResult.categoryCount} categories');
print('Total reclaimable space: ${analysisResult.totalSize} bytes');

// Perform cleanup with progress tracking
final categoryIds = ['system_essentials', 'browsers'];
await for (final progress in cleanupService.performCleanup(
  categoryIds,
  analysisResult.categories,
)) {
  print('${progress.progressPercentage}% - ${progress.currentItem}');
  print('Freed: ${progress.bytesFreed} bytes');
}

// Or perform sync cleanup
final result = await cleanupService.performCleanupSync(
  categoryIds,
  analysisResult.categories,
);

print('Success: ${result.success}');
print('Cleaned: ${result.itemsCleaned} items');
print('Freed: ${result.bytesFreed} bytes');
print('Duration: ${result.duration}');
```

### Uninstall Service

```dart
// Get installed apps
final apps = await uninstallService.getInstalledApps();

print('Found ${apps.length} apps');

for (final app in apps) {
  print('${app.name}: ${app.displaySize}');
  print('Bundle ID: ${app.bundleId}');
  print('Related files: ${app.relatedFilesCount}');
}

// Uninstall an app with progress
await for (final progress in uninstallService.uninstallApp(apps.first)) {
  print('${progress.progressPercentage}% - ${progress.currentItem}');
}

// Or uninstall synchronously
final result = await uninstallService.uninstallAppSync(apps.first);

print('Uninstalled: ${result.appName}');
print('Freed: ${result.bytesFreed} bytes');
print('Files removed: ${result.filesRemoved}');
```

### Disk Analyzer Service

```dart
// Analyze a directory
final diskItem = await diskAnalyzerService.analyzePathSync(
  '/Users/you/Documents',
  maxDepth: 3,
);

print('${diskItem.name}: ${diskItem.displaySize}');
print('Type: ${diskItem.type}');
print('Children: ${diskItem.childCount}');

// Navigate the tree
for (final child in diskItem.sortedChildren) {
  print('  ${child.name}: ${child.displaySize}');
}

// Find large files (>100MB)
final largeFiles = await diskAnalyzerService.findLargeFiles(
  '/Users/you',
  minSizeInMB: 100,
  maxDepth: 3,
);

print('Found ${largeFiles.length} large files');

// Get top 10 largest items
final topItems = await diskAnalyzerService.getTopLargestItems(
  '/Users/you',
  limit: 10,
);
```

### Whitelist Management

```dart
final whitelistService = serviceProvider.whitelistService;

// Load whitelist
await whitelistService.loadWhitelist();

// Check if path is whitelisted
if (whitelistService.isWhitelisted('/path/to/check')) {
  print('Path is protected');
}

// Add custom pattern
await whitelistService.addToWhitelist('~/my-important-cache/*');

// Get all patterns
final patterns = whitelistService.getWhitelistPatterns();

// Get only custom patterns (excludes defaults)
final customPatterns = whitelistService.getCustomPatterns();

// Reset to defaults
await whitelistService.reset();
```

## Configuration

Edit `lib/shared/constants/cleanup_constants.dart`:

```dart
class CleanupConstants {
  // Default protected patterns
  static const defaultWhitelistPatterns = [
    '~/Library/Caches/ms-playwright*',
    '~/.cache/huggingface*',
    '~/.m2/repository/*',
    '~/.ollama/models/*',
  ];
  
  // Age thresholds
  static const tempFileAgeDays = 7;
  static const orphanDataAgeDays = 60;
  
  // Performance
  static const maxParallelJobs = 15;
  
  // Config location
  static const configDirectory = '~/.config/fcleaner';
  static const whitelistFileName = 'whitelist';
}
```

## Error Handling

All operations are wrapped in try-catch blocks and continue on errors:

```dart
final result = await cleanupService.performCleanupSync(categoryIds, categories);

if (result.hasErrors) {
  print('Encountered ${result.errors.length} errors:');
  for (final error in result.errors) {
    print('  - $error');
  }
}

if (result.isPartialSuccess) {
  print('Partial success: cleaned ${result.itemsCleaned} items despite errors');
}
```

## Dependencies

Add to `pubspec.yaml`:

```yaml
dependencies:
  path: ^1.9.0  # Path manipulation
```

## Platform Support

Currently supports:
- ✅ macOS (arm64 and x86_64)

Future support:
- ⏳ Windows (architecture ready, needs WindowsCleanupDatasource)
- ⏳ Linux (architecture ready, needs LinuxCleanupDatasource)

## Performance Optimizations

1. **Parallel scanning**: Up to 15 concurrent file operations
2. **Lazy loading**: Category details loaded on demand
3. **Caching**: Size calculations cached where appropriate
4. **Streaming**: Real-time progress updates via Dart Streams
5. **Skip patterns**: Avoids scanning system-protected directories

## Safety Features

1. **Whitelist system**: Protects important caches by default
2. **Age thresholds**: Only cleans old temporary files (7+ days) and orphaned data (60+ days)
3. **Graceful errors**: Continues cleanup even if some items fail
4. **System protection**: Skips critical system paths
5. **Trash support**: Apps moved to Trash (not permanently deleted)

## Testing

See `lib/examples/service_usage_example.dart` for complete usage examples.

## Next Steps

For UI implementation, you'll want to:

1. Create Bloc/Cubit for state management
2. Build UI screens for each feature
3. Add progress indicators and animations
4. Implement settings screen for whitelist management
5. Add system tray integration
6. Package as macOS app bundle

## Architecture Benefits

✅ **Simple**: No over-abstraction, easy to understand
✅ **Flutter-idiomatic**: Feature-first organization
✅ **Pragmatic**: Concrete services, not abstract interfaces
✅ **Maintainable**: Clear separation of concerns
✅ **Extensible**: Easy to add new platforms or features
✅ **Testable**: Services can be mocked where needed

## File Count

- Total: 22 files
- Shared: 8 files
- Cleanup: 6 files
- Uninstall: 4 files
- Disk Analyzer: 3 files
- App: 1 file

