import 'package:fcleaner/cleanup/models/cleanup_category.dart';
import 'package:fcleaner/cleanup/models/cleanup_item.dart';
import 'package:fcleaner/cleanup/models/cleanup_preview.dart';
import 'package:fcleaner/shared/models/system_info.dart';

class AnalysisResult {
  const AnalysisResult({
    required this.categories,
    required this.analyzedAt,
    required this.systemInfo,
  });

  final List<CleanupCategory> categories;
  final DateTime analyzedAt;
  final SystemInfo systemInfo;

  int get totalSize => categories.fold(0, (sum, cat) => sum + cat.totalSize);

  int get totalItems => categories.fold(0, (sum, cat) => sum + cat.itemCount);

  int get categoryCount => categories.length;

  List<CleanupCategory> get nonEmptyCategories =>
      categories.where((cat) => cat.isNotEmpty).toList();

  bool get hasCleanableItems => totalItems > 0;

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
      requiresSudo: categories
          .where((cat) => categoryIds.contains(cat.id))
          .any((cat) => cat.requiresSudo),
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
          requiresSudo: false,
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
  }) {
    return AnalysisResult(
      categories: categories ?? this.categories,
      analyzedAt: analyzedAt ?? this.analyzedAt,
      systemInfo: systemInfo ?? this.systemInfo,
    );
  }
}
