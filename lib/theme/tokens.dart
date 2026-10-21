import 'package:flutter/material.dart';

/// The three looks of the app. Light is pure white, dark is pure black and
/// night keeps the black ground but uses warm text and a dimmer lime so it is
/// easy on the eyes late in the evening.
enum AppThemeMode { light, dark, night }

/// Colour tokens copied from the design canvas. Every screen reads its colours
/// from here, so a theme switch repaints the whole app.
@immutable
class AppColors {
  const AppColors({
    required this.mode,
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.border,
    required this.text,
    required this.muted,
    required this.faint,
    required this.accent,
    required this.onAccent,
    required this.accentText,
    required this.accentSoft,
    required this.danger,
    required this.dangerSoft,
    required this.warn,
    required this.warnSoft,
    required this.track,
    required this.knob,
  });

  final AppThemeMode mode;
  final Color bg;
  final Color surface;
  final Color surface2;
  final Color border;
  final Color text;
  final Color muted;
  final Color faint;
  final Color accent;
  final Color onAccent;
  final Color accentText;
  final Color accentSoft;
  final Color danger;
  final Color dangerSoft;
  final Color warn;
  final Color warnSoft;
  final Color track;
  final Color knob;

  bool get isLight => mode == AppThemeMode.light;

  static const light = AppColors(
    mode: AppThemeMode.light,
    bg: Color(0xFFFFFFFF),
    surface: Color(0xFFF5F6F2),
    surface2: Color(0xFFEAECE5),
    border: Color(0xFFE2E4DC),
    text: Color(0xFF0A0A0A),
    muted: Color(0xFF5C5F55),
    faint: Color(0xFF9A9D92),
    accent: Color(0xFFC6F432),
    onAccent: Color(0xFF0A0A0A),
    accentText: Color(0xFF3D5700),
    accentSoft: Color(0xFFEEF9CC),
    danger: Color(0xFFC4321F),
    dangerSoft: Color(0xFFFBE9E6),
    warn: Color(0xFF8A5100),
    warnSoft: Color(0xFFFDF0DC),
    track: Color(0xFFD6D9CF),
    knob: Color(0xFFFFFFFF),
  );

  static const dark = AppColors(
    mode: AppThemeMode.dark,
    bg: Color(0xFF000000),
    surface: Color(0xFF0F0F0F),
    surface2: Color(0xFF1C1C1C),
    border: Color(0xFF232323),
    text: Color(0xFFFFFFFF),
    muted: Color(0xFFA1A1A1),
    faint: Color(0xFF5E5E5E),
    accent: Color(0xFFC6F432),
    onAccent: Color(0xFF000000),
    accentText: Color(0xFFC6F432),
    accentSoft: Color(0x1FC6F432),
    danger: Color(0xFFFF6B57),
    dangerSoft: Color(0x1FFF6B57),
    warn: Color(0xFFFFB547),
    warnSoft: Color(0x1AFFB547),
    track: Color(0xFF2E2E2E),
    knob: Color(0xFFFFFFFF),
  );

  static const night = AppColors(
    mode: AppThemeMode.night,
    bg: Color(0xFF000000),
    surface: Color(0xFF110D09),
    surface2: Color(0xFF1E1710),
    border: Color(0xFF261E15),
    text: Color(0xFFE8D5B5),
    muted: Color(0xFFA6927A),
    faint: Color(0xFF5C5042),
    accent: Color(0xFFA9C43A),
    onAccent: Color(0xFF0A0805),
    accentText: Color(0xFFB4CC4A),
    accentSoft: Color(0x1FA9C43A),
    danger: Color(0xFFE07A5F),
    dangerSoft: Color(0x1FE07A5F),
    warn: Color(0xFFD9A05B),
    warnSoft: Color(0x1AD9A05B),
    track: Color(0xFF2E2419),
    knob: Color(0xFFE8D5B5),
  );

  static AppColors of(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return light;
      case AppThemeMode.dark:
        return dark;
      case AppThemeMode.night:
        return night;
    }
  }
}

/// Font family names registered in pubspec.yaml.
class AppFonts {
  static const sans = 'Geist';
  static const mono = 'GeistMono';
}

/// Shared spacing and radius values from the design.
class AppSpace {
  static const gutter = 20.0;
  static const topInset = 16.0;
  static const radiusCard = 22.0;
  static const radiusHero = 28.0;
}

/// Lets any widget read the active colours with `AppTheme.of(context)`.
class AppTheme extends InheritedWidget {
  const AppTheme({super.key, required this.colors, required super.child});

  final AppColors colors;

  static AppColors of(BuildContext context) {
    final widget = context.dependOnInheritedWidgetOfExactType<AppTheme>();
    return widget?.colors ?? AppColors.dark;
  }

  @override
  bool updateShouldNotify(AppTheme oldWidget) => oldWidget.colors != colors;
}

/// Text styles used across the app. Sizes and weights follow the design.
class AppText {
  static TextStyle display(AppColors c, {double size = 28}) => TextStyle(
        fontFamily: AppFonts.sans,
        fontSize: size,
        height: 1.1,
        fontWeight: FontWeight.w600,
        letterSpacing: -size * 0.03,
        color: c.text,
      );

  static TextStyle title(AppColors c, {double size = 22}) => TextStyle(
        fontFamily: AppFonts.sans,
        fontSize: size,
        fontWeight: FontWeight.w600,
        letterSpacing: -size * 0.02,
        color: c.text,
      );

  static TextStyle body(AppColors c,
          {double size = 15, FontWeight weight = FontWeight.w400, Color? color, double height = 1.45}) =>
      TextStyle(
        fontFamily: AppFonts.sans,
        fontSize: size,
        fontWeight: weight,
        height: height,
        color: color ?? c.text,
      );

  static TextStyle label(AppColors c, {double size = 14, Color? color}) => TextStyle(
        fontFamily: AppFonts.sans,
        fontSize: size,
        fontWeight: FontWeight.w600,
        color: color ?? c.text,
      );

  static TextStyle muted(AppColors c, {double size = 13, FontWeight weight = FontWeight.w400}) => TextStyle(
        fontFamily: AppFonts.sans,
        fontSize: size,
        fontWeight: weight,
        height: 1.4,
        color: c.muted,
      );

  static TextStyle mono(AppColors c, {double size = 13, FontWeight weight = FontWeight.w500, Color? color}) =>
      TextStyle(
        fontFamily: AppFonts.mono,
        fontSize: size,
        fontWeight: weight,
        letterSpacing: size >= 20 ? -size * 0.04 : 0,
        color: color ?? c.text,
      );

  static TextStyle overline(AppColors c) => TextStyle(
        fontFamily: AppFonts.sans,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 12 * 0.08,
        color: c.muted,
      );
}
