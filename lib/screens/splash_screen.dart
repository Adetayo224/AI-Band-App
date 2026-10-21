import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../app.dart';
import '../state/scope.dart';
import '../theme/tokens.dart';
import '../ui/motion.dart';
import '../ui/widgets.dart';
import 'home_shell.dart';
import 'onboarding.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer(const Duration(milliseconds: 1700), _go);
  }

  void _go() {
    if (!mounted) return;
    final next = context.store.onboarded ? const HomeShell() : const WelcomeScreen();
    Navigator.of(context).pushReplacement(fadeRoute(next));
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return PageScaffold(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(children: [
        Expanded(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            SizedBox(
              width: 180,
              height: 180,
              child: Stack(alignment: Alignment.center, children: [
                Positioned.fill(
                  child: ImageFiltered(
                    imageFilter: ui.ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                    child: Breathe(color: c.accent, duration: const Duration(milliseconds: 2800)),
                  ),
                ),
                const BandMark(size: 128, strokeWidth: 3, showSpeaker: true),
              ]),
            ),
            const SizedBox(height: 28),
            Rise(
              delay: const Duration(milliseconds: 200),
              child: Column(children: [
                Text.rich(
                  TextSpan(children: [
                    const TextSpan(text: 'AI Band'),
                    TextSpan(text: '.', style: TextStyle(color: c.accent)),
                  ]),
                  style: TextStyle(
                    fontFamily: AppFonts.sans,
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -34 * 0.04,
                    color: c.text,
                  ),
                ),
                const SizedBox(height: 8),
                Text('Your assistant, on your wrist', style: AppText.body(c, color: c.muted)),
              ]),
            ),
          ]),
        ),
        SizedBox(
          width: 120,
          height: 4,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: Container(color: c.track, child: _LoadingBar(color: c.accent)),
          ),
        ),
        const SizedBox(height: 16),
        Text('Version 1.0.0', style: AppText.mono(c, size: 12, weight: FontWeight.w400, color: c.muted)),
      ]),
    );
  }
}

class _LoadingBar extends StatefulWidget {
  const _LoadingBar({required this.color});
  final Color color;

  @override
  State<_LoadingBar> createState() => _LoadingBarState();
}

class _LoadingBarState extends State<_LoadingBar> with TickerProviderStateMixin, LoopingAnimation {
  @override
  Duration get loopDuration => const Duration(milliseconds: 1400);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      return AnimatedBuilder(
        animation: loop,
        builder: (context, _) {
          final w = box.maxWidth * 0.4;
          final x = -w + (box.maxWidth + w) * Curves.easeInOut.transform(loop.value);
          return Stack(children: [
            Positioned(
              left: x,
              top: 0,
              bottom: 0,
              width: w,
              child: DecoratedBox(
                decoration: BoxDecoration(color: widget.color, borderRadius: BorderRadius.circular(99)),
              ),
            ),
          ]);
        },
      );
    });
  }
}
