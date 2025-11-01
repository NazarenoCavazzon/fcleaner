import 'package:fcleaner/cleanup/models/analysis_result.dart';
import 'package:fcleaner/home/cubit/home_cubit.dart';
import 'package:fcleaner/shared/utils/byte_formatter.dart';
import 'package:fcleaner/uninstall/models/app_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:ui/ui.dart';

class InfoCards extends StatelessWidget {
  const InfoCards({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.read<HomeCubit>().state;
    final analysisResult = state.cleanUpAnalysis;
    final listAppsInfo = state.uninstallAnalysis;

    final cards = _buildInfoCards(
      analysisResult: analysisResult,
      apps: listAppsInfo,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        late final int crossAxisCount;

        switch (constraints.maxWidth) {
          case >= 850:
            crossAxisCount = 4;
          case >= 500:
            crossAxisCount = 2;
          default:
            crossAxisCount = 1;
        }

        return AlignedGridView.count(
          shrinkWrap: true,
          itemCount: cards.length,
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          itemBuilder: (context, index) {
            return _InfoCard(cards[index]);
          },
        );
      },
    );
  }
}

List<InfoCardData> _buildInfoCards({
  required AnalysisResult analysisResult,
  required List<AppInfo> apps,
}) {
  return [
    InfoCardData(
      title: 'Junk Files',
      value: _getCategorySize(analysisResult, [
        'system_essentials',
        'orphaned_data',
        'sandboxed_apps',
      ]),
      description: 'Can be cleaned',
      icon: Symbols.delete,
    ),
    InfoCardData(
      title: 'Cache Files',
      value: _getCategorySize(analysisResult, [
        'macos_system_caches',
        'browsers',
        'cloud_storage',
      ]),
      description: 'System & app caches',
      icon: Icons.folder_outlined,
    ),
    InfoCardData(
      title: 'Log Files',
      value: _getCategorySize(analysisResult, [
        'system_essentials',
        'applications',
      ]),
      description: 'Old system logs',
      icon: Icons.description_outlined,
    ),
    InfoCardData(
      title: 'Installed Apps',
      value: '${apps.length}',
      description: 'Applications found',
      icon: Icons.apps_outlined,
    ),
  ];
}

String _getCategorySize(AnalysisResult result, List<String> categoryIds) {
  final categories = result.categories.where(
    (cat) => categoryIds.contains(cat.id),
  );
  final totalSize = categories.fold(0, (sum, cat) => sum + cat.totalSize);
  return ByteFormatter.formatShort(totalSize);
}

class InfoCardData {
  const InfoCardData({
    required this.title,
    required this.value,
    required this.description,
    required this.icon,
  });

  final String title;
  final String value;
  final String description;
  final IconData icon;
}

class _InfoCard extends StatelessWidget {
  const _InfoCard(this.data);

  final InfoCardData data;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                data.title,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              Icon(
                data.icon,
                size: 24,
                color: Theme.of(context).colorScheme.onSecondary,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            data.value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            data.description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
