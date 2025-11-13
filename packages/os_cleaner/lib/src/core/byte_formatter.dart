class ByteFormatter {
  static String format(int bytes, {int decimals = 2}) {
    if (bytes <= 0) return '0 B';

    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB', 'PB'];
    final i = (bytes.bitLength - 1) ~/ 10;
    final size = bytes / (1 << (i * 10));

    return '${size.toStringAsFixed(decimals)} ${suffixes[i]}';
  }

  static String formatShort(int bytes) {
    if (bytes <= 0) return '0 B';

    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    final i = (bytes.bitLength - 1) ~/ 10;
    final size = bytes / (1 << (i * 10));

    if (size >= 100) {
      return '${size.toStringAsFixed(0)} ${suffixes[i]}';
    } else if (size >= 10) {
      return '${size.toStringAsFixed(1)} ${suffixes[i]}';
    } else {
      return '${size.toStringAsFixed(2)} ${suffixes[i]}';
    }
  }

  static int parseSize(String sizeString) {
    final regex = RegExp(r'([\d.]+)\s*([KMGTP]?B?)');
    final match = regex.firstMatch(sizeString.toUpperCase());

    if (match == null) return 0;

    final value = double.tryParse(match.group(1) ?? '0') ?? 0;
    final suffix = match.group(2) ?? 'B';

    const multipliers = {
      'B': 1,
      'KB': 1024,
      'MB': 1024 * 1024,
      'GB': 1024 * 1024 * 1024,
      'TB': 1024 * 1024 * 1024 * 1024,
      'PB': 1024 * 1024 * 1024 * 1024 * 1024,
    };

    return (value * (multipliers[suffix] ?? 1)).toInt();
  }
}
