import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/splash_screen.dart';
import 'state/scope.dart';
import 'theme/tokens.dart';

/// Root widget: applies the active colour theme and the Geist font.
class WristbandApp extends StatelessWidget {
  const WristbandApp({super.key, required this.services});

  final Services services;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      services: services,
      child: ListenableBuilder(
        listenable: services.store,
        builder: (context, _) {
          final colors = AppColors.of(services.store.effectiveTheme);
          final overlay = colors.isLight ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light;
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: overlay.copyWith(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: colors.bg,
              systemNavigationBarIconBrightness: colors.isLight ? Brightness.dark : Brightness.light,
            ),
            child: AppTheme(
              colors: colors,
              child: MaterialApp(
                title: 'AI Band',
                debugShowCheckedModeBanner: false,
                theme: _materialTheme(colors),
                builder: (context, child) => AppTheme(colors: colors, child: child!),
                home: const SplashScreen(),
              ),
            ),
          );
        },
      ),
    );
  }

  ThemeData _materialTheme(AppColors c) {
    final base = c.isLight ? ThemeData.light(useMaterial3: true) : ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: c.bg,
      canvasColor: c.bg,
      colorScheme: base.colorScheme.copyWith(
        primary: c.accent,
        onPrimary: c.onAccent,
        surface: c.surface,
        onSurface: c.text,
        error: c.danger,
      ),
      textTheme: base.textTheme.apply(fontFamily: AppFonts.sans, bodyColor: c.text, displayColor: c.text),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: c.accent,
        selectionColor: c.accent.withValues(alpha: 0.35),
        selectionHandleColor: c.accent,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: c.accent,
        inactiveTrackColor: c.track,
        thumbColor: c.accent,
        overlayColor: c.accent.withValues(alpha: 0.15),
        trackHeight: 6,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      }),
    );
  }
}

/// Smooth push transition: the new page slides in a little and fades.
Route<T> slideRoute<T>(Widget page) => PageRouteBuilder<T>(
      transitionDuration: const Duration(milliseconds: 340),
      reverseTransitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (context, a, secondary, child) {
        final curve = CurvedAnimation(parent: a, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
        return FadeTransition(
          opacity: curve,
          child: SlideTransition(
            position: Tween(begin: const Offset(0.12, 0), end: Offset.zero).animate(curve),
            child: child,
          ),
        );
      },
    );

/// Full screen transition used for Live talk: rises from the bottom.
Route<T> riseRoute<T>(Widget page) => PageRouteBuilder<T>(
      transitionDuration: const Duration(milliseconds: 420),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (context, a, secondary, child) {
        final curve = CurvedAnimation(parent: a, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
        return FadeTransition(
          opacity: curve,
          child: SlideTransition(
            position: Tween(begin: const Offset(0, 0.08), end: Offset.zero).animate(curve),
            child: ScaleTransition(scale: Tween(begin: 0.98, end: 1.0).animate(curve), child: child),
          ),
        );
      },
    );

/// Cross fade, used when replacing the whole flow (onboarding to home).
Route<T> fadeRoute<T>(Widget page) => PageRouteBuilder<T>(
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (context, a, _, child) =>
          FadeTransition(opacity: CurvedAnimation(parent: a, curve: Curves.easeOut), child: child),
    );
