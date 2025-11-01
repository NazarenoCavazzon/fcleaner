import 'package:fcleaner/cleanup/models/analysis_result.dart';
import 'package:fcleaner/cleanup/models/cleanup_preview.dart';
import 'package:fcleaner/home/cubit/home_cubit.dart';
import 'package:fcleaner/home/widgets/widgets.dart';
import 'package:fcleaner/uninstall/models/app_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class Home extends StatelessWidget {
  const Home({
    required this.cleanUpAnalysis,
    required this.cleanupPreview,
    required this.uninstallAnalysis,
    super.key,
  });

  static String get route => '/';
  final AnalysisResult cleanUpAnalysis;
  final CleanupPreview cleanupPreview;
  final List<AppInfo> uninstallAnalysis;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HomeCubit(
        cleanUpAnalysis: cleanUpAnalysis,
        cleanupPreview: cleanupPreview,
        uninstallAnalysis: uninstallAnalysis,
      ),
      child: const HomeView(),
    );
  }
}

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'FCleaner',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
              Text(
                'Keep your Mac running smoothly',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              const StorageOverview(),
              const SizedBox(height: 24),
              const InfoCards(),
            ],
          ),
        ),
      ),
    );
  }
}
