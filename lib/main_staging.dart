import 'package:fcleaner/app/app.dart';
import 'package:fcleaner/bootstrap.dart';
import 'package:os_cleaner/os_cleaner.dart';

Future<void> main() async {
  await bootstrap(() async {
    final platformCleaner = await createPlatformCleaner();
    return App(platformCleaner: platformCleaner);
  });
}
