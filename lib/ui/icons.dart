import 'package:flutter/widgets.dart';

import 'svg_path.dart';

/// One drawable part of an icon on a 24 by 24 grid.
sealed class IconPart {
  const IconPart({this.fill = false});
  final bool fill;
}

class PathPart extends IconPart {
  const PathPart(this.d, {super.fill});
  final String d;
}

class CirclePart extends IconPart {
  const CirclePart(this.cx, this.cy, this.r, {super.fill});
  final double cx, cy, r;
}

class RectPart extends IconPart {
  const RectPart(this.x, this.y, this.w, this.h, {this.rx = 0, super.fill});
  final double x, y, w, h, rx;
}

/// Line icons drawn with SVG path data, exactly as on the design canvas.
/// No emojis are used anywhere in the app.
class AppIcons {
  static const chevronLeft = [PathPart('m15 6-6 6 6 6')];
  static const chevronRight = [PathPart('m9 6 6 6-6 6')];
  static const chevronDown = [PathPart('m6 9 6 6 6-6')];
  static const bell = [PathPart('M6 16v-5a6 6 0 1 1 12 0v5l1.5 2h-15z'), PathPart('M10 20.5a2 2 0 0 0 4 0')];
  static const bluetooth = [PathPart('m7 7 10 10-5 4V3l5 4L7 17')];
  static const bluetoothOff = [PathPart('m7 7 10 10-5 4V3l5 4-2.5 2'), PathPart('M3 3l18 18')];
  static const mic = [
    RectPart(9, 3, 6, 11, rx: 3),
    PathPart('M5 11a7 7 0 0 0 14 0'),
    PathPart('M12 18v3'),
  ];
  static const micOff = [
    RectPart(9, 3, 6, 11, rx: 3),
    PathPart('M5 11a7 7 0 0 0 14 0'),
    PathPart('M12 18v3'),
    PathPart('M4 4l16 16'),
  ];
  static const arrowUpRight = [PathPart('M7 17 17 7'), PathPart('M8 7h9v9')];
  static const target = [
    CirclePart(12, 12, 3),
    CirclePart(12, 12, 8),
    PathPart('M12 2v2M12 20v2M2 12h2M20 12h2'),
  ];
  static const vibration = [RectPart(8, 4, 8, 16, rx: 2), PathPart('M4.5 8v8M19.5 8v8M1.5 10.5v3M22.5 10.5v3')];
  static const vibrationSmall = [RectPart(8, 4, 8, 16, rx: 2), PathPart('M4.5 8v8M19.5 8v8')];
  static const volume = [
    PathPart('M11 5 6 9H3v6h3l5 4z'),
    PathPart('M15.5 8.5a5 5 0 0 1 0 7'),
    PathPart('M18.5 5.5a9 9 0 0 1 0 13'),
  ];
  static const volumeLow = [PathPart('M11 5 6 9H3v6h3l5 4z'), PathPart('M15.5 8.5a5 5 0 0 1 0 7')];
  static const sync = [
    PathPart('M20 11a8 8 0 0 0-14.9-3'),
    PathPart('M4 13a8 8 0 0 0 14.9 3'),
    PathPart('M4 4v4h4'),
    PathPart('M20 20v-4h-4'),
  ];
  static const sparkle = [PathPart('M12 3l1.8 5.2L19 10l-5.2 1.8L12 17l-1.8-5.2L5 10l5.2-1.8z')];
  static const sparkles = [
    PathPart('M12 3l1.8 5.2L19 10l-5.2 1.8L12 17l-1.8-5.2L5 10l5.2-1.8z'),
    PathPart('M19 16l.7 1.8 1.8.7-1.8.7L19 21l-.7-1.8-1.8-.7 1.8-.7z'),
  ];
  static const home = [PathPart('M3 10.5 12 3l9 7.5V20a1 1 0 0 1-1 1h-5v-6h-6v6H4a1 1 0 0 1-1-1z')];
  static const chat = [PathPart('M21 12a8 8 0 0 1-11.6 7.1L4 20l1-4.6A8 8 0 1 1 21 12z')];
  static const watch = [
    CirclePart(12, 12, 5),
    PathPart('M9 7.6 9.6 3h4.8l.6 4.6'),
    PathPart('M9 16.4l.6 4.6h4.8l.6-4.6'),
  ];
  static const sliders = [
    PathPart('M4 6h9M17 6h3M4 12h3M11 12h9M4 18h11M19 18h1'),
    CirclePart(15, 6, 2),
    CirclePart(9, 12, 2),
    CirclePart(17, 18, 2),
  ];
  static const check = [PathPart('m5 12.5 4.5 4.5L19 7.5')];
  static const help = [
    CirclePart(12, 12, 9),
    PathPart('M9.5 9.5a2.5 2.5 0 1 1 3.5 2.3c-.6.3-1 .8-1 1.5v.7'),
    PathPart('M12 17h.01'),
  ];
  static const search = [CirclePart(11, 11, 7), PathPart('m20 20-4-4')];
  static const plus = [PathPart('M12 5v14M5 12h14')];
  static const pin = [PathPart('M9 4h6l-1 6 3 3H7l3-3z'), PathPart('M12 13v7')];
  static const phone = [RectPart(7, 2.5, 10, 19, rx: 2.5), PathPart('M11 18h2')];
  static const copy = [
    RectPart(8, 8, 12, 12, rx: 2.5),
    PathPart('M16 8V6a2 2 0 0 0-2-2H6a2 2 0 0 0-2 2v8a2 2 0 0 0 2 2h2'),
  ];
  static const share = [PathPart('M12 3v12M7 8l5-5 5 5'), PathPart('M5 13v6a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2v-6')];
  static const trash = [PathPart('M4 7h16M10 11v6M14 11v6M6 7l1 13h10l1-13M9 7V4h6v3')];
  static const alarm = [CirclePart(12, 13, 8), PathPart('M12 9v4l2.5 2M5 3 2 6M19 3l3 3')];
  static const clock = [CirclePart(12, 12, 9), PathPart('M12 7v5l3 2')];
  static const download = [PathPart('M12 4v11M7 10l5 5 5-5M5 20h14')];
  static const battery = [RectPart(2, 7, 18, 10, rx: 2.5), PathPart('M22 11v2')];
  static const batteryLow = [RectPart(2, 7, 18, 10, rx: 2.5), PathPart('M22 11v2M5 10v4')];
  static const chip = [
    RectPart(5, 5, 14, 14, rx: 2),
    PathPart('M9 2v3M15 2v3M9 19v3M15 19v3M2 9h3M2 15h3M19 9h3M19 15h3'),
  ];
  static const chipCore = [
    RectPart(5, 5, 14, 14, rx: 2),
    PathPart('M9 2v3M15 2v3M9 19v3M15 19v3M2 9h3M2 15h3M19 9h3M19 15h3'),
    RectPart(9, 9, 6, 6, rx: 1),
  ];
  static const dots = [
    CirclePart(5, 12, 1.8, fill: true),
    CirclePart(12, 12, 1.8, fill: true),
    CirclePart(19, 12, 1.8, fill: true),
  ];
  static const restart = [PathPart('M20 11a8 8 0 1 1-2.3-5.7'), PathPart('M20 4v5h-5')];
  static const reset = [PathPart('M3 12a9 9 0 1 0 3-6.7'), PathPart('M3 4v5h5')];
  static const pencil = [PathPart('M4 20h4L19 9l-4-4L4 16z')];
  static const user = [CirclePart(12, 8, 4), PathPart('M4 21a8 8 0 0 1 16 0')];
  static const lock = [RectPart(4, 10, 16, 11, rx: 2.5), PathPart('M8 10V7a4 4 0 0 1 8 0v3')];
  static const waveform = [PathPart('M4 10v4M8 7v10M12 4v16M16 7v10M20 10v4')];
  static const globe = [
    CirclePart(12, 12, 9),
    PathPart('M3 12h18M12 3a14 14 0 0 1 0 18M12 3a14 14 0 0 0 0 18'),
  ];
  static const shield = [PathPart('M12 3 5 6v5c0 4.5 3 8.3 7 10 4-1.7 7-5.5 7-10V6z')];
  static const sun = [
    CirclePart(12, 12, 4),
    PathPart('M12 2v2M12 20v2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4M2 12h2M20 12h2M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4'),
  ];
  static const contrast = [CirclePart(12, 12, 8), PathPart('M12 4a8 8 0 0 0 0 16z', fill: true)];
  static const moon = [PathPart('M20 14.5A8 8 0 1 1 9.5 4a6.5 6.5 0 0 0 10.5 10.5z')];
  static const eye = [PathPart('M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7S2 12 2 12z'), CirclePart(12, 12, 3)];
  static const bolt = [PathPart('M13 2 4 14h7l-1 8 9-12h-7z', fill: true)];
  static const boltLine = [PathPart('M13 2 4 14h7l-1 8 9-12h-7z')];
  static const magnet = [PathPart('M6 3v8a6 6 0 0 0 12 0V3'), PathPart('M6 7h4M14 7h4')];
  static const drop = [PathPart('M12 3s6 6.5 6 11a6 6 0 0 1-12 0c0-4.5 6-11 6-11z')];
  static const button = [CirclePart(12, 12, 8), CirclePart(12, 12, 3)];
  static const warning = [PathPart('M12 3 2 20h20z'), PathPart('M12 10v4M12 17h.01')];
  static const play = [
    PathPart('M8 5.5v13a1 1 0 0 0 1.5.9l10.4-6.5a1 1 0 0 0 0-1.8L9.5 4.6A1 1 0 0 0 8 5.5z', fill: true),
  ];
  static const pause = [RectPart(6, 5, 4, 14, rx: 1, fill: true), RectPart(14, 5, 4, 14, rx: 1, fill: true)];
  static const stop = [RectPart(6, 6, 12, 12, rx: 3, fill: true)];
  static const captions = [RectPart(3, 5, 18, 14, rx: 3), PathPart('M10 10.5a2 2 0 1 0 0 3M17 10.5a2 2 0 1 0 0 3')];
  static const key = [CirclePart(8, 15, 4), PathPart('M11 12l9-9M17 6l3 3M14 9l2 2')];
}

/// Draws an [AppIcons] entry at any size with any colour.
class AppIcon extends StatelessWidget {
  const AppIcon(this.parts, {super.key, this.size = 20, this.color, this.strokeWidth = 1.8, this.semanticLabel});

  final List<IconPart> parts;
  final double size;
  final Color? color;
  final double strokeWidth;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = color ?? DefaultTextStyle.of(context).style.color ?? const Color(0xFFFFFFFF);
    final painter = CustomPaint(
      size: Size.square(size),
      painter: _IconPainter(parts, c, strokeWidth),
    );
    if (semanticLabel == null) return ExcludeSemantics(child: painter);
    return Semantics(label: semanticLabel, image: true, child: painter);
  }
}

class _IconPainter extends CustomPainter {
  _IconPainter(this.parts, this.color, this.strokeWidth);

  final List<IconPart> parts;
  final Color color;
  final double strokeWidth;

  static final Map<String, Path> _cache = {};

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24;
    canvas.save();
    canvas.scale(scale);
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    for (final p in parts) {
      final paint = p.fill ? fill : stroke;
      switch (p) {
        case PathPart(:final d):
          canvas.drawPath(_cache.putIfAbsent(d, () => parseSvgPath(d)), paint);
        case CirclePart(:final cx, :final cy, :final r):
          canvas.drawCircle(Offset(cx, cy), r, paint);
        case RectPart(:final x, :final y, :final w, :final h, :final rx):
          canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(rx)), paint);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_IconPainter old) => old.color != color || old.parts != parts || old.strokeWidth != strokeWidth;
}
