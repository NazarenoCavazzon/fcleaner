import 'package:os_cleaner/src/models/models.dart';

class CleanupCategory {
  const CleanupCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.items,
  });

  final String id;
  final String name;
  final String description;
  final List<CleanupItem> items;

  int get totalSize => items.fold(0, (sum, item) => sum + item.sizeBytes);
  int get itemCount => items.length;
  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;

  CleanupCategory copyWith({
    String? id,
    String? name,
    String? description,
    List<CleanupItem>? items,
  }) {
    return CleanupCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      items: items ?? this.items,
    );
  }
}
