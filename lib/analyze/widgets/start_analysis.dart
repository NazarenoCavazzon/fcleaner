import 'package:fcleaner/analyze/cubit/analyze_cubit.dart';
import 'package:fcleaner/home/view/home_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ui/ui.dart';

class StartAnalysis extends StatelessWidget {
  const StartAnalysis({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      width: 700,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            children: [
              Text(
                'Ready to optimize your system?',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Analyze your Mac to find junk files, unused apps, and reclaim valuable disk space',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          const SizedBox(height: 24),
          BlocConsumer<AnalyzeCubit, AnalyzeState>(
            buildWhen: (previous, current) => previous.status != current.status,
            listenWhen: (previous, current) =>
                current.status == AnalyzeStatus.analyzed,
            listener: (context, state) {
              if (state.status == AnalyzeStatus.analyzed) {
                context.go(
                  Home.route,
                  extra: {
                    'cleanUpAnalysis': state.cleanUpAnalysis,
                    'cleanupPreview': state.cleanupPreview,
                    'uninstallAnalysis': state.uninstallAnalysis,
                  },
                );
              }
            },

            builder: (context, state) {
              return MaterialButton(
                splashColor: Colors.transparent,
                focusElevation: 0,
                elevation: 0,
                highlightElevation: 0,
                hoverElevation: 0,
                disabledElevation: 0,
                highlightColor: Colors.transparent,
                minWidth: double.infinity,
                height: 64,
                color: state.isAnalyzing
                    ? Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.7)
                    : Theme.of(context).colorScheme.primary,
                textColor: Theme.of(context).colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onPressed: context.read<AnalyzeCubit>().analyze,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: state.isAnalyzing
                      ? [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            'Analyzing your system...',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ]
                      : [
                          Icon(
                            Icons.auto_awesome,
                            color: Theme.of(context).colorScheme.onPrimary,
                            size: 24,
                          ),
                          const SizedBox(width: 16),
                          Text(
                            'Start Analysis',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ],
                ),
              );
            },
          ),
          const SizedBox(height: 32),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              StartAnalysisItem(
                title: 'System Cleanup',
                icon: Icons.cleaning_services,
              ),
              SizedBox(width: 16),
              StartAnalysisItem(
                title: 'App Uninstaller',
                icon: Icons.inventory_2_outlined,
              ),
              SizedBox(width: 16),
              StartAnalysisItem(title: 'Disk Analyzer', icon: Icons.storage),
            ],
          ),
        ],
      ),
    );
  }
}

class StartAnalysisItem extends StatelessWidget {
  const StartAnalysisItem({
    required this.title,
    required this.icon,
    super.key,
  });

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
