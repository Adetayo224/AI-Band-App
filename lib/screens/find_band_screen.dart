import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/band_service.dart';
import '../state/scope.dart';
import '../theme/tokens.dart';
import '../ui/icons.dart';
import '../ui/motion.dart';
import '../ui/widgets.dart';

/// Radar style finder. The band dot moves closer to the phone as the
/// Bluetooth signal gets stronger.
class FindBandScreen extends StatefulWidget {
  const FindBandScreen({super.key});

  @override
  State<FindBandScreen> createState() => _FindBandScreenState();
}

class _FindBandScreenState extends State<FindBandScreen> {
  late BandService _band;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _band = context.band;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_band.connected && !_band.ringing) _band.setRinging(true);
    });
  }

  @override
  void dispose() {
    if (_band.ringing) _band.setRinging(false);
    if (_band.vibrating) _band.setFindVibrate(false);
    super.dispose();
  }

  static const _levels = [
    ('Far away', 'More than 10 metres', 130.0),
    ('Nearby', 'About 5 metres away', 96.0),
    ('Close', 'About 2 metres away', 62.0),
    ('Very close', 'Within 1 metre', 32.0),
  ];

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return PageScaffold(
      child: Watch(
        listenables: [_band],
        builder: (context) {
          final connected = _band.connected;
          final lv = connected ? _band.proximityLevel : 0;
          final (label, sub, r) = _levels[lv];
          const a = -0.75;
          final dx = 155 + r * math.cos(a);
          final dy = 155 + r * math.sin(a);
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const SubHeader(title: 'Find my band', backLabel: 'Back to device'),
            const SizedBox(height: 10),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: GestureDetector(
                  onTap: _band.isDemo ? _band.demoCycleDistance : null,
                  child: SizedBox(
                    width: 310,
                    height: 310,
                    child: Stack(clipBehavior: Clip.none, children: [
                      if (connected) Positioned.fill(child: RadarSweep(color: c.accent.withValues(alpha: 0.22))),
                      if (connected)
                        Positioned.fill(
                            child: PingRings(
                                color: c.accent,
                                startScale: 0.15,
                                startOpacity: 0.6,
                                duration: const Duration(milliseconds: 2600))),
                      Positioned.fill(child: CustomPaint(painter: _RadarRings(c.border))),
                      Center(
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(color: c.text, shape: BoxShape.circle),
                          alignment: Alignment.center,
                          child: AppIcon(AppIcons.phone, size: 20, color: c.bg),
                        ),
                      ),
                      if (connected)
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 600),
                          curve: const Cubic(0.2, 0.8, 0.3, 1),
                          left: dx - 24,
                          top: dy - 24,
                          child: Bob(
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: c.accent,
                                shape: BoxShape.circle,
                                boxShadow: [BoxShadow(color: c.accentSoft, spreadRadius: 6)],
                              ),
                              alignment: Alignment.center,
                              child: AppIcon(AppIcons.watch, size: 22, color: c.onAccent, strokeWidth: 2),
                            ),
                          ),
                        ),
                    ]),
                  ),
                ),
              ),
            ),
            if (_band.isDemo)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('Demo: tap the radar to walk closer',
                    textAlign: TextAlign.center, style: AppText.muted(c, size: 12)),
              ),
            const SizedBox(height: 16),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Column(key: ValueKey('$connected$lv'), children: [
                Text(connected ? label : 'Band not connected', style: AppText.display(c, size: 32)),
                const SizedBox(height: 6),
                Text(connected ? sub : 'Reconnect it from the Device tab, then try again.',
                    style: AppText.muted(c, size: 14)),
              ]),
            ),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Semantics(
                label: 'Signal strength ${lv + 1} of 4',
                child: Row(children: [
                  for (var i = 0; i < 4; i++) ...[
                    if (i > 0) const SizedBox(width: 6),
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        height: 6,
                        decoration: BoxDecoration(
                          color: connected && i <= lv ? c.accent : c.track,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                  ],
                ]),
              ),
            ),
            const SizedBox(height: 10),
            Text('Walk around. The dot moves closer as the signal gets stronger.',
                textAlign: TextAlign.center, style: AppText.muted(c, size: 12)),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                child: PillButton(
                  label: _band.ringing ? 'Stop sound' : 'Play sound',
                  icon: AppIcons.volumeLow,
                  tone: _band.ringing ? ButtonTone.accent : ButtonTone.solid,
                  fontSize: 15,
                  onTap: connected ? () => _band.setRinging(!_band.ringing) : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: PillButton(
                  label: _band.vibrating ? 'Vibrating' : 'Vibrate',
                  icon: AppIcons.vibrationSmall,
                  tone: ButtonTone.outline,
                  fontSize: 15,
                  onTap: connected ? () => _band.setFindVibrate(!_band.vibrating) : null,
                ),
              ),
            ]),
          ]);
        },
      ),
    );
  }
}

class _RadarRings extends CustomPainter {
  _RadarRings(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = color;
    final center = size.center(Offset.zero);
    for (final r in const [152.0, 114.0, 76.0, 38.0]) {
      canvas.drawCircle(center, r, p);
    }
  }

  @override
  bool shouldRepaint(_RadarRings old) => old.color != color;
}
