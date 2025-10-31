import 'package:fcleaner/shared/utils/byte_formatter.dart';

enum DiskItemType {
  file,
  directory,
  symlink,
}

class DiskItem {
  const DiskItem({
    required this.path,
    required this.name,
    required this.sizeBytes,
    required this.type,
    this.children,
  });

  final String path;
  final String name;
  final int sizeBytes;
  final DiskItemType type;
  final List<DiskItem>? children;

  String get displaySize => ByteFormatter.format(sizeBytes);

  String get displaySizeShort => ByteFormatter.formatShort(sizeBytes);

  double percentageOf(int totalSize) {
    if (totalSize == 0) return 0;
    return (sizeBytes / totalSize) * 100;
  }

  bool get isDirectory => type == DiskItemType.directory;

  bool get isFile => type == DiskItemType.file;

  bool get hasChildren => children != null && children!.isNotEmpty;

  int get childCount => children?.length ?? 0;

  DiskItem copyWith({
    String? path,
    String? name,
    int? sizeBytes,
    DiskItemType? type,
    List<DiskItem>? children,
  }) {
    return DiskItem(
      path: path ?? this.path,
      name: name ?? this.name,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      type: type ?? this.type,
      children: children ?? this.children,
    );
  }

  List<DiskItem> get sortedChildren {
    if (children == null) return [];
    final sorted = List<DiskItem>.from(children!)
      ..sort((a, b) => b.sizeBytes.compareTo(a.sizeBytes));
    return sorted;
  }
}
