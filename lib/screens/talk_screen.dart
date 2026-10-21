import 'package:flutter/material.dart';

import '../app.dart';
import '../models/models.dart';
import '../services/assistant.dart';
import '../state/scope.dart';
import '../theme/tokens.dart';
import '../ui/icons.dart';
import '../ui/motion.dart';
import '../ui/widgets.dart';
import 'chat_detail_screen.dart';

/// Live conversation: the big orb moves through listening, thinking and
/// speaking while captions show what was said.
class TalkScreen extends StatefulWidget {
  const TalkScreen({super.key});

  @override
  State<TalkScreen> createState() => _TalkScreenState();
}

class _TalkScreenState extends State<TalkScreen> {
  late Assistant _a;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _a = context.assistant;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_a.phase == TalkPhase.idle) {
        _a.prepare();
        _a.startListening();
      }
    });
  }

  Future<void> _end() async {
    await _a.end();
    if (mounted) Navigator.of(context).pop();
  }

  static const _heights = <double>[
    10,
    18,
    26,
    14,
    34,
    22,
    40,
    28,
    16,
    36,
    24,
    44,
    30,
    18,
    38,
    26,
    42,
    20,
    32,
    14,
    28,
    36,
    22,
    12,
    30,
    18,
    24,
    10
  ];

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final s = context.services;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _end();
      },
      child: PageScaffold(
        child: Watch(
          listenables: [_a, s.band, s.store],
          builder: (context) {
            final phase = _a.phase;
            final source = _a.effectiveSource;
            final bandOk = _a.bandReady;
            final captions = s.store.settings.captions;
            final (title, hint) = switch (phase) {
              TalkPhase.idle => ('Tap to talk', _a.error ?? 'Tap the circle or press the button on your band.'),
              TalkPhase.listening => (
                  'Listening',
                  source == MicSource.band
                      ? 'Speak now. Press the band button or tap the circle when you finish.'
                      : 'Speak now. Tap the circle when you finish.'
                ),
              TalkPhase.thinking => ('Thinking', 'Your assistant is working on an answer.'),
              TalkPhase.speaking => (
                  'Speaking',
                  bandOk && !s.band.charging && source == MicSource.band
                      ? 'Playing the reply on your band speaker.'
                      : 'Playing the reply on your phone.'
                ),
            };
            return Column(children: [
              // Header
              SizedBox(
                height: 44,
                child: Row(children: [
                  CircleIconButton(icon: AppIcons.chevronLeft, label: 'Back to home', onTap: _end),
                  Expanded(
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text('Live conversation', style: AppText.label(c, size: 15)),
                      const SizedBox(height: 2),
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Dot(color: s.band.connected ? c.accent : c.faint),
                        const SizedBox(width: 6),
                        Text(
                          s.band.connected ? '${s.store.band?.displayName ?? 'Band'} connected' : 'Using your phone',
                          style: AppText.muted(c, size: 12),
                        ),
                      ]),
                    ]),
                  ),
                  CircleIconButton(
                    icon: AppIcons.captions,
                    label: captions ? 'Hide captions' : 'Show captions',
                    background: captions ? c.accentSoft : c.surface,
                    foreground: captions ? c.accent : c.text,
                    onTap: () => s.store.updateSettings((x) => x.captions = !x.captions),
                  ),
                ]),
              ),
              const SizedBox(height: 16),
              Opacity(
                opacity: phase == TalkPhase.listening ? 0.5 : 1,
                child: Segmented<MicSource>(
                  solid: true,
                  height: 40,
                  value: bandOk ? _a.source : MicSource.phone,
                  onChanged: (v) {
                    if (v == MicSource.band && !bandOk) {
                      showToast(context, 'Connect your band to use its microphone.');
                      return;
                    }
                    _a.setSource(v);
                  },
                  options: const [
                    SegmentOption(MicSource.band, 'Band mic'),
                    SegmentOption(MicSource.phone, 'Phone mic')
                  ],
                ),
              ),
              // Orb (scales down on small phones)
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    _Orb(phase: phase, onTap: _a.orbTapped),
                    const SizedBox(height: 22),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: Column(key: ValueKey('$phase${_a.error}'), children: [
                        Text(title, style: AppText.title(c)),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: 290,
                          child: Text(hint,
                              textAlign: TextAlign.center,
                              style: AppText.body(c,
                                  size: 14,
                                  color: _a.error != null && phase == TalkPhase.idle ? c.danger : c.muted,
                                  height: 1.4)),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      height: 44,
                      child: Center(
                        child: EqBars(
                          heights: [
                            for (final h in _heights)
                              h *
                                  (phase == TalkPhase.listening
                                      ? (0.55 + 0.45 * _a.level.clamp(0, 1) * 2).clamp(0.55, 1.0)
                                      : 1),
                          ],
                          active: phase == TalkPhase.listening || phase == TalkPhase.speaking,
                          color: phase == TalkPhase.listening
                              ? c.text
                              : phase == TalkPhase.speaking
                                  ? c.accent
                                  : (c.isLight ? const Color(0xFFC9CCC0) : c.track),
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
              // Captions
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                child: captions ? _Captions(a: _a) : const SizedBox(width: double.infinity),
              ),
              // Controls
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Expanded(
                  child: _Control(
                    label: _a.muted ? 'Unmute' : 'Mute',
                    size: 56,
                    background: _a.muted ? c.text : c.surface,
                    foreground: _a.muted ? c.bg : c.text,
                    icon: AppIcons.micOff,
                    onTap: _a.toggleMute,
                  ),
                ),
                Expanded(
                  child: _Control(
                    label: 'End',
                    size: 72,
                    background: c.text,
                    foreground: c.bg,
                    icon: AppIcons.stop,
                    iconSize: 24,
                    border: false,
                    onTap: _end,
                  ),
                ),
                Expanded(
                  child: _Control(
                    label: 'History',
                    size: 56,
                    background: c.surface,
                    foreground: c.text,
                    icon: AppIcons.chat,
                    onTap: () {
                      final convo = _a.conversation;
                      if (convo == null || convo.messages.isEmpty) {
                        showToast(context, 'Nothing saved in this conversation yet.');
                        return;
                      }
                      Navigator.of(context).push(slideRoute(ChatDetailScreen(id: convo.id)));
                    },
                  ),
                ),
              ]),
            ]);
          },
        ),
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({required this.phase, required this.onTap});
  final TalkPhase phase;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final thinking = phase == TalkPhase.thinking;
    final icon = switch (phase) {
      TalkPhase.idle || TalkPhase.listening => AppIcons.mic,
      TalkPhase.thinking => AppIcons.sparkles,
      TalkPhase.speaking => AppIcons.volume,
    };
    return Semantics(
      button: true,
      label: switch (phase) {
        TalkPhase.idle => 'Start talking',
        TalkPhase.listening => 'Finish speaking',
        TalkPhase.thinking => 'Thinking',
        TalkPhase.speaking => 'Stop the reply',
      },
      child: Pressable(
        onTap: onTap,
        pressedScale: 0.95,
        child: SizedBox(
          width: 228,
          height: 228,
          child: Stack(alignment: Alignment.center, clipBehavior: Clip.none, children: [
            if (phase == TalkPhase.listening) ...[
              Positioned.fill(child: Breathe(color: c.accent)),
              Positioned.fill(child: Breathe(color: c.accent, offset: 0.5)),
            ],
            if (thinking)
              SizedBox(
                  width: 204,
                  height: 204,
                  child: Spinner(
                      color: c.accent,
                      size: 204,
                      strokeWidth: 2,
                      dashed: true,
                      duration: const Duration(milliseconds: 1600))),
            if (phase == TalkPhase.speaking)
              SizedBox(
                  width: 212,
                  height: 212,
                  child: PingRings(
                      color: c.accent,
                      count: 2,
                      startScale: 0.83,
                      strokeWidth: 2,
                      duration: const Duration(milliseconds: 2600))),
            AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              width: 176,
              height: 176,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: thinking ? c.surface2 : c.accent,
                boxShadow: phase == TalkPhase.idle
                    ? [BoxShadow(color: c.accent.withValues(alpha: 0.25), blurRadius: 40)]
                    : null,
              ),
              alignment: Alignment.center,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, a) =>
                    ScaleTransition(scale: a, child: FadeTransition(opacity: a, child: child)),
                child: AppIcon(icon,
                    key: ValueKey(phase == TalkPhase.idle ? TalkPhase.listening : phase),
                    size: 56,
                    color: thinking ? c.accent : c.onAccent,
                    strokeWidth: 1.6),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _Captions extends StatelessWidget {
  const _Captions({required this.a});
  final Assistant a;

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final listening = a.phase == TalkPhase.listening;
    final showUser = a.userText.isNotEmpty || listening;
    return Container(
      constraints: const BoxConstraints(minHeight: 132),
      margin: const EdgeInsets.only(bottom: 22),
      alignment: Alignment.bottomCenter,
      child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
        if (showUser)
          Align(
            alignment: Alignment.centerRight,
            child: Rise(
              key: ValueKey('u${a.userText.isEmpty}'),
              offset: 10,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 290),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: c.surface2,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(6),
                  ),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Flexible(
                    child: Text(
                      a.userText.isEmpty ? (a.muted ? 'Muted' : 'Listening') : a.userText,
                      style: AppText.body(c, color: a.userText.isEmpty ? c.muted : c.text, height: 1.4),
                    ),
                  ),
                  if (listening) BlinkCaret(color: c.accent),
                ]),
              ),
            ),
          ),
        if (a.phase == TalkPhase.thinking) ...[
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Rise(
              offset: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                decoration: BoxDecoration(
                  color: c.surface,
                  border: Border.all(color: c.border),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                    bottomLeft: Radius.circular(6),
                  ),
                ),
                child: TypingDots(color: c.accent),
              ),
            ),
          ),
        ],
        if (a.replyText.isNotEmpty && a.phase != TalkPhase.thinking && !listening) ...[
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Rise(
              key: ValueKey(a.replyText),
              offset: 10,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 310),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: c.surface,
                  border: Border.all(color: c.border),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                    bottomLeft: Radius.circular(6),
                  ),
                ),
                child: Text(a.replyText, maxLines: 6, overflow: TextOverflow.ellipsis, style: AppText.body(c)),
              ),
            ),
          ),
        ],
      ]),
    );
  }
}

class _Control extends StatelessWidget {
  const _Control({
    required this.label,
    required this.size,
    required this.background,
    required this.foreground,
    required this.icon,
    required this.onTap,
    this.iconSize = 22,
    this.border = true,
  });

  final String label;
  final double size;
  final Color background;
  final Color foreground;
  final List<IconPart> icon;
  final VoidCallback onTap;
  final double iconSize;
  final bool border;

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: background,
            shape: BoxShape.circle,
            border: border ? Border.all(color: c.border) : null,
          ),
          alignment: Alignment.center,
          child: AppIcon(icon, size: iconSize, color: foreground),
        ),
        const SizedBox(height: 8),
        Text(label, style: AppText.body(c, size: 12, weight: FontWeight.w500, color: c.muted)),
      ]),
    );
  }
}
