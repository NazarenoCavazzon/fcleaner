import 'package:fcleaner/app/service_provider.dart';
import 'package:fcleaner/shared/utils/byte_formatter.dart';

Future<void> main() async {
  final serviceProvider = ServiceProvider()..initialize();

  // await cleanupExample(serviceProvider);
  await uninstallExample(serviceProvider);
  // await diskAnalyzerExample(serviceProvider);
}

Future<void> cleanupExample(ServiceProvider sp) async {
  print('=== CLEANUP EXAMPLE ===\n');

  final cleanupService = sp.cleanupService;

  // Step 1: Analyze system (discover what CAN be cleaned)
  print('Analyzing system...');
  final analysis = await cleanupService.analyzeSystem();

  print('Analysis complete!');
  print('Total categories: ${analysis.categoryCount}');
  print('Total items found: ${analysis.totalItems}');
  print(
    'Total potential savings: ${ByteFormatter.format(analysis.totalSize)}\n',
  );

  print('Categories found:');
  for (final category in analysis.nonEmptyCategories) {
    print(
      '  ${category.name}: ${category.itemCount} items (${ByteFormatter.format(category.totalSize)})',
    );
  }

  // Step 2: Select categories to clean
  print('\n--- CLEANUP PREVIEW ---');
  final selectedCategories = analysis.categories
      .map((c) => c.id)
      .take(30)
      .toList();
  print('Selected categories: ${selectedCategories.join(", ")}\n');

  // Step 3: Get preview of what WILL be deleted
  final preview = analysis.getPreview(selectedCategories);

  print('${preview.summary}');
  print('Requires sudo: ${preview.requiresSudo}');
  print('Categories to clean: ${preview.categoryCount}\n');

  // Show detailed breakdown
  print('Detailed breakdown:');
  for (final categoryPreview in preview.categoriesBySize) {
    print(
      '${categoryPreview.categoryName}: ${categoryPreview.itemCount} items (${categoryPreview.displaySize})',
    );

    // Show top 3 largest items as examples
    final topItems = categoryPreview.topItems(30);
    for (final item in topItems) {
      print('  - ${item.name} (${ByteFormatter.format(item.sizeBytes)})');
    }

    if (categoryPreview.itemCount > 3) {
      print('  ... and ${categoryPreview.itemCount - 3} more items');
    }
    print('');
  }

  // // Step 4: Perform cleanup (dry run first)
  // print('--- DRY RUN CLEANUP ---');
  // var result = await cleanupService.performCleanupSync(
  //   analysis: analysis,
  //   categoryIds: selectedCategories,
  //   dryRun: true,
  // );

  // print('Dry run complete!');
  // print('Would delete: ${result.itemsCleaned} items');
  // print('Would free: ${ByteFormatter.format(result.bytesFreed)}');
  // print('Duration: ${result.duration.inMilliseconds}ms\n');

  // Step 5: Perform actual cleanup (commented out for safety)
  // print('--- ACTUAL CLEANUP ---');
  // if (preview.requiresSudo) {
  //   final sudoGranted = await cleanupService.requestSudoIfNeeded(
  //     analysis,
  //     selectedCategories,
  //   );
  //   print('Sudo access: ${sudoGranted ? "granted" : "denied"}');
  // }
  //
  // result = await cleanupService.performCleanupSync(
  //   analysis: analysis,
  //   categoryIds: selectedCategories,
  //   dryRun: false,
  // );
  //
  // print('Cleanup complete!');
  // print('Deleted: ${result.itemsCleaned} items');
  // print('Freed: ${ByteFormatter.format(result.bytesFreed)}');
  // print('Duration: ${result.duration}');
  //
  // if (result.hasErrors) {
  //   print('\nEncountered ${result.errors.length} errors:');
  //   for (final error in result.errors.take(5)) {
  //     print('  - $error');
  //   }
  // }

  print('Cleanup example complete!\n');
}

Future<void> uninstallExample(ServiceProvider sp) async {
  print('=== UNINSTALL EXAMPLE ===\n');

  final uninstallService = sp.uninstallService;

  print('Scanning installed apps...');
  final apps = await uninstallService.getInstalledApps();

  print('Found ${apps.length} apps\n');

  if (apps.isNotEmpty) {
    print('Top 5 largest apps:');
    for (final app in apps.take(5)) {
      print(
        '${app.name}: ${app.displaySize} (${app.relatedFilesCount} related files)',
      );
    }
  }

  print('\nUninstall example complete!\n');
}

Future<void> diskAnalyzerExample(ServiceProvider sp) async {
  print('=== DISK ANALYZER EXAMPLE ===\n');

  final diskAnalyzerService = sp.diskAnalyzerService;
  final homeDir = sp.systemCommandService.getHomeDirectory();

  print('Analyzing home directory...');
  final diskItem = await diskAnalyzerService.analyzePathSync(
    await homeDir,
    maxDepth: 2,
  );

  if (diskItem != null) {
    print('Root: ${diskItem.name} - ${diskItem.displaySize}');
    print('Children: ${diskItem.childCount}\n');

    if (diskItem.hasChildren) {
      print('Top 5 largest items:');
      for (final child in diskItem.sortedChildren.take(5)) {
        print('${child.name}: ${child.displaySize}');
      }
    }
  }

  print('\nFinding large files (>100MB)...');
  final largeFiles = await diskAnalyzerService.findLargeFiles(
    await homeDir,
    minSizeInMB: 100,
    maxDepth: 3,
  );

  print('Found ${largeFiles.length} large files');
  for (final file in largeFiles.take(5)) {
    print('${file.name}: ${file.displaySize}');
  }

  print('\nDisk analyzer example complete!\n');
}
