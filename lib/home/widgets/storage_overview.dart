import 'package:fcleaner/home/cubit/home_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:ui/ui.dart';

class StorageOverview extends StatelessWidget {
  const StorageOverview({super.key});

  @override
  Widget build(BuildContext context) {
    final systemInfo = context
        .read<HomeCubit>()
        .state
        .cleanUpAnalysis
        .systemInfo;
    final usedSpaceInGb =
        ((systemInfo.totalDiskSpace - systemInfo.freeDiskSpace) / 1000000000)
            .ceil();
    final totalSpaceInGb = (systemInfo.totalDiskSpace / 1000000000).ceil();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Symbols.hard_drive,
                size: 20,
                color: Theme.of(context).colorScheme.onSecondary,
              ),
              const SizedBox(width: 4),
              const Text(
                'Storage Overview',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                '$usedSpaceInGb GB of $totalSpaceInGb GB used',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w400,
                  color: Theme.of(context).colorScheme.onSecondary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Disk Usage',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w400,
                  color: Theme.of(context).colorScheme.onSecondary,
                ),
              ),
              Text(
                '${(usedSpaceInGb / totalSpaceInGb * 100).toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: usedSpaceInGb / totalSpaceInGb,
            color: Theme.of(context).colorScheme.primary,
            minHeight: 12,
            borderRadius: BorderRadius.circular(100),
            backgroundColor: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }
}
