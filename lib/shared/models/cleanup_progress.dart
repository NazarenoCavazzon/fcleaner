class CleanupProgress {
  const CleanupProgress({
    required this.currentCategory,
    required this.currentItem,
    required this.itemsProcessed,
    required this.totalItems,
    required this.bytesFreed,
  });

  final String currentCategory;
  final String currentItem;
  final int itemsProcessed;
  final int totalItems;
  final int bytesFreed;

  double get progress => totalItems > 0 ? itemsProcessed / totalItems : 0;

  double get progressPercentage => progress * 100;
}
