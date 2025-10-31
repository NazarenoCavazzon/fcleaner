import 'package:fcleaner/home/home.dart';
import 'package:fcleaner/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppView();
  }
}

class AppView extends StatefulWidget {
  const AppView({super.key});

  @override
  State<AppView> createState() => _AppViewState();
}

class _AppViewState extends State<AppView> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      theme: ThemeData(
        appBarTheme: AppBarTheme(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        useMaterial3: true,
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: _getRouter(context),
    );
  }

  GoRouter _getRouter(BuildContext context) {
    return GoRouter(
      initialLocation: '/',
      navigatorKey: _navigatorKey,
      routes: [
        GoRoute(
          name: HomePage.route,
          path: HomePage.route,
          builder: (_, state) => HomePage(key: state.pageKey),
        ),
      ],
    );
  }
}
