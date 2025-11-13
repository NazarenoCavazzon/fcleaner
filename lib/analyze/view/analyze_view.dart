import 'package:fcleaner/analyze/cubit/analyze_cubit.dart';
import 'package:fcleaner/analyze/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:os_cleaner/os_cleaner.dart';

class AnalyzePage extends StatelessWidget {
  const AnalyzePage({super.key});

  static String get route => '/analyze';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AnalyzeCubit(context.read<OSCleaner>()),
      child: const AnalyzeView(),
    );
  }
}

class AnalyzeView extends StatelessWidget {
  const AnalyzeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'FCleaner',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Keep your Mac running at peak performance',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w400,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              const StartAnalysis(),
              const SizedBox(height: 24),
              Text(
                'Safe and secure • No data collection • Complete control',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
