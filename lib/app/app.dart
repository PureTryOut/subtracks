import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:subtracks/app/routes.dart';

import '../state/init.dart';
import '../state/theme.dart';

class MyApp extends HookConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final init = ref.watch(initProvider);
    return init.when(
      data: (_) => const App(),
      error: (e, s) => Directionality(
        textDirection: TextDirection.ltr,
        child: Container(
          color: Colors.red[900],
          child: Column(
            children: [
              const SizedBox(height: 100),
              Text(e.toString()),
              Text(s.toString()),
            ],
          ),
        ),
      ),
      loading: () => const CircularProgressIndicator(),
    );
  }
}

class App extends HookConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var router = ref.watch(routesProvider);
    final base = ref.watch(baseThemeProvider);

    return MaterialApp.router(
      theme: base.theme,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: [...AppLocalizations.supportedLocales]
        ..moveToTheFront(const Locale('en')),
      builder: (context, child) => Overlay(
        initialEntries: [
          OverlayEntry(builder: (context) => child!),
        ],
      ),
    );
  }
}
