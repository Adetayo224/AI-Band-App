import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/audio_codec.dart';
import '../services/phone_audio.dart';
import '../state/scope.dart';
import '../theme/tokens.dart';
import '../ui/icons.dart';
import '../ui/motion.dart';
import '../ui/widgets.dart';
import 'dart:io';

class VoiceScreen extends StatefulWidget {
  const VoiceScreen({super.key});

  @override
  State<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends State<VoiceScreen> {
  String? _playing;
  String? _loading;
  late PhoneAudio _audio;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _audio = context.services.audio;
  }

  @override
  void dispose() {
    _audio.stopPlayback();
    super.dispose();
  }

  /// Plays a short sample of a voice (needs the OpenAI key).
  Future<void> _preview(AssistantVoice v) async {
    if (_playing == v.id) {
      await _audio.stopPlayback();
      setState(() => _playing = null);
      return;
    }
    final s = context.services;
    if (!s.ai.configured) {
      showToast(context, 'Voice previews work once the OpenAI key is added.');
      return;
    }
    setState(() => _loading = v.id);
    try {
      final name = s.store.profile.callName;
      final text = 'Hi${name.isEmpty ? '' : ' $name'}, I am ${v.name}. This is how I will sound on your band.';
      final Uint8List pcm = await s.ai.speak(text, voice: v.openAiVoice, speed: s.store.settings.speed);
      final dir = await PhoneAudio.audioDir();
      final f = File('${dir.path}/preview_${v.id}.wav');
      await f.writeAsBytes(Pcm.wav(pcm, 24000), flush: true);
      if (!mounted) return;
      setState(() {
        _loading = null;
        _playing = v.id;
      });
      await _audio.playFile(f.path);
    } catch (e) {
      if (mounted) showToast(context, '$e');
    }
    if (mounted) {
      setState(() {
        _loading = null;
        if (_playing == v.id) _playing = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final store = context.store;
    return PageScaffold(
      scroll: true,
      child: Watch(
        listenables: [store],
        builder: (context) {
          final s = store.settings;
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const SubHeader(title: 'Assistant voice', backLabel: 'Back to settings'),
            const SizedBox(height: 16),
            for (final v in AssistantVoice.all) ...[
              _VoiceTile(
                voice: v,
                selected: s.voiceId == v.id,
                playing: _playing == v.id,
                loading: _loading == v.id,
                onPick: () => store.updateSettings((x) => x.voiceId = v.id),
                onPreview: () => _preview(v),
              ),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 6),
            AppCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Row(children: [
                  Expanded(child: Text('Speaking speed', style: AppText.label(c))),
                  Text(speedLabels[s.speedIndex], style: AppText.mono(c, size: 13, color: c.muted)),
                ]),
                Slider(
                  value: s.speedIndex.toDouble(),
                  min: 0,
                  max: 4,
                  divisions: 4,
                  onChanged: (v) => store.updateSettings((x) => x.speedIndex = v.round()),
                ),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Slower', style: AppText.muted(c, size: 11)),
                  Text('Faster', style: AppText.muted(c, size: 11)),
                ]),
                const SizedBox(height: 18),
                Text('Reply length', style: AppText.label(c)),
                const SizedBox(height: 10),
                Segmented<ReplyLength>(
                  background: c.bg,
                  value: s.replyLength,
                  onChanged: (v) => store.updateSettings((x) => x.replyLength = v),
                  options: const [
                    SegmentOption(ReplyLength.short, 'Short'),
                    SegmentOption(ReplyLength.balanced, 'Balanced'),
                    SegmentOption(ReplyLength.detailed, 'Detailed'),
                  ],
                ),
                const SizedBox(height: 10),
                Text('Short replies save band battery and play faster on the speaker.',
                    style: AppText.muted(c, size: 12)),
              ]),
            ),
          ]);
        },
      ),
    );
  }
}

class _VoiceTile extends StatelessWidget {
  const _VoiceTile({
    required this.voice,
    required this.selected,
    required this.playing,
    required this.loading,
    required this.onPick,
    required this.onPreview,
  });

  final AssistantVoice voice;
  final bool selected;
  final bool playing;
  final bool loading;
  final VoidCallback onPick;
  final VoidCallback onPreview;

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: BoxDecoration(
        color: selected ? c.accentSoft.withValues(alpha: c.isLight ? 0.6 : 0.65) : c.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: selected ? c.accent : c.border, width: 1.5),
      ),
      child: Row(children: [
        Expanded(
          child: Semantics(
            selected: selected,
            button: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onPick,
              child: Row(children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: selected ? c.accent : c.faint, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: AnimatedScale(
                    scale: selected ? 1 : 0,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutBack,
                    child: Container(
                        width: 10, height: 10, decoration: BoxDecoration(color: c.accent, shape: BoxShape.circle)),
                  ),
                ),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(voice.name, style: AppText.label(c, size: 16)),
                  const SizedBox(height: 2),
                  Text(voice.description, style: AppText.muted(c)),
                ]),
              ]),
            ),
          ),
        ),
        Pressable(
          onTap: onPreview,
          semanticLabel: playing ? 'Stop preview of ${voice.name}' : 'Play preview of ${voice.name}',
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: playing ? c.accent : c.text, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: loading
                ? Spinner(color: c.bg, size: 16, strokeWidth: 2)
                : playing
                    ? EqBars(
                        heights: const [14, 14, 14],
                        color: c.onAccent,
                        barWidth: 3,
                        gap: 3,
                        duration: const Duration(milliseconds: 800),
                        stagger: 0.15,
                      )
                    : AppIcon(AppIcons.play, size: 16, color: c.bg),
          ),
        ),
      ]),
    );
  }
}
