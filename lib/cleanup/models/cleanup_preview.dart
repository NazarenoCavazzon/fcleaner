import 'package:fcleaner/cleanup/models/cleanup_item.dart';
import 'package:fcleaner/shared/utils/byte_formatter.dart';

class CleanupPreview {
  const CleanupPreview({
    required this.categoryIds,
    required this.totalItems,
    required this.totalBytes,
    required this.itemsByCategory,
    required this.requiresSudo,
  });

  final List<String> categoryIds;
  final int totalItems;
  final int totalBytes;
  final Map<String, CategoryPreview> itemsByCategory;
  final bool requiresSudo;

  String get summary =>
      'Will delete $totalItems items, freeing ${ByteFormatter.format(totalBytes)}';

  String get summaryShort => ByteFormatter.formatShort(totalBytes);

  bool get hasItems => totalItems > 0;

  bool get isEmpty => totalItems == 0;

  int get categoryCount => itemsByCategory.length;

  List<CategoryPreview> get categoriesBySize {
    final categories = itemsByCategory.values.toList()
      ..sort((a, b) => b.totalBytes.compareTo(a.totalBytes));
    return categories;
  }
}

class CategoryPreview {
  const CategoryPreview({
    required this.categoryId,
    required this.categoryName,
    required this.items,
  });

  final String categoryId;
  final String categoryName;
  final List<CleanupItem> items;

  int get totalBytes => items.fold(0, (sum, item) => sum + item.sizeBytes);

  int get itemCount => items.length;

  String get displaySize => ByteFormatter.format(totalBytes);

  String get displaySizeShort => ByteFormatter.formatShort(totalBytes);

  List<CleanupItem> get largestItems {
    final sorted = List<CleanupItem>.from(items)
      ..sort((a, b) => b.sizeBytes.compareTo(a.sizeBytes));
    return sorted;
  }

  List<CleanupItem> topItems([int limit = 5]) {
    return largestItems.take(limit).toList();
  }
}
