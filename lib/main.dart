import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'auth/auth_controller.dart';
import 'auth/auth_scope.dart';
import 'screens/home_shell.dart';
import 'services/app_update_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  runApp(const RodaPresaApp());
}

class RodaPresaApp extends StatefulWidget {
  const RodaPresaApp({super.key});

  @override
  State<RodaPresaApp> createState() => _RodaPresaAppState();
}

class _RodaPresaAppState extends State<RodaPresaApp> {
  late final AppUpdateService _appUpdateService;
  late final AuthController _authController;

  @override
  void initState() {
    super.initState();
    _appUpdateService = AppUpdateService();
    _authController = AuthController();

    _checkForRequiredUpdate();
    unawaited(_authController.restoreSession());
  }

  void _checkForRequiredUpdate() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_appUpdateService.checkForImmediateUpdate());
    });
  }

  @override
  void dispose() {
    _authController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthScope(
      controller: _authController,
      child: MaterialApp(
        title: 'Roda Presa',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        locale: const Locale('pt', 'BR'),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('pt', 'BR')],
        home: const HomeShell(),
      ),
    );
  }
}
