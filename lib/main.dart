import 'dart:io' show Platform;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/constants.dart';
import 'core/theme.dart';
import 'ui/splash/splash_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  final walletBox = await Hive.openBox(HiveBoxes.wallet);
  await Hive.openBox(HiveBoxes.chatSessions);
  await Hive.openBox(HiveBoxes.messages);
  await Hive.openBox(HiveBoxes.settings);

  if (!walletBox.containsKey('credits')) {
    await walletBox.put('credits', AppConstants.startingCredits);
  }

  // google_mobile_ads has no web/desktop implementation — calling
  // initialize() there throws (MissingPluginException on desktop,
  // and on web, `Platform.is*` itself throws before we'd even get that far).
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    await MobileAds.instance.initialize();
  }

  runApp(const ProviderScope(child: ReedPillApp()));
}

class ReedPillApp extends StatelessWidget {
  const ReedPillApp({super.key});

  @override
  Widget build(BuildContext context) {
    final String languageCode = ui.PlatformDispatcher.instance.locale
        .languageCode;

    return MaterialApp(
      title: 'ReedPill',
      debugShowCheckedModeBanner: false,
      supportedLocales: const [
        Locale('en'),
        Locale('ar'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.themeFor(languageCode),
      home: const SplashView(),
    );
  }
}
