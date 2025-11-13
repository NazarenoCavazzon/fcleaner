import 'package:os_cleaner/src/models/models.dart';

class AnalysisResult {
  const AnalysisResult({
    required this.categories,
    required this.analyzedAt,
    required this.systemInfo,
    required this.installedApps,
  });

  final List<CleanupCategory> categories;
  final DateTime analyzedAt;
  final SystemInfo systemInfo;
  final List<AppInfo> installedApps;

  int get totalSize => categories.fold(0, (sum, cat) => sum + cat.totalSize);
  int get totalItems => categories.fold(0, (sum, cat) => sum + cat.itemCount);
  int get categoryCount => categories.length;
  bool get hasCleanableItems => totalItems > 0;

  List<CleanupCategory> get nonEmptyCategories =>
      categories.where((cat) => cat.isNotEmpty).toList();

  List<CleanupItem> getItemsToDelete(List<String> categoryIds) {
    return categories
        .where((cat) => categoryIds.contains(cat.id))
        .expand((cat) => cat.items)
        .where((item) => !item.isWhitelisted)
        .toList();
  }

  int getTotalSizeToFree(List<String> categoryIds) {
    return getItemsToDelete(
      categoryIds,
    ).fold(0, (sum, item) => sum + item.sizeBytes);
  }

  int getTotalItemsToDelete(List<String> categoryIds) {
    return getItemsToDelete(categoryIds).length;
  }

  CleanupPreview getPreview(List<String> categoryIds) {
    final items = getItemsToDelete(categoryIds);
    final itemsByCategory = _groupByCategory(items, categoryIds);

    return CleanupPreview(
      categoryIds: categoryIds,
      totalItems: items.length,
      totalBytes: items.fold(0, (sum, item) => sum + item.sizeBytes),
      itemsByCategory: itemsByCategory,
    );
  }

  Map<String, CategoryPreview> _groupByCategory(
    List<CleanupItem> items,
    List<String> categoryIds,
  ) {
    final grouped = <String, CategoryPreview>{};

    for (final categoryId in categoryIds) {
      final category = categories.firstWhere(
        (cat) => cat.id == categoryId,
        orElse: () => const CleanupCategory(
          id: '',
          name: '',
          description: '',
          items: [],
        ),
      );

      if (category.id.isEmpty) continue;

      final categoryItems = items
          .where((item) => category.items.any((ci) => ci.path == item.path))
          .toList();

      if (categoryItems.isNotEmpty) {
        grouped[categoryId] = CategoryPreview(
          categoryId: category.id,
          categoryName: category.name,
          items: categoryItems,
        );
      }
    }

    return grouped;
  }

  AnalysisResult copyWith({
    List<CleanupCategory>? categories,
    DateTime? analyzedAt,
    SystemInfo? systemInfo,
    List<AppInfo>? installedApps,
  }) {
    return AnalysisResult(
      categories: categories ?? this.categories,
      analyzedAt: analyzedAt ?? this.analyzedAt,
      systemInfo: systemInfo ?? this.systemInfo,
      installedApps: installedApps ?? this.installedApps,
    );
  }
}
