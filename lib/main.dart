import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'screens/dev/component_showcase_screen.dart';
import 'screens/dev/design_preview_screen.dart';
import 'screens/home_screen.dart';
import 'screens/step_guide_screen.dart';
import 'screens/live_cpr_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/triage_screen.dart';
import 'services/ollama_service.dart';

// Trusts the self-signed/dev cert on the ngrok tunnel host ONLY. Every other
// HTTPS connection this app makes still gets full certificate validation.
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) =>
              host == OllamaService.ngrokHost;
  }
}

void main() {
  HttpOverrides.global = MyHttpOverrides();
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0A0A0F),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const ReviveApp());
}

class ReviveApp extends StatelessWidget {
  const ReviveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Revive AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      // Pinned to dark until Phase 3 migrates the screens onto semantic
      // tokens. The screens still carry hardcoded dark-surface colors, so
      // following the system setting today would render dark-on-light.
      // Flip to ThemeMode.system once the screen migration lands.
      themeMode: ThemeMode.dark,
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/guide': (context) => const StepGuideScreen(),
        '/triage': (context) => const TriageScreen(),
        '/live': (context) => const LiveCprScreen(),
        '/chat': (context) => const ChatScreen(),
        DesignPreviewScreen.routeName: (context) => const DesignPreviewScreen(),
        ComponentShowcaseScreen.routeName: (context) =>
            const ComponentShowcaseScreen(),
      },
    );
  }
}
