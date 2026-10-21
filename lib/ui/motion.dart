import 'dart:math' as math;

import 'package:flutter/material.dart';

/// True when the phone asks for reduced motion. Every looping animation in
/// the app checks this and stays still when it is on.
bool reduceMotion(BuildContext context) => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

/// A controller that repeats forever unless the user prefers reduced motion.
mixin LoopingAnimation<T extends StatefulWidget> on State<T>, TickerProviderStateMixin<T> {
  late final AnimationController loop;

  Duration get loopDuration;

  @override
  void initState() {
    super.initState();
    loop = AnimationController(vsync: this, duration: loopDuration);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (reduceMotion(context)) {
      loop.stop();
      loop.value = 0.5;
    } else if (!loop.isAnimating) {
      loop.repeat();
    }
  }

  @override
  void dispose() {
    loop.dispose();
    super.dispose();
  }
}

/// Fades and slides a child up once when it first appears ("rise" on the
/// design canvas).
class Rise extends StatefulWidget {
  const Rise({super.key, required this.child, this.delay = Duration.zero, this.offset = 12});

  final Widget child;
  final Duration delay;
  final double offset;

  @override
  State<Rise> createState() => _RiseState();
}

class _RiseState extends State<Rise> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (reduceMotion(context)) _c.value = 1;
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curve = CurvedAnimation(parent: _c, curve: Curves.easeOut);
    return AnimatedBuilder(
      animation: curve,
      builder: (context, child) => Opacity(
        opacity: curve.value,
        child: Transform.translate(offset: Offset(0, widget.offset * (1 - curve.value)), child: child),
      ),
      child: widget.child,
    );
  }
}

/// Scales a child in with a small overshoot ("pop").
class Pop extends StatefulWidget {
  const Pop({super.key, required this.child});
  final Widget child;

  @override
  State<Pop> createState() => _PopState();
}

class _PopState extends State<Pop> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 550))
    ..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (reduceMotion(context)) return widget.child;
    final a = CurvedAnimation(parent: _c, curve: const Cubic(0.2, 1.4, 0.4, 1));
    return FadeTransition(
      opacity: CurvedAnimation(parent: _c, curve: const Interval(0, 0.5)),
      child: ScaleTransition(scale: Tween(begin: 0.6, end: 1.0).animate(a), child: widget.child),
    );
  }
}

/// Shakes a child sideways once, used for the "band not found" icon.
class Shake extends StatefulWidget {
  const Shake({super.key, required this.child});
  final Widget child;

  @override
  State<Shake> createState() => _ShakeState();
}

class _ShakeState extends State<Shake> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (reduceMotion(context)) return widget.child;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = _c.value;
        final dx = math.sin(t * math.pi * 5) * 6 * (1 - t);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: widget.child,
    );
  }
}

/// Expanding rings that fade out, used on onboarding, pairing and Find my
/// band ("ping" on the design canvas).
class PingRings extends StatefulWidget {
  const PingRings({
    super.key,
    required this.color,
    this.count = 3,
    this.duration = const Duration(milliseconds: 2400),
    this.fill,
    this.strokeWidth = 1.5,
    this.startScale = 0.35,
    this.startOpacity = 0.7,
  });

  final Color color;
  final Color? fill;
  final int count;
  final Duration duration;
  final double strokeWidth;
  final double startScale;
  final double startOpacity;

  @override
  State<PingRings> createState() => _PingRingsState();
}

class _PingRingsState extends State<PingRings> with TickerProviderStateMixin, LoopingAnimation {
  @override
  Duration get loopDuration => widget.duration;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: loop,
      builder: (context, _) => CustomPaint(
        painter: _PingPainter(
          t: loop.value,
          count: widget.count,
          color: widget.color,
          fill: widget.fill,
          strokeWidth: widget.strokeWidth,
          startScale: widget.startScale,
          startOpacity: widget.startOpacity,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _PingPainter extends CustomPainter {
  _PingPainter({
    required this.t,
    required this.count,
    required this.color,
    required this.fill,
    required this.strokeWidth,
    required this.startScale,
    required this.startOpacity,
  });

  final double t;
  final int count;
  final Color color;
  final Color? fill;
  final double strokeWidth;
  final double startScale;
  final double startOpacity;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final maxR = size.shortestSide / 2;
    for (var i = 0; i < count; i++) {
      final p = (t + i / count) % 1.0;
      final eased = Curves.easeOutCubic.transform(p);
      final r = maxR * (startScale + (1 - startScale) * eased);
      final o = startOpacity * (1 - p);
      if (fill != null) {
        canvas.drawCircle(center, r, Paint()..color = fill!.withValues(alpha: fill!.a * o / startOpacity));
      }
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..color = color.withValues(alpha: o),
      );
    }
  }

  @override
  bool shouldRepaint(_PingPainter old) => old.t != t || old.color != color;
}

/// A soft glowing halo that grows and shrinks ("breathe").
class Breathe extends StatefulWidget {
  const Breathe(
      {super.key, required this.color, this.duration = const Duration(milliseconds: 2600), this.offset = 0.0});
  final Color color;
  final Duration duration;
  final double offset;

  @override
  State<Breathe> createState() => _BreatheState();
}

class _BreatheState extends State<Breathe> with TickerProviderStateMixin, LoopingAnimation {
  @override
  Duration get loopDuration => widget.duration;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: loop,
      builder: (context, _) {
        final p = (loop.value + widget.offset) % 1.0;
        final wave = (1 - math.cos(p * 2 * math.pi)) / 2; // 0..1..0
        final scale = 0.92 + 0.14 * wave;
        final opacity = 0.55 - 0.4 * wave;
        return Transform.scale(
          scale: scale,
          child: DecoratedBox(
            decoration: BoxDecoration(shape: BoxShape.circle, color: widget.color.withValues(alpha: opacity)),
          ),
        );
      },
    );
  }
}

/// A spinning ring or dashed ring.
class Spinner extends StatefulWidget {
  const Spinner({
    super.key,
    required this.color,
    this.size = 20,
    this.strokeWidth = 2.5,
    this.dashed = false,
    this.duration = const Duration(milliseconds: 900),
  });

  final Color color;
  final double size;
  final double strokeWidth;
  final bool dashed;
  final Duration duration;

  @override
  State<Spinner> createState() => _SpinnerState();
}

class _SpinnerState extends State<Spinner> with TickerProviderStateMixin, LoopingAnimation {
  @override
  Duration get loopDuration => widget.duration;

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: loop,
      child: CustomPaint(
        size: Size.square(widget.size),
        painter: _SpinnerPainter(widget.color, widget.strokeWidth, widget.dashed),
      ),
    );
  }
}

class _SpinnerPainter extends CustomPainter {
  _SpinnerPainter(this.color, this.stroke, this.dashed);
  final Color color;
  final double stroke;
  final bool dashed;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    final r = rect.deflate(stroke / 2);
    if (dashed) {
      const segments = 28;
      const sweep = 2 * math.pi / segments;
      for (var i = 0; i < segments; i++) {
        canvas.drawArc(r, i * sweep, sweep * 0.55, false, paint);
      }
    } else {
      canvas.drawArc(r, 0, math.pi * 1.5, false, paint);
    }
  }

  @override
  bool shouldRepaint(_SpinnerPainter old) => old.color != color;
}

/// Bouncing equaliser bars. When [active] is false they rest flat.
class EqBars extends StatefulWidget {
  const EqBars({
    super.key,
    required this.heights,
    required this.color,
    this.active = true,
    this.barWidth = 4,
    this.gap = 4,
    this.duration = const Duration(milliseconds: 1100),
    this.stagger = 0.07,
    this.restScale = 0.18,
  });

  final List<double> heights;
  final Color color;
  final bool active;
  final double barWidth;
  final double gap;
  final Duration duration;
  final double stagger;
  final double restScale;

  @override
  State<EqBars> createState() => _EqBarsState();
}

class _EqBarsState extends State<EqBars> with TickerProviderStateMixin, LoopingAnimation {
  @override
  Duration get loopDuration => widget.duration;

  @override
  Widget build(BuildContext context) {
    final maxH = widget.heights.fold<double>(0, math.max);
    return SizedBox(
      height: maxH,
      child: AnimatedBuilder(
        animation: loop,
        builder: (context, _) {
          final secs = widget.duration.inMilliseconds / 1000;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < widget.heights.length; i++) ...[
                if (i > 0) SizedBox(width: widget.gap),
                Container(
                  width: widget.barWidth,
                  height: widget.heights[i] *
                      (widget.active
                          ? 0.25 +
                              0.75 *
                                  ((1 - math.cos(((loop.value + (i * widget.stagger) / secs) % 1) * 2 * math.pi)) / 2)
                          : widget.restScale),
                  decoration: BoxDecoration(color: widget.color, borderRadius: BorderRadius.circular(99)),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// Three dots bouncing in turn, shown while the assistant is thinking.
class TypingDots extends StatefulWidget {
  const TypingDots({super.key, required this.color});
  final Color color;

  @override
  State<TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<TypingDots> with TickerProviderStateMixin, LoopingAnimation {
  @override
  Duration get loopDuration => const Duration(milliseconds: 1200);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: loop,
      builder: (context, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 3; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Builder(builder: (context) {
              final p = (loop.value - i * 0.125) % 1.0;
              final k = p < 0.4 ? math.sin(p / 0.4 * math.pi) : 0.0;
              return Transform.translate(
                offset: Offset(0, -4 * k),
                child: Opacity(
                  opacity: 0.35 + 0.65 * k,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

/// A blinking text caret.
class BlinkCaret extends StatefulWidget {
  const BlinkCaret({super.key, required this.color});
  final Color color;

  @override
  State<BlinkCaret> createState() => _BlinkCaretState();
}

class _BlinkCaretState extends State<BlinkCaret> with TickerProviderStateMixin, LoopingAnimation {
  @override
  Duration get loopDuration => const Duration(seconds: 1);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: loop,
      builder: (context, _) => Opacity(
        opacity: loop.value < 0.5 ? 1 : 0,
        child: Container(
          width: 2,
          height: 16,
          margin: const EdgeInsets.only(left: 2),
          color: widget.color,
        ),
      ),
    );
  }
}

/// A shimmering highlight that slides across a progress fill.
class Shine extends StatefulWidget {
  const Shine({super.key});

  @override
  State<Shine> createState() => _ShineState();
}

class _ShineState extends State<Shine> with TickerProviderStateMixin, LoopingAnimation {
  @override
  Duration get loopDuration => const Duration(milliseconds: 1600);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      return AnimatedBuilder(
        animation: loop,
        builder: (context, _) {
          final w = box.maxWidth * 0.4;
          final x = -w + (box.maxWidth + w * 2) * Curves.easeInOut.transform(loop.value);
          return Stack(children: [
            Positioned(
              left: x,
              top: 0,
              bottom: 0,
              width: w,
              child: Container(color: Colors.white.withValues(alpha: 0.35)),
            ),
          ]);
        },
      );
    });
  }
}

/// A rotating cone of light, used on the Find my band radar.
class RadarSweep extends StatefulWidget {
  const RadarSweep({super.key, required this.color});
  final Color color;

  @override
  State<RadarSweep> createState() => _RadarSweepState();
}

class _RadarSweepState extends State<RadarSweep> with TickerProviderStateMixin, LoopingAnimation {
  @override
  Duration get loopDuration => const Duration(milliseconds: 3200);

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: loop,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: SweepGradient(
            colors: [widget.color, widget.color.withValues(alpha: 0)],
            stops: const [0, 0.25],
            transform: const GradientRotation(-math.pi / 2),
          ),
        ),
      ),
    );
  }
}

/// A gentle repeating bob (scale up and down), used on the radar band dot.
class Bob extends StatefulWidget {
  const Bob({super.key, required this.child});
  final Widget child;

  @override
  State<Bob> createState() => _BobState();
}

class _BobState extends State<Bob> with TickerProviderStateMixin, LoopingAnimation {
  @override
  Duration get loopDuration => const Duration(milliseconds: 1200);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: loop,
      builder: (context, child) =>
          Transform.scale(scale: 1 + 0.12 * (1 - math.cos(loop.value * 2 * math.pi)) / 2, child: child),
      child: widget.child,
    );
  }
}

/// Pulsing outer glow used when Find my band is ringing.
class PulseGlow extends StatefulWidget {
  const PulseGlow({super.key, required this.child, required this.color, required this.active, this.radius = 22});
  final Widget child;
  final Color color;
  final bool active;
  final double radius;

  @override
  State<PulseGlow> createState() => _PulseGlowState();
}

class _PulseGlowState extends State<PulseGlow> with TickerProviderStateMixin, LoopingAnimation {
  @override
  Duration get loopDuration => const Duration(milliseconds: 1400);

  @override
  Widget build(BuildContext context) {
    if (!widget.active) return widget.child;
    return AnimatedBuilder(
      animation: loop,
      builder: (context, child) {
        final k = math.sin(loop.value * math.pi);
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            boxShadow: [
              BoxShadow(color: widget.color.withValues(alpha: 0.45 * (1 - k)), spreadRadius: 10 * k),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
