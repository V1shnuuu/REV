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
  // Locked to portrait: compression detection reads the accelerometer's Z
  // axis, which assumes the phone stays flat/upright against the chest. A
  // landscape rotation would remap the axis and break counting.
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const ReviveApp());
}

/// Keeps the status and navigation bars in step with the active theme.
///
/// The overlay style used to be set once in main() with a hardcoded dark
/// navigation bar. Now that the app follows the system light/dark setting,
/// that would paint a black navigation bar under a light UI, so it is resolved
/// from the theme instead.
class _SystemUiWrapper extends StatelessWidget {
  final Widget child;

  const _SystemUiWrapper({required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconBrightness = isDark ? Brightness.light : Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: iconBrightness,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: context.colors.surfacePrimary,
        systemNavigationBarIconBrightness: iconBrightness,
      ),
      child: child,
    );
  }
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
      // Every screen now resolves colour through the ReviveColors extension,
      // so both brightnesses render correctly and the app can follow the
      // system setting.
      themeMode: ThemeMode.system,
      // Wraps every route, so the system bars track the active brightness on
      // whichever screen is showing.
      builder: (context, child) =>
          _SystemUiWrapper(child: child ?? const SizedBox.shrink()),
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
