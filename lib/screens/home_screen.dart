import 'dart:async';

import 'package:flutter/material.dart';

import '../app.dart';
import '../models/models.dart';
import '../services/band_service.dart';
import '../state/scope.dart';
import '../theme/tokens.dart';
import '../ui/format.dart';
import '../ui/icons.dart';
import '../ui/motion.dart';
import '../ui/widgets.dart';
import 'chat_detail_screen.dart';
import 'home_shell.dart';
import 'notifications_screen.dart';
import 'onboarding.dart';

/// Home tab. Shows the normal dashboard, or the "band disconnected" or
/// "band charging" states from the design, depending on the band.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.services;
    return Watch(
      listenables: [s.store, s.band],
      builder: (context) {
        final band = s.band;
        Widget body;
        if (!band.connected) {
          body = const _DisconnectedHome(key: ValueKey('off'));
        } else if (band.charging) {
          body = const _ChargingHome(key: ValueKey('charging'));
        } else {
          body = const _NormalHome(key: ValueKey('on'));
        }
        return AnimatedSwitcher(duration: const Duration(milliseconds: 350), child: body);
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({this.title, this.subtitle});
  final String? title;
  final Widget? subtitle;

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final store = context.store;
    final now = DateTime.now();
    final name = store.profile.callName;
    return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          subtitle ??
              Text(Fmt.longDate(now), style: AppText.body(c, size: 13, weight: FontWeight.w500, color: c.muted)),
          const SizedBox(height: 4),
          Text(title ?? (name.isEmpty ? Fmt.greeting(now) : '${Fmt.greeting(now)}, $name'),
              maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.display(c)),
        ]),
      ),
      const SizedBox(width: 12),
      CircleIconButton(
        icon: AppIcons.bell,
        label: 'Notifications',
        badge: store.hasUnread,
        onTap: () => Navigator.of(context).push(slideRoute(const NotificationsScreen())),
      ),
    ]);
  }
}

// ------------------------------------------------------------------ normal

class _NormalHome extends StatefulWidget {
  const _NormalHome({super.key});

  @override
  State<_NormalHome> createState() => _NormalHomeState();
}

class _NormalHomeState extends State<_NormalHome> {
  bool _synced = false;
  Timer? _syncTimer;

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }

  Future<void> _sync() async {
    await context.band.pushSettings();
    if (!mounted) return;
    setState(() => _synced = true);
    _syncTimer?.cancel();
    _syncTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _synced = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final s = context.services;
    final band = s.band;
    final shell = HomeShell.of(context);
    final latest = s.store.conversations.where((x) => x.messages.isNotEmpty).firstOrNull;
    final battery = band.battery ?? 0;
    return PageScaffold(
      scroll: true,
      safeBottom: false,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const _Header(),
        const SizedBox(height: 16),
        Rise(
          child: Pressable(
            pressedScale: 0.98,
            onTap: () => shell.goTo(AppTab.device),
            child: AppCard(
              radius: AppSpace.radiusHero,
              padding: const EdgeInsets.all(20),
              child: Row(children: [
                Semantics(
                  label: 'Wristband battery at $battery percent',
                  child: BandMark(size: 104, progress: battery / 100),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      StatusChip(label: 'Connected', color: c.accentText, background: c.accentSoft),
                      const Spacer(),
                      AppIcon(AppIcons.bluetooth, size: 14, color: c.muted),
                      const SizedBox(width: 4),
                      Text(band.signalWord, style: AppText.muted(c, size: 12)),
                    ]),
                    const SizedBox(height: 10),
                    Text(s.store.band?.displayName ?? 'My Band', style: AppText.label(c, size: 17)),
                    const SizedBox(height: 10),
                    Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          AnimatedCount(value: battery, style: AppText.mono(c, size: 30)),
                          Text('%', style: AppText.mono(c, size: 15, color: c.muted)),
                          const SizedBox(width: 8),
                          Flexible(child: Text(Fmt.batteryLeft(battery), style: AppText.muted(c, size: 12))),
                        ]),
                  ]),
                ),
              ]),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Rise(delay: const Duration(milliseconds: 60), child: _TalkCard(onTap: shell.openTalk)),
        const SizedBox(height: 16),
        Rise(
          delay: const Duration(milliseconds: 120),
          child: Row(children: [
            _QuickAction(
              icon: AppIcons.target,
              label: band.ringing ? 'Ringing' : 'Find band',
              active: band.ringing,
              onTap: () => band.setRinging(!band.ringing),
            ),
            const SizedBox(width: 10),
            _QuickAction(icon: AppIcons.vibration, label: 'Vibration', onTap: () => shell.goTo(AppTab.device)),
            const SizedBox(width: 10),
            _QuickAction(icon: AppIcons.volume, label: 'Volume', onTap: () => shell.goTo(AppTab.device)),
            const SizedBox(width: 10),
            _QuickAction(icon: AppIcons.sync, label: _synced ? 'Synced' : 'Sync', onTap: _sync),
          ]),
        ),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: Text('Latest reply', style: AppText.label(c, size: 15))),
          Pressable(
            onTap: () => shell.goTo(AppTab.chats),
            child: Text('View all', style: AppText.body(c, size: 13, weight: FontWeight.w500, color: c.accentText)),
          ),
        ]),
        const SizedBox(height: 10),
        Rise(
          delay: const Duration(milliseconds: 180),
          child: latest == null
              ? AppCard(
                  child: Text('Your conversations will show here. Press the band button or tap Talk to start.',
                      style: AppText.muted(c, size: 14)),
                )
              : _LatestReply(conversation: latest),
        ),
        const SizedBox(height: 24),
      ]),
    );
  }
}

class _TalkCard extends StatelessWidget {
  const _TalkCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return Pressable(
      onTap: onTap,
      semanticLabel: 'Tap to talk',
      pressedScale: 0.97,
      child: Container(
        height: 96,
        padding: const EdgeInsets.fromLTRB(16, 16, 20, 16),
        decoration: BoxDecoration(color: c.accent, borderRadius: BorderRadius.circular(28)),
        child: Row(children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(color: c.onAccent, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: AppIcon(AppIcons.mic, size: 28, color: c.accent),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tap to talk', style: AppText.title(c, size: 18).copyWith(color: c.onAccent)),
                  const SizedBox(height: 4),
                  Text('Or press the button on your band',
                      style: AppText.body(c, size: 13, color: c.onAccent.withValues(alpha: 0.75))),
                ]),
          ),
          AppIcon(AppIcons.arrowUpRight, size: 22, color: c.onAccent, strokeWidth: 2),
        ]),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon, required this.label, required this.onTap, this.active = false});
  final List<IconPart> icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return Expanded(
      child: Pressable(
        onTap: onTap,
        semanticLabel: label,
        child: PulseGlow(
          active: active,
          color: c.accent,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            height: 84,
            decoration: BoxDecoration(
              color: active ? c.accent : c.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: active ? c.accent : c.border),
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              AppIcon(icon, size: 22, color: active ? c.onAccent : c.text),
              const SizedBox(height: 8),
              Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body(c, size: 12, weight: FontWeight.w500, color: active ? c.onAccent : c.text)),
            ]),
          ),
        ),
      ),
    );
  }
}

class _LatestReply extends StatelessWidget {
  const _LatestReply({required this.conversation});
  final Conversation conversation;

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final question = conversation.messages.firstWhere((m) => m.fromUser, orElse: () => conversation.messages.first);
    return Pressable(
      pressedScale: 0.98,
      onTap: () => Navigator.of(context).push(slideRoute(ChatDetailScreen(id: conversation.id))),
      child: AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            IconTile(
              icon: AppIcons.sparkle,
              background: c.accentSoft,
              foreground: c.accentText,
              size: 26,
              iconSize: 14,
              circle: true,
            ),
            const SizedBox(width: 8),
            Expanded(
              child:
                  Text(question.text, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.muted(c, size: 13)),
            ),
            Text(Fmt.time(conversation.createdAt), style: AppText.mono(c, size: 12, color: c.muted)),
          ]),
          const SizedBox(height: 10),
          Text(conversation.preview, maxLines: 3, overflow: TextOverflow.ellipsis, style: AppText.body(c)),
        ]),
      ),
    );
  }
}

// ------------------------------------------------------------ disconnected

class _DisconnectedHome extends StatelessWidget {
  const _DisconnectedHome({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final s = context.services;
    final band = s.band;
    final paired = s.store.band != null;
    final busy = band.state == LinkState.connecting;
    final shell = HomeShell.of(context);
    return PageScaffold(
      scroll: true,
      safeBottom: false,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const _Header(),
        const SizedBox(height: 16),
        AppCard(
          radius: AppSpace.radiusHero,
          padding: const EdgeInsets.all(20),
          child: Row(children: [
            BandMark(size: 104, dashed: true, dotColor: c.faint, opacity: 0.55),
            const SizedBox(width: 18),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                StatusChip(
                  label: busy ? 'Connecting' : (paired ? 'Not connected' : 'No band yet'),
                  color: busy ? c.accentText : c.danger,
                  background: busy ? c.accentSoft : c.dangerSoft,
                ),
                const SizedBox(height: 10),
                Text(s.store.band?.displayName ?? 'Your band', style: AppText.label(c, size: 17)),
                const SizedBox(height: 10),
                Text(
                  paired
                      ? (band.lastSeen == null
                          ? 'Waiting for your band'
                          : 'Last seen ${Fmt.ago(band.lastSeen!)}${band.battery == null ? '' : ' with ${band.battery}% battery'}')
                      : 'Pair your wristband to start talking.',
                  style: AppText.muted(c),
                ),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        AppCard(
          radius: AppSpace.radiusHero,
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              IconTile(icon: AppIcons.bluetoothOff, background: c.dangerSoft, foreground: c.danger, iconSize: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(paired ? 'Your band is out of reach' : 'No band paired', style: AppText.label(c, size: 16)),
                  const SizedBox(height: 4),
                  Text(
                    paired
                        ? 'Make sure it is charged, switched on and within a few metres of your phone.'
                        : 'Hold the band button for 3 seconds, then search for it.',
                    style: AppText.muted(c),
                  ),
                ]),
              ),
            ]),
            const SizedBox(height: 14),
            PillButton(
              label: busy ? 'Searching for your band' : (paired ? 'Reconnect' : 'Pair a band'),
              height: 52,
              fontSize: 15,
              leading: busy ? Spinner(color: c.onAccent, size: 18) : null,
              onTap: busy
                  ? null
                  : () async {
                      if (!paired) return openPairing(context);
                      final ok = await band.reconnect();
                      if (!ok && context.mounted) showToast(context, 'Band not found. Try the checks below.');
                    },
            ),
            Center(
              child: LinkButton(
                label: 'Still not working? Troubleshoot',
                size: 13,
                onTap: () => Navigator.of(context).push(slideRoute(const PairFailScreen())),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        Pressable(
          pressedScale: 0.98,
          onTap: shell.openTalk,
          child: DashedCard(
            child: Row(children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: c.text, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: AppIcon(AppIcons.phone, size: 22, color: c.bg),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Talk from your phone', style: AppText.label(c, size: 15)),
                  const SizedBox(height: 3),
                  Text('Use the phone mic while the band is away', style: AppText.muted(c)),
                ]),
              ),
              AppIcon(AppIcons.chevronRight, size: 18, color: c.muted, strokeWidth: 2),
            ]),
          ),
        ),
        const SizedBox(height: 24),
      ]),
    );
  }
}

/// Card with a dashed outline (used for "Talk from your phone").
class DashedCard extends StatelessWidget {
  const DashedCard({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return CustomPaint(
      painter: _DashedBorder(c.border),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }
}

class _DashedBorder extends CustomPainter {
  _DashedBorder(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(24)));
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final m in path.computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, d + 5), paint);
        d += 9;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorder old) => old.color != color;
}

// ---------------------------------------------------------------- charging

class _ChargingHome extends StatelessWidget {
  const _ChargingHome({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final s = context.services;
    final band = s.band;
    final battery = band.battery ?? 0;
    final shell = HomeShell.of(context);
    return PageScaffold(
      scroll: true,
      safeBottom: false,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _Header(
          title: s.store.band?.displayName ?? 'My Band',
          subtitle: Row(children: [
            Dot(color: c.accent),
            const SizedBox(width: 6),
            Text('Connected and charging', style: AppText.muted(c, size: 13)),
          ]),
        ),
        const SizedBox(height: 16),
        AppCard(
          radius: AppSpace.radiusHero,
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          child: Column(children: [
            SizedBox(
              width: 220,
              height: 220,
              child: Stack(alignment: Alignment.center, children: [
                ChargeRing(value: battery / 100),
                Column(mainAxisSize: MainAxisSize.min, children: [
                  const PulsingBolt(),
                  const SizedBox(height: 4),
                  Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        AnimatedCount(value: battery, style: AppText.mono(c, size: 52).copyWith(height: 1)),
                        Text('%', style: AppText.mono(c, size: 22, color: c.muted)),
                      ]),
                  const SizedBox(height: 4),
                  Text(Fmt.chargeLeft(battery), style: AppText.muted(c)),
                ]),
              ]),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(color: c.accentSoft, borderRadius: BorderRadius.circular(999)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                AppIcon(AppIcons.magnet, size: 18, color: c.accentText, strokeWidth: 2),
                const SizedBox(width: 10),
                Text('Magnetic charger connected', style: AppText.label(c, size: 13, color: c.accentText)),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        Row(children: [
          const Expanded(child: _StatTile(label: 'Battery health', value: 'Good')),
          const SizedBox(width: 10),
          Expanded(
              child:
                  _StatTile(label: 'Firmware', value: band.firmware.isEmpty ? 'Unknown' : band.firmware, mono: true)),
        ]),
        const SizedBox(height: 16),
        Pressable(
          pressedScale: 0.98,
          onTap: shell.openTalk,
          child: AppCard(
            child: Row(children: [
              IconTile(icon: AppIcons.mic, background: c.accent, foreground: c.onAccent, circle: true),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Talk while it charges', style: AppText.label(c, size: 15)),
                  const SizedBox(height: 3),
                  Text('Replies play through your phone for now', style: AppText.muted(c)),
                ]),
              ),
              AppIcon(AppIcons.chevronRight, size: 18, color: c.muted, strokeWidth: 2),
            ]),
          ),
        ),
        const SizedBox(height: 24),
      ]),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value, this.mono = false});
  final String label;
  final String value;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return AppCard(
      padding: const EdgeInsets.all(14),
      radius: 20,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: AppText.muted(c, size: 12)),
        const SizedBox(height: 6),
        Text(value, style: mono ? AppText.mono(c, size: 18) : AppText.label(c, size: 18)),
      ]),
    );
  }
}

/// Large battery ring that fills up when it first appears.
class ChargeRing extends StatelessWidget {
  const ChargeRing({super.key, required this.value});
  final double value;

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: const Duration(milliseconds: 1600),
      curve: const Cubic(0.2, 0.8, 0.3, 1),
      builder: (context, v, _) => CustomPaint(
        size: const Size.square(220),
        painter: _RingPainter(v, c.track, c.accent),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.v, this.track, this.fill);
  final double v;
  final Color track;
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(center: size.center(Offset.zero), radius: size.width / 2 - 14);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, 6.2832, false, p..color = track);
    canvas.drawArc(rect, -1.5708, 6.2832 * v, false, p..color = fill);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.v != v || old.fill != fill;
}

/// Lightning bolt that softly pulses while charging.
class PulsingBolt extends StatefulWidget {
  const PulsingBolt({super.key});

  @override
  State<PulsingBolt> createState() => _PulsingBoltState();
}

class _PulsingBoltState extends State<PulsingBolt> with TickerProviderStateMixin, LoopingAnimation {
  @override
  Duration get loopDuration => const Duration(milliseconds: 1600);

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return AnimatedBuilder(
      animation: loop,
      builder: (context, child) {
        final k = (1 - (loop.value * 2 - 1).abs());
        return Opacity(opacity: 1 - 0.45 * k, child: Transform.scale(scale: 1 - 0.1 * k, child: child));
      },
      child: AppIcon(AppIcons.bolt, size: 26, color: c.accent),
    );
  }
}

/// Counts up to a number when it first appears.
class AnimatedCount extends StatelessWidget {
  const AnimatedCount({super.key, required this.value, required this.style});
  final int value;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Text('${v.round()}', style: style),
    );
  }
}
