import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'screens/main_shell.dart';
import 'screens/onboarding_screen.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';

class JejuCruiseApp extends StatefulWidget {
  const JejuCruiseApp({super.key});

  @override
  State<JejuCruiseApp> createState() => _JejuCruiseAppState();
}

class _JejuCruiseAppState extends State<JejuCruiseApp>
    with WidgetsBindingObserver {
  final AppState _appState = AppState();
  bool _keyboardWasVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _appState.initialize();
  }

  @override
  void didChangeMetrics() {
    final views = WidgetsBinding.instance.platformDispatcher.views;
    final keyboardVisible =
        views.isNotEmpty && views.first.viewInsets.bottom > 0;
    if (!keyboardVisible && _keyboardWasVisible) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FocusManager.instance.primaryFocus?.unfocus();
        SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
      });
    }
    _keyboardWasVisible = keyboardVisible;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _appState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    return MaterialApp(
      title: 'crujeju',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: const Locale('ko'),
      supportedLocales: const [
        Locale('ko'),
        Locale('en'),
        Locale('zh'),
        Locale('ja'),
      ],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: AnimatedBuilder(
        animation: _appState,
        builder: (context, _) {
          if (!_appState.initialized) return const AppLaunchScreen();
          if (!_appState.onboardingComplete) {
            return OnboardingScreen(onCompleted: _appState.completeOnboarding);
          }
          return MainShell(appState: _appState);
        },
      ),
    );
  }
}
