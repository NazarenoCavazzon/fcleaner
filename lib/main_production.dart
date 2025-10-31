import 'package:fcleaner/app/app.dart';
import 'package:fcleaner/bootstrap.dart';

Future<void> main() async {
  await bootstrap(() => const App());
}
