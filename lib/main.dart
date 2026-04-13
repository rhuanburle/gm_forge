import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/auth/auth_service.dart';
import 'core/database/hive_database.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'core/widgets/mobile_warning_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await HiveDatabase.init();

  // Increase Flutter's in-memory image cache to 150 MB to reduce re-downloads
  PaintingBinding.instance.imageCache.maximumSizeBytes = 150 * 1024 * 1024;

  runApp(const ProviderScope(child: QuestScriptApp()));
}

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
  };
}

class QuestScriptApp extends ConsumerWidget {
  const QuestScriptApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(authStateProvider);

    return MaterialApp.router(
      title: 'Quest Script',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: ref.watch(appRouterProvider),
      scrollBehavior: MyCustomScrollBehavior(),
      builder: (context, child) {
        return MobileWarningWrapper(child: child!);
      },
    );
  }
}
