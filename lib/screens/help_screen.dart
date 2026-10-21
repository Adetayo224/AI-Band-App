import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app.dart';
import '../state/scope.dart';
import '../theme/tokens.dart';
import '../ui/icons.dart';
import '../ui/widgets.dart';
import 'onboarding.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  int? _open = 0;
  String _q = '';
  bool _sent = false;

  static const _faqs = [
    (
      'Why is my band not connecting?',
      'Check that Bluetooth is on, the band is charged and within 1 metre. Hold the band button for 3 seconds until it vibrates twice, then search again.'
    ),
    (
      'How long does the battery last?',
      'Battery life depends on how often you talk to it. Short replies and a lower speaker volume help it last longer.'
    ),
    (
      'Can I wear it in the shower?',
      'The band is sealed against splashes. Avoid swimming or long time under water until its waterproof rating is confirmed.'
    ),
    (
      'How do I update the firmware?',
      'Go to Device and tap Install when an update is ready. Keep the band near your phone until it restarts.'
    ),
    (
      'Where is my data stored?',
      'Your details, settings and conversations are stored only on this phone. Your voice is sent to the AI service to get an answer.'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final faqs = _faqs
        .asMap()
        .entries
        .where((e) => _q.isEmpty || e.value.$1.toLowerCase().contains(_q) || e.value.$2.toLowerCase().contains(_q))
        .toList();
    return PageScaffold(
      scroll: true,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const SubHeader(title: 'Help', backLabel: 'Back to settings'),
        const SizedBox(height: 14),
        Container(
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
                onChanged: (v) => setState(() => _q = v.trim().toLowerCase()),
                cursorColor: c.accent,
                style: AppText.body(c, height: 1.2),
                decoration: InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
                  hintText: 'Search for an answer',
                  hintStyle: AppText.body(c, color: c.muted, height: 1.2),
                ),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.7,
          children: [
            _Topic(
                icon: AppIcons.bluetooth,
                label: 'Pairing',
                onTap: () => Navigator.of(context).push(slideRoute(const PairFailScreen()))),
            _Topic(icon: AppIcons.boltLine, label: 'Charging', onTap: () => setState(() => _open = 1)),
            _Topic(icon: AppIcons.drop, label: 'Water and care', onTap: () => setState(() => _open = 2)),
            _Topic(icon: AppIcons.button, label: 'Band button', onTap: () => setState(() => _open = 0)),
          ],
        ),
        const SizedBox(height: 16),
        const SectionLabel('Common questions'),
        const SizedBox(height: 8),
        GroupCard(children: [
          for (var i = 0; i < faqs.length; i++)
            Container(
              decoration: BoxDecoration(border: i == 0 ? null : Border(top: BorderSide(color: c.border))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Semantics(
                  button: true,
                  expanded: _open == faqs[i].key,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() => _open = _open == faqs[i].key ? null : faqs[i].key),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                      child: Row(children: [
                        Expanded(child: Text(faqs[i].value.$1, style: AppText.label(c))),
                        AnimatedRotation(
                          turns: _open == faqs[i].key ? 0.5 : 0,
                          duration: const Duration(milliseconds: 220),
                          child: AppIcon(AppIcons.chevronDown, size: 16, color: c.muted, strokeWidth: 2),
                        ),
                      ]),
                    ),
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  child: _open == faqs[i].key
                      ? Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                          child: Text(faqs[i].value.$2, style: AppText.muted(c, size: 13)),
                        )
                      : const SizedBox(width: double.infinity),
                ),
              ]),
            ),
        ]),
        const SizedBox(height: 16),
        AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Still need help?', style: AppText.label(c, size: 15)),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: PillButton(
                  label: 'Contact support',
                  height: 46,
                  fontSize: 14,
                  onTap: () => showToast(context, 'Support contact details will be added before release.'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: PillButton(
                  label: _sent ? 'Logs copied' : 'Copy logs',
                  tone: ButtonTone.outline,
                  height: 46,
                  fontSize: 14,
                  onTap: () {
                    final b = context.band;
                    final log = 'state=${b.state.name} connected=${b.connected} demo=${b.isDemo} '
                        'battery=${b.battery} charging=${b.charging} firmware=${b.firmware} rssi=${b.rssi} '
                        'bluetooth=${b.bluetoothState.name} lastError=${b.lastError}';
                    Clipboard.setData(ClipboardData(text: log));
                    setState(() => _sent = true);
                  },
                ),
              ),
            ]),
          ]),
        ),
        const SizedBox(height: 24),
      ]),
    );
  }
}

class _Topic extends StatelessWidget {
  const _Topic({required this.icon, required this.label, required this.onTap});
  final List<IconPart> icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return Pressable(
      onTap: onTap,
      child: AppCard(
        radius: 18,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(children: [
          IconTile(icon: icon, background: c.accentSoft, foreground: c.accentText, size: 32, radius: 10, iconSize: 16),
          const SizedBox(width: 10),
          Expanded(child: Text(label, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppText.label(c))),
        ]),
      ),
    );
  }
}
