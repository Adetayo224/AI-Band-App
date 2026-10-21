import 'dart:math' as math;
import 'dart:ui';

/// Small SVG path data parser. It supports every command the app icons use
/// (M L H V C S Q T A Z, absolute and relative) and returns a Flutter [Path].
Path parseSvgPath(String data) {
  final tokens = _tokenize(data);
  final path = Path();
  var i = 0;
  var cmd = '';
  var cx = 0.0, cy = 0.0; // current point
  var sx = 0.0, sy = 0.0; // sub path start
  var lcx = 0.0, lcy = 0.0; // last control point
  var lastCmd = '';

  bool isCmd(String t) => t.length == 1 && RegExp(r'[A-Za-z]').hasMatch(t);
  double next() => double.parse(tokens[i++]);
  bool flag() {
    final t = tokens[i];
    // Arc flags can be glued together, for example "011".
    if (t.length > 1 && (t[0] == '0' || t[0] == '1') && !t.contains('.')) {
      tokens[i] = t.substring(1);
      return t[0] == '1';
    }
    i++;
    return t == '1';
  }

  while (i < tokens.length) {
    if (isCmd(tokens[i])) {
      cmd = tokens[i++];
    } else if (cmd.isEmpty) {
      i++;
      continue;
    }
    final rel = cmd == cmd.toLowerCase();
    final c = cmd.toUpperCase();
    final ox = rel ? cx : 0.0;
    final oy = rel ? cy : 0.0;
    switch (c) {
      case 'M':
        cx = ox + next();
        cy = oy + next();
        sx = cx;
        sy = cy;
        path.moveTo(cx, cy);
        // Further pairs after a moveto are treated as lineto.
        cmd = rel ? 'l' : 'L';
        break;
      case 'L':
        cx = ox + next();
        cy = oy + next();
        path.lineTo(cx, cy);
        break;
      case 'H':
        cx = (rel ? cx : 0.0) + next();
        path.lineTo(cx, cy);
        break;
      case 'V':
        cy = (rel ? cy : 0.0) + next();
        path.lineTo(cx, cy);
        break;
      case 'C':
        final x1 = ox + next(), y1 = oy + next();
        final x2 = ox + next(), y2 = oy + next();
        cx = ox + next();
        cy = oy + next();
        path.cubicTo(x1, y1, x2, y2, cx, cy);
        lcx = x2;
        lcy = y2;
        break;
      case 'S':
        final reflect = lastCmd == 'C' || lastCmd == 'S';
        final x1 = reflect ? 2 * cx - lcx : cx;
        final y1 = reflect ? 2 * cy - lcy : cy;
        final x2 = ox + next(), y2 = oy + next();
        cx = ox + next();
        cy = oy + next();
        path.cubicTo(x1, y1, x2, y2, cx, cy);
        lcx = x2;
        lcy = y2;
        break;
      case 'Q':
        final x1 = ox + next(), y1 = oy + next();
        cx = ox + next();
        cy = oy + next();
        path.quadraticBezierTo(x1, y1, cx, cy);
        lcx = x1;
        lcy = y1;
        break;
      case 'T':
        final reflect = lastCmd == 'Q' || lastCmd == 'T';
        final x1 = reflect ? 2 * cx - lcx : cx;
        final y1 = reflect ? 2 * cy - lcy : cy;
        cx = ox + next();
        cy = oy + next();
        path.quadraticBezierTo(x1, y1, cx, cy);
        lcx = x1;
        lcy = y1;
        break;
      case 'A':
        final rx = next(), ry = next();
        final rot = next();
        final large = flag();
        final sweep = flag();
        cx = ox + next();
        cy = oy + next();
        path.arcToPoint(
          Offset(cx, cy),
          radius: Radius.elliptical(rx, ry),
          rotation: rot,
          largeArc: large,
          clockwise: sweep,
        );
        break;
      case 'Z':
        path.close();
        cx = sx;
        cy = sy;
        break;
    }
    lastCmd = c;
  }
  return path;
}

List<String> _tokenize(String d) {
  final out = <String>[];
  final re = RegExp(r'[A-Za-z]|-?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?');
  for (final m in re.allMatches(d)) {
    out.add(m.group(0)!);
  }
  return out;
}

/// Degrees to radians helper used by painters.
double deg(double d) => d * math.pi / 180;
