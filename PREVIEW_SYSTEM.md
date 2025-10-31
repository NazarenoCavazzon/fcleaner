# Cleanup Preview System

## Overview

The new preview system makes it **crystal clear** what `performCleanup()` will delete before executing any cleanup operations.

## What Changed

### 1. New `CleanupPreview` Model

A comprehensive preview that shows exactly what will be deleted:

```dart
class CleanupPreview {
  final List<String> categoryIds;           // Which categories selected
  final int totalItems;                     // Total items to delete
  final int totalBytes;                     // Total bytes to free
  final Map<String, CategoryPreview> itemsByCategory;  // Grouped by category
  final bool requiresSudo;                  // Does it need admin access?
  
  String get summary;                       // Human-readable summary
  List<CategoryPreview> get categoriesBySize;  // Sorted by size
}

class CategoryPreview {
  final String categoryId;
  final String categoryName;
  final List<CleanupItem> items;            // Actual items to delete
  
  int get totalBytes;
  String get displaySize;
  List<CleanupItem> topItems([int limit = 5]);  // Show largest items
}
```

### 2. Enhanced `AnalysisResult`

New methods to generate previews:

```dart
// Get list of items that will be deleted
List<CleanupItem> getItemsToDelete(List<String> categoryIds);

// Calculate total size that will be freed
int getTotalSizeToFree(List<String> categoryIds);

// Get total count of items to delete
int getTotalItemsToDelete(List<String> categoryIds);

// Generate comprehensive preview
CleanupPreview getPreview(List<String> categoryIds);
```

### 3. Refactored `CleanupService`

**Old API (unclear):**
```dart
// What will this delete? Everything? Just some items?
performCleanup(categoryIds, analysisResult.categories);
```

**New API (explicit):**
```dart
// Uses the analysis to know exactly what to delete
performCleanup({
  required AnalysisResult analysis,
  required List<String> categoryIds,
  bool dryRun = false,  // Safety: test without deleting
});
```

**Benefits:**
- ✅ Explicitly references the analysis
- ✅ Built-in dry-run mode
- ✅ No ambiguity about what gets deleted
- ✅ Only deletes non-whitelisted items

## Usage Flow

### Step 1: Analyze System
```dart
final analysis = await cleanupService.analyzeSystem();

print('Found ${analysis.totalItems} items in ${analysis.categoryCount} categories');
print('Total: ${ByteFormatter.format(analysis.totalSize)}');
```

### Step 2: Select Categories
```dart
final selectedCategories = ['system_essentials', 'browsers', 'developer_tools'];
```

### Step 3: Preview What Will Be Deleted
```dart
final preview = analysis.getPreview(selectedCategories);

print('${preview.summary}');
// Output: "Will delete 1,234 items, freeing 2.5 GB"

print('Requires sudo: ${preview.requiresSudo}');
print('Categories: ${preview.categoryCount}');

// Show detailed breakdown
for (final categoryPreview in preview.categoriesBySize) {
  print('${categoryPreview.categoryName}:');
  print('  Items: ${categoryPreview.itemCount}');
  print('  Size: ${categoryPreview.displaySize}');
  
  // Show largest items as examples
  for (final item in categoryPreview.topItems(3)) {
    print('    - ${item.name} (${ByteFormatter.format(item.sizeBytes)})');
  }
}
```

**Example Output:**
```
Will delete 1,234 items, freeing 2.5 GB
Requires sudo: false
Categories: 3

System Essentials: 456 items (1.2 GB)
  - node_modules_cache (450 MB)
  - Downloads/incomplete.dmg (200 MB)
  - Library/Caches/com.apple.Safari (150 MB)
  ... and 453 more items

Browsers: 678 items (1.0 GB)
  - Chrome/Cache (600 MB)
  - Firefox/cache2 (300 MB)
  - Safari/Webpage Previews (100 MB)
  ... and 675 more items

Developer Tools: 100 items (300 MB)
  - .npm/_cacache (150 MB)
  - .yarn/cache (100 MB)
  - .cache/pip (50 MB)
  ... and 97 more items
```

### Step 4: Dry Run (Test Without Deleting)
```dart
final result = await cleanupService.performCleanupSync(
  analysis: analysis,
  categoryIds: selectedCategories,
  dryRun: true,  // SAFE: doesn't actually delete
);

print('Dry run complete!');
print('Would delete: ${result.itemsCleaned} items');
print('Would free: ${ByteFormatter.format(result.bytesFreed)}');
```

### Step 5: Actual Cleanup
```dart
// Request sudo if needed
if (preview.requiresSudo) {
  await cleanupService.requestSudoIfNeeded(analysis, selectedCategories);
}

// Perform actual cleanup
final result = await cleanupService.performCleanupSync(
  analysis: analysis,
  categoryIds: selectedCategories,
  dryRun: false,  // NOW it actually deletes
);

print('Deleted: ${result.itemsCleaned} items');
print('Freed: ${ByteFormatter.format(result.bytesFreed)}');
```

### Streaming Progress (Optional)
```dart
await for (final progress in cleanupService.performCleanup(
  analysis: analysis,
  categoryIds: selectedCategories,
  dryRun: false,
)) {
  print('${progress.progressPercentage.toStringAsFixed(1)}%');
  print('Current: ${progress.currentItem}');
  print('Freed so far: ${ByteFormatter.format(progress.bytesFreed)}');
}
```

## Key Features

### 1. Preview Before Delete
Know **exactly** what will be deleted before taking any action.

### 2. Dry Run Mode
Test the cleanup without actually deleting anything:
```dart
performCleanupSync(analysis: analysis, categoryIds: ids, dryRun: true);
```

### 3. Whitelisted Items Excluded
`getItemsToDelete()` automatically filters out whitelisted items:
```dart
.where((item) => !item.isWhitelisted)
```

### 4. Category Grouping
Preview groups items by category with size totals:
```dart
preview.itemsByCategory['system_essentials'].totalBytes
```

### 5. Top Items Display
Show the largest items in each category:
```dart
categoryPreview.topItems(5)  // Top 5 largest items
```

## Migration Guide

### Before (Old API)
```dart
final analysis = await cleanupService.analyzeSystem();
final categoryIds = ['system_essentials'];

// Unclear what this deletes
await cleanupService.performCleanup(categoryIds, analysis.categories);
```

### After (New API)
```dart
final analysis = await cleanupService.analyzeSystem();
final categoryIds = ['system_essentials'];

// 1. Preview first
final preview = analysis.getPreview(categoryIds);
print(preview.summary);

// 2. Dry run
await cleanupService.performCleanupSync(
  analysis: analysis,
  categoryIds: categoryIds,
  dryRun: true,
);

// 3. Actual cleanup
await cleanupService.performCleanupSync(
  analysis: analysis,
  categoryIds: categoryIds,
  dryRun: false,
);
```

## Benefits

✅ **Transparency**: User knows exactly what will be deleted
✅ **Safety**: Built-in dry-run mode for testing
✅ **Clarity**: No ambiguity about what `performCleanup()` does
✅ **Detailed**: Shows item-by-item breakdown by category
✅ **Flexible**: Preview can be customized for different UIs
✅ **Efficient**: Items filtered once, reused for cleanup

## Files Created/Modified

**New Files:**
- `lib/cleanup/models/cleanup_preview.dart` - Preview models

**Modified Files:**
- `lib/cleanup/models/analysis_result.dart` - Added preview methods
- `lib/cleanup/data/cleanup_service.dart` - Refactored API
- `lib/examples/service_usage_example.dart` - Updated example

## Example Output

Run the example to see the preview system in action:

```bash
cd /Users/nazarenocavazzon/Documents/fcleaner
dart lib/examples/service_usage_example.dart
```

You'll see:
1. **Analysis phase**: What CAN be cleaned
2. **Preview phase**: What WILL be deleted
3. **Detailed breakdown**: Items grouped by category
4. **Dry run**: Simulated cleanup without deletion

