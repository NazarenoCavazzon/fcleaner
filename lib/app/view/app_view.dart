import 'package:fcleaner/analyze/analyze.dart';
import 'package:fcleaner/shared/services/service_provider.dart';
import 'package:fcleaner/cleanup/models/analysis_result.dart';
import 'package:fcleaner/cleanup/models/cleanup_preview.dart';
import 'package:fcleaner/home/home.dart';
import 'package:fcleaner/l10n/gen/app_localizations.dart';
import 'package:fcleaner/uninstall/models/app_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
      create: (context) => ServiceProvider(),
      child: const AppView(),
    );
  }
}

class AppView extends StatefulWidget {
  const AppView({super.key});

  @override
  State<AppView> createState() => _AppViewState();
}

class _AppViewState extends State<AppView> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  late GoRouter _routerConfig;

  @override
  void initState() {
    super.initState();
    _routerConfig = _getRouter(context);
    context.read<ServiceProvider>().initialize();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      theme: ThemeData(
        fontFamily: 'WorkSans',
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF3B82F6),
          onPrimary: Color(0xFFFCFCFC),
          secondary: Color(0xFFF5F5F5),
          onSecondary: Color(0xFF636363),
          onSurface: Color(0xFF262626),
          error: Color(0xFFDC2626),
          onError: Color(0xFFFCFCFC),
          surfaceContainerHighest: Color(0xFFE5E5E5),
          outline: Color(0xFFE5E5E5),
        ),
        useMaterial3: true,
      ),
      // darkTheme: ThemeData(
      //   fontFamily: 'WorkSans',
      //   colorScheme: const ColorScheme.dark(
      //     primary: Color(0xFF60A5FA),
      //     onPrimary: Color(0xFFFCFCFC),
      //     secondary: Color(0xFF333333),
      //     onSecondary: Color(0xFFF2F2F2),
      //     surface: Color(0xFF262626),
      //     onSurface: Color(0xFFF2F2F2),
      //     error: Color(0xFFEF4444),
      //     onError: Color(0xFFFCFCFC),
      //     surfaceContainerHighest: Color(0xFF404040),
      //     outline: Color(0xFF404040),
      //   ),
      //   useMaterial3: true,
      // ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: _routerConfig,
    );
  }

  GoRouter _getRouter(BuildContext context) {
    return GoRouter(
      initialLocation: AnalyzePage.route,
      navigatorKey: _navigatorKey,
      routes: [
        GoRoute(
          name: AnalyzePage.route,
          path: AnalyzePage.route,
          builder: (_, state) => AnalyzePage(key: state.pageKey),
        ),
        GoRoute(
          name: Home.route,
          path: Home.route,
          builder: (context, state) {
            final params = state.extra as Map<String, dynamic>?;

            if (params == null) {
              context.go(AnalyzePage.route);
            }

            return Home(
              key: state.pageKey,
              cleanUpAnalysis: params!['cleanUpAnalysis'] as AnalysisResult,
              cleanupPreview: params['cleanupPreview'] as CleanupPreview,
              uninstallAnalysis: params['uninstallAnalysis'] as List<AppInfo>,
            );
          },
        ),
      ],
    );
  }
}
