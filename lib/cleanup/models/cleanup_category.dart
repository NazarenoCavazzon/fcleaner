import 'package:fcleaner/cleanup/models/cleanup_item.dart';

class CleanupCategory {
  const CleanupCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.items,
    required this.requiresSudo,
  });

  final String id;
  final String name;
  final String description;
  final List<CleanupItem> items;
  final bool requiresSudo;

  int get totalSize => items.fold(0, (sum, item) => sum + item.sizeBytes);

  int get itemCount => items.length;

  bool get isEmpty => items.isEmpty;

  bool get isNotEmpty => items.isNotEmpty;

  CleanupCategory copyWith({
    String? id,
    String? name,
    String? description,
    List<CleanupItem>? items,
    bool? requiresSudo,
  }) {
    return CleanupCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      items: items ?? this.items,
      requiresSudo: requiresSudo ?? this.requiresSudo,
    );
  }
}
