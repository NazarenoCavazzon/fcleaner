import 'package:fcleaner/disk_analyzer/data/macos_disk_datasource.dart';
import 'package:fcleaner/disk_analyzer/models/disk_item.dart';

class DiskAnalyzerService {
  DiskAnalyzerService(this._datasource);

  final MacOSDiskDatasource _datasource;

  Stream<DiskItem> analyzePath(
    String path, {
    int maxDepth = 3,
  }) async* {
    yield* _datasource.analyzePath(path, maxDepth: maxDepth);
  }

  Future<DiskItem?> analyzePathSync(
    String path, {
    int maxDepth = 3,
  }) async {
    return _datasource.analyzePathSync(path, maxDepth: maxDepth);
  }

  Future<List<DiskItem>> getTopLargestItems(
    String path, {
    int limit = 10,
  }) async {
    return _datasource.getTopLargestItems(path, limit: limit);
  }

  Future<List<DiskItem>> findLargeFiles(
    String path, {
    int minSizeInMB = 100,
    int maxDepth = 3,
  }) async {
    final rootItem = await analyzePathSync(path, maxDepth: maxDepth);

    if (rootItem == null) {
      return [];
    }

    final largeFiles = <DiskItem>[];
    final minSizeBytes = minSizeInMB * 1024 * 1024;

    _findLargeFilesRecursive(rootItem, minSizeBytes, largeFiles);

    largeFiles.sort((a, b) => b.sizeBytes.compareTo(a.sizeBytes));

    return largeFiles;
  }

  void _findLargeFilesRecursive(
    DiskItem item,
    int minSizeBytes,
    List<DiskItem> result,
  ) {
    if (item.isFile && item.sizeBytes >= minSizeBytes) {
      result.add(item);
    }

    if (item.children != null) {
      for (final child in item.children!) {
        _findLargeFilesRecursive(child, minSizeBytes, result);
      }
    }
  }
}
