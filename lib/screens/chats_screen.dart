import 'package:flutter/material.dart';

import '../app.dart';
import '../models/models.dart';
import '../state/scope.dart';
import '../theme/tokens.dart';
import '../ui/format.dart';
import '../ui/icons.dart';
import '../ui/motion.dart';
import '../ui/widgets.dart';
import 'chat_detail_screen.dart';
import 'home_shell.dart';

enum ChatFilter { all, band, phone, pinned }

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  ChatFilter _filter = ChatFilter.all;
  String _query = '';

  bool _keep(Conversation c) {
    if (c.messages.isEmpty) return false;
    final f = switch (_filter) {
      ChatFilter.all => true,
      ChatFilter.band => c.source == MicSource.band,
      ChatFilter.phone => c.source == MicSource.phone,
      ChatFilter.pinned => c.pinned,
    };
    if (!f) return false;
    if (_query.isEmpty) return true;
    final q = _query.toLowerCase();
    return c.title.toLowerCase().contains(q) || c.messages.any((m) => m.text.toLowerCase().contains(q));
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final store = context.store;
    return PageScaffold(
      safeBottom: false,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Watch(
        listenables: [store],
        builder: (context) {
          final list = store.conversations.where(_keep).toList();
          final groups = <String, List<Conversation>>{};
          for (final x in list) {
            groups.putIfAbsent(Fmt.group(x.createdAt), () => []).add(x);
          }
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            SizedBox(
              height: 44,
              child: Row(children: [
                Expanded(child: Text('Conversations', style: AppText.display(c))),
                CircleIconButton(
                  icon: AppIcons.plus,
                  label: 'New conversation',
                  background: c.accent,
                  foreground: c.onAccent,
                  borderColor: c.accent,
                  onTap: () => HomeShell.of(context).openTalk(),
                ),
              ]),
            ),
            const SizedBox(height: 16),
            _SearchField(onChanged: (v) => setState(() => _query = v.trim())),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                for (final f in ChatFilter.values) ...[
                  _FilterPill(
                    label: switch (f) {
                      ChatFilter.all => 'All',
                      ChatFilter.band => 'Wristband',
                      ChatFilter.phone => 'Phone',
                      ChatFilter.pinned => 'Pinned',
                    },
                    selected: _filter == f,
                    onTap: () => setState(() => _filter = f),
                  ),
                  const SizedBox(width: 8),
                ],
              ]),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: list.isEmpty
                  ? _Empty(searching: _query.isNotEmpty)
                  : ListView(
                      padding: const EdgeInsets.only(bottom: 24),
                      physics: const BouncingScrollPhysics(),
                      children: [
                        for (final g in groups.entries) ...[
                          Rise(
                            key: ValueKey('${g.key}$_filter'),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                              SectionLabel(g.key),
                              const SizedBox(height: 8),
                              GroupCard(children: [
                                for (var i = 0; i < g.value.length; i++) _ChatRow(convo: g.value[i], first: i == 0),
                              ]),
                              const SizedBox(height: 16),
                            ]),
                          ),
                        ],
                      ],
                    ),
            ),
          ]);
        },
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.onChanged});
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.border),
      ),
      child: Row(children: [
        AppIcon(AppIcons.search, size: 18, color: c.muted),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            onChanged: onChanged,
            cursorColor: c.accent,
            style: AppText.body(c, height: 1.2),
            decoration: InputDecoration(
              isCollapsed: true,
              border: InputBorder.none,
              hintText: 'Search conversations',
              hintStyle: AppText.body(c, color: c.muted, height: 1.2),
            ),
          ),
        ),
      ]),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? c.text : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? c.text : c.border),
        ),
        child: Text(label, style: AppText.label(c, size: 13, color: selected ? c.bg : c.text)),
      ),
    );
  }
}

class _ChatRow extends StatelessWidget {
  const _ChatRow({required this.convo, required this.first});
  final Conversation convo;
  final bool first;

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final band = convo.source == MicSource.band;
    return Pressable(
      pressedScale: 0.98,
      onTap: () => Navigator.of(context).push(slideRoute(ChatDetailScreen(id: convo.id))),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(border: first ? null : Border(top: BorderSide(color: c.border))),
        child: Row(children: [
          IconTile(
            icon: band ? AppIcons.watch : AppIcons.phone,
            background: band ? c.accentSoft : c.surface2,
            foreground: band ? c.accentText : c.text,
            size: 40,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(
                  child: Text(convo.title.isEmpty ? 'Conversation' : convo.title,
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.label(c, size: 15)),
                ),
                if (convo.pinned) ...[
                  const SizedBox(width: 6),
                  AppIcon(AppIcons.pin, size: 13, color: c.accentText, strokeWidth: 2, semanticLabel: 'Pinned'),
                ],
              ]),
              const SizedBox(height: 3),
              Text(convo.preview, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.muted(c)),
            ]),
          ),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(Fmt.shortWhen(convo.createdAt), style: AppText.muted(c, size: 12)),
            const SizedBox(height: 4),
            Text(Fmt.duration(convo.totalMs),
                style: AppText.mono(c, size: 11, weight: FontWeight.w400, color: c.muted)),
          ]),
        ]),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.searching});
  final bool searching;

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: Column(children: [
        AppIcon(AppIcons.chat, size: 32, color: c.muted, strokeWidth: 1.6),
        const SizedBox(height: 10),
        Text(searching ? 'No matches' : 'Nothing here yet', style: AppText.label(c, size: 15)),
        const SizedBox(height: 6),
        Text(
          searching ? 'Try a different word.' : 'Conversations you have in this filter will show up here.',
          textAlign: TextAlign.center,
          style: AppText.muted(c),
        ),
      ]),
    );
  }
}
