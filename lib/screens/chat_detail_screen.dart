import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app.dart';
import '../models/models.dart';
import '../services/phone_audio.dart';
import '../state/scope.dart';
import '../theme/tokens.dart';
import '../ui/format.dart';
import '../ui/icons.dart';
import '../ui/motion.dart';
import '../ui/widgets.dart';
import 'talk_screen.dart';

class ChatDetailScreen extends StatefulWidget {
  const ChatDetailScreen({super.key, required this.id});
  final String id;

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  int? _playing;
  late PhoneAudio _audio;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _audio = context.services.audio;
  }

  static const _wave = <double>[8, 14, 20, 12, 18, 22, 10, 16, 20, 8, 14, 18, 10, 6, 12, 8];

  Future<void> _play(ChatMessage m, int i) async {
    final audio = _audio;
    if (_playing == i) {
      await audio.stopPlayback();
      setState(() => _playing = null);
      return;
    }
    if (m.audioPath == null || !File(m.audioPath!).existsSync()) {
      showToast(context, 'The audio for this message is no longer on the phone.');
      return;
    }
    await audio.stopPlayback();
    setState(() => _playing = i);
    await audio.playFile(m.audioPath!);
    if (mounted && _playing == i) setState(() => _playing = null);
  }

  @override
  void dispose() {
    _audio.stopPlayback();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final store = context.store;
    return Watch(
      listenables: [store],
      builder: (context) {
        final convo = store.conversationById(widget.id);
        if (convo == null) {
          return const PageScaffold(child: Column(children: [SubHeader(title: 'Conversation'), Spacer()]));
        }
        final band = convo.source == MicSource.band;
        return PageScaffold(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            SubHeader(
              title: convo.title.isEmpty ? 'Conversation' : convo.title,
              subtitle: Fmt.dayAndTime(convo.createdAt),
              backLabel: 'Back to conversations',
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(color: c.accentSoft, borderRadius: BorderRadius.circular(999)),
                  child: Row(children: [
                    AppIcon(band ? AppIcons.watch : AppIcons.phone, size: 14, color: c.accentText, strokeWidth: 2),
                    const SizedBox(width: 6),
                    Text(band ? 'From wristband' : 'From phone',
                        style: AppText.label(c, size: 12, color: c.accentText)),
                  ]),
                ),
                const SizedBox(width: 8),
                _Chip(icon: AppIcons.clock, text: Fmt.duration(convo.totalMs), mono: true),
                const SizedBox(width: 8),
                _Chip(text: '${convo.messages.length} messages'),
              ]),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: ListView.separated(
                physics: const BouncingScrollPhysics(),
                itemCount: convo.messages.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final m = convo.messages[i];
                  final on = _playing == i;
                  return Rise(
                    delay: Duration(milliseconds: 40 * i.clamp(0, 6)),
                    child: Align(
                      alignment: m.fromUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                        decoration: BoxDecoration(
                          color: m.fromUser ? c.surface2 : c.surface,
                          border: Border.all(color: m.fromUser ? c.surface2 : c.border),
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(20),
                            topRight: const Radius.circular(20),
                            bottomLeft: Radius.circular(m.fromUser ? 20 : 6),
                            bottomRight: Radius.circular(m.fromUser ? 6 : 20),
                          ),
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          SelectableText(m.text, style: AppText.body(c)),
                          const SizedBox(height: 10),
                          Row(mainAxisSize: MainAxisSize.min, children: [
                            Pressable(
                              onTap: () => _play(m, i),
                              semanticLabel: on ? 'Pause audio' : 'Play audio',
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(color: on ? c.accent : c.text, shape: BoxShape.circle),
                                alignment: Alignment.center,
                                child: AppIcon(on ? AppIcons.pause : AppIcons.play,
                                    size: 14, color: on ? c.onAccent : c.bg),
                              ),
                            ),
                            const SizedBox(width: 10),
                            EqBars(
                              heights: _wave,
                              active: on,
                              restScale: 0.35,
                              barWidth: 3,
                              gap: 3,
                              duration: const Duration(milliseconds: 900),
                              stagger: 0.06,
                              color: on ? c.accent : c.faint,
                            ),
                            const SizedBox(width: 10),
                            Text(Fmt.duration(m.durationMs), style: AppText.mono(c, size: 12, color: c.muted)),
                          ]),
                        ]),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Row(children: [
              _Action(
                icon: AppIcons.pin,
                label: convo.pinned ? 'Pinned' : 'Pin',
                active: convo.pinned,
                onTap: () => store.togglePin(convo),
              ),
              const SizedBox(width: 8),
              _Action(
                icon: AppIcons.copy,
                label: 'Copy',
                onTap: () {
                  final text = convo.messages.map((m) => '${m.fromUser ? 'You' : 'Assistant'}: ${m.text}').join('\n');
                  Clipboard.setData(ClipboardData(text: text));
                  showToast(context, 'Conversation copied');
                },
              ),
              const SizedBox(width: 8),
              _Action(
                icon: AppIcons.share,
                label: 'Share',
                onTap: () {
                  final text = convo.messages.map((m) => m.text).join('\n\n');
                  Clipboard.setData(ClipboardData(text: text));
                  showToast(context, 'Copied. Paste it into any app to share.');
                },
              ),
              const SizedBox(width: 8),
              _Action(
                icon: AppIcons.trash,
                label: 'Delete',
                danger: true,
                onTap: () async {
                  final ok = await showConfirmSheet(
                    context,
                    title: 'Delete this conversation?',
                    message: 'The transcript and its audio are removed from this phone.',
                    confirmLabel: 'Delete',
                    icon: AppIcons.trash,
                  );
                  if (ok == true && context.mounted) {
                    Navigator.of(context).pop();
                    await store.deleteConversation(convo);
                  }
                },
              ),
            ]),
            const SizedBox(height: 14),
            PillButton(
              label: 'Continue conversation',
              icon: AppIcons.mic,
              onTap: () {
                context.assistant.resume(convo);
                Navigator.of(context).push(riseRoute(const TalkScreen()));
              },
            ),
          ]),
        );
      },
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({this.icon, required this.text, this.mono = false});
  final List<IconPart>? icon;
  final String text;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), border: Border.all(color: c.border)),
      child: Row(children: [
        if (icon != null) ...[AppIcon(icon!, size: 14, color: c.muted, strokeWidth: 2), const SizedBox(width: 6)],
        Text(text, style: mono ? AppText.mono(c, size: 12, color: c.muted) : AppText.muted(c, size: 12)),
      ]),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action(
      {required this.icon, required this.label, required this.onTap, this.active = false, this.danger = false});
  final List<IconPart> icon;
  final String label;
  final VoidCallback onTap;
  final bool active;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final fg = danger ? c.danger : (active ? c.accentText : c.text);
    return Expanded(
      child: Pressable(
        onTap: onTap,
        semanticLabel: label,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          height: 64,
          decoration: BoxDecoration(
            color: active ? c.accentSoft : c.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: c.border),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            AppIcon(icon, size: 20, color: fg),
            const SizedBox(height: 6),
            Text(label, style: AppText.body(c, size: 12, weight: FontWeight.w500, color: fg)),
          ]),
        ),
      ),
    );
  }
}
