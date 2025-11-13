import 'package:fcleaner/home/cubit/home_cubit.dart';
import 'package:fcleaner/home/view/overview_view.dart';
import 'package:fcleaner/home/view/system_cleanup_view.dart';
import 'package:fcleaner/home/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:os_cleaner/os_cleaner.dart';

class Home extends StatelessWidget {
  const Home({
    required this.cleanUpAnalysis,
    super.key,
  });

  static String get route => '/';
  final AnalysisResult cleanUpAnalysis;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HomeCubit(
        cleanUpAnalysis: cleanUpAnalysis,
        osCleaner: context.read<OSCleaner>(),
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
              const HomeTabBar(),
              BlocBuilder<HomeCubit, HomeState>(
                builder: (context, state) {
                  return switch (state.selectedTab) {
                    HomeTab.overview => const OverviewView(),
                    HomeTab.cleanup => const SystemCleanupView(),
                    HomeTab.uninstall => const SizedBox(),
                  };
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
