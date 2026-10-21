import 'package:flutter/material.dart';

import '../app.dart';
import '../models/models.dart';
import '../state/scope.dart';
import '../theme/tokens.dart';
import '../ui/format.dart';
import '../ui/icons.dart';
import '../ui/motion.dart';
import '../ui/widgets.dart';
import 'firmware_screen.dart';
import 'settings_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final store = context.store;
    return PageScaffold(
      child: Watch(
        listenables: [store],
        builder: (context) {
          final today = store.notices.where((n) => Fmt.group(n.at) == 'Today').toList();
          final earlier = store.notices.where((n) => Fmt.group(n.at) != 'Today').toList();
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            SubHeader(
              title: 'Notifications',
              backLabel: 'Back to home',
              trailing: Pressable(
                onTap: store.hasUnread ? store.markAllRead : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                  child: Text('Mark all read',
                      style: AppText.label(c, size: 14, color: store.hasUnread ? c.accentText : c.muted)),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: store.notices.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.only(top: 60),
                      child: Column(children: [
                        AppIcon(AppIcons.bell, size: 32, color: c.muted, strokeWidth: 1.6),
                        const SizedBox(height: 10),
                        Text('You are all caught up', style: AppText.label(c, size: 15)),
                        const SizedBox(height: 6),
                        Text('Band alerts and updates will appear here.', style: AppText.muted(c)),
                      ]),
                    )
                  : ListView(physics: const BouncingScrollPhysics(), children: [
                      if (today.isNotEmpty) _Group(label: 'Today', items: today),
                      if (earlier.isNotEmpty) _Group(label: 'Earlier', items: earlier),
                    ]),
            ),
            PillButton(
              label: 'Notification settings',
              tone: ButtonTone.outline,
              height: 48,
              fontSize: 14,
              icon: AppIcons.sliders,
              onTap: () => Navigator.of(context).push(slideRoute(const SettingsScreen(standalone: true))),
            ),
          ]);
        },
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.label, required this.items});
  final String label;
  final List<AppNotice> items;

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return Rise(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SectionLabel(label),
          const SizedBox(height: 8),
          GroupCard(children: [
            for (var i = 0; i < items.length; i++) _Row(n: items[i], first: i == 0, c: c),
          ]),
        ]),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.n, required this.first, required this.c});
  final AppNotice n;
  final bool first;
  final AppColors c;

  @override
  Widget build(BuildContext context) {
    final (icon, bg, fg) = switch (n.kind) {
      NoticeKind.reminder => (AppIcons.alarm, c.accentSoft, c.accentText),
      NoticeKind.firmware => (AppIcons.download, c.accentSoft, c.accentText),
      NoticeKind.battery => (AppIcons.batteryLow, c.warnSoft, c.warn),
      NoticeKind.disconnected => (AppIcons.bluetoothOff, c.dangerSoft, c.danger),
      NoticeKind.paired => (AppIcons.check, c.surface2, c.text),
    };
    return Pressable(
      pressedScale: 0.98,
      onTap: () {
        if (n.kind == NoticeKind.firmware) {
          Navigator.of(context).push(slideRoute(const FirmwareScreen()));
        } else {
          Navigator.of(context).maybePop();
        }
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(border: first ? null : Border(top: BorderSide(color: c.border))),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          IconTile(icon: icon, background: bg, foreground: fg, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(n.title, style: AppText.body(c, weight: n.read ? FontWeight.w500 : FontWeight.w600)),
              const SizedBox(height: 3),
              Text(n.body, style: AppText.muted(c)),
            ]),
          ),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(Fmt.shortWhen(n.at), style: AppText.muted(c, size: 12)),
            const SizedBox(height: 8),
            Dot(color: n.read ? Colors.transparent : c.accent, size: 8),
          ]),
        ]),
      ),
    );
  }
}
