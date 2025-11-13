import 'package:fcleaner/home/widgets/widgets.dart';
import 'package:flutter/widgets.dart';

class OverviewView extends StatelessWidget {
  const OverviewView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        StorageOverview(),
        SizedBox(height: 24),
        InfoCards(),
      ],
    );
  }
}
