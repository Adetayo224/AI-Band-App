import 'package:flutter/material.dart';

import '../app.dart';
import '../config.dart';
import '../models/models.dart';
import '../state/scope.dart';
import '../theme/tokens.dart';
import '../ui/icons.dart';
import '../ui/widgets.dart';
import 'help_screen.dart';
import 'language_screen.dart';
import 'personal_data_screen.dart';
import 'voice_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, this.standalone = false});

  /// True when opened from another page (shows a back button).
  final bool standalone;

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final store = context.store;
    return PageScaffold(
      scroll: true,
      safeBottom: standalone,
      child: Watch(
        listenables: [store],
        builder: (context) {
          final s = store.settings;
          final p = store.profile;
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            SizedBox(
              height: 44,
              child: Row(children: [
                if (standalone) ...[const BackCircle(), const SizedBox(width: 12)],
                Expanded(child: Text('Settings', style: standalone ? AppText.title(c) : AppText.display(c))),
                CircleIconButton(
                  icon: AppIcons.help,
                  label: 'Help',
                  onTap: () => Navigator.of(context).push(slideRoute(const HelpScreen())),
                ),
              ]),
            ),
            const SizedBox(height: 14),
            Pressable(
              pressedScale: 0.98,
              onTap: () => Navigator.of(context).push(slideRoute(const PersonalDataScreen())),
              child: AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: c.accent, shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: p.initials.isEmpty
                        ? AppIcon(AppIcons.user, size: 20, color: c.onAccent)
                        : Text(p.initials, style: AppText.label(c, size: 17, color: c.onAccent)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Personal data', style: AppText.label(c, size: 15)),
                      const SizedBox(height: 2),
                      Text('Name and details, stored on this phone', style: AppText.muted(c)),
                    ]),
                  ),
                  AppIcon(AppIcons.chevronRight, size: 18, color: c.muted, strokeWidth: 2),
                ]),
              ),
            ),
            const SizedBox(height: 18),
            const SectionLabel('Appearance'),
            const SizedBox(height: 8),
            AppCard(
              padding: const EdgeInsets.all(12),
              child: Column(children: [
                Row(children: [
                  for (final m in AppThemeMode.values) ...[
                    if (m != AppThemeMode.light) const SizedBox(width: 10),
                    Expanded(
                      child: _ThemeOption(
                        mode: m,
                        selected: s.theme == m,
                        onTap: () => store.updateSettings((x) => x.theme = m),
                      ),
                    ),
                  ],
                ]),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  child: Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Night mode after 9 PM', style: AppText.label(c)),
                        const SizedBox(height: 2),
                        Text('Warmer, dimmer colours for late use', style: AppText.muted(c, size: 12)),
                      ]),
                    ),
                    AppSwitch(
                      value: s.autoNight,
                      label: 'Night mode after 9 PM',
                      onChanged: (v) => store.updateSettings((x) => x.autoNight = v),
                    ),
                  ]),
                ),
              ]),
            ),
            const SizedBox(height: 18),
            const SectionLabel('Assistant'),
            const SizedBox(height: 8),
            GroupCard(children: [
              ListRow(
                icon: AppIcons.waveform,
                label: 'Voice',
                value: AssistantVoice.byId(s.voiceId).name,
                onTap: () => Navigator.of(context).push(slideRoute(const VoiceScreen())),
              ),
              ListRow(
                icon: AppIcons.globe,
                label: 'Language',
                value: s.autoDetectLanguage ? 'Automatic' : AppLanguage.byCode(s.language).name,
                topBorder: true,
                onTap: () => Navigator.of(context).push(slideRoute(const LanguageScreen())),
              ),
              ListRow(
                icon: AppIcons.vibrationSmall,
                label: 'Vibrate when reply is ready',
                topBorder: true,
                trailing: AppSwitch(
                  value: s.vibrateOnReply,
                  label: 'Vibrate when reply is ready',
                  onChanged: (v) => store.updateSettings((x) => x.vibrateOnReply = v),
                ),
              ),
              ListRow(
                icon: AppIcons.bell,
                label: 'Notifications',
                topBorder: true,
                trailing: AppSwitch(
                  value: s.notificationsEnabled,
                  label: 'Notifications',
                  onChanged: (v) => store.updateSettings((x) => x.notificationsEnabled = v),
                ),
              ),
            ]),
            const SizedBox(height: 18),
            const SectionLabel('Privacy'),
            const SizedBox(height: 8),
            GroupCard(children: [
              ListRow(
                icon: AppIcons.shield,
                label: 'Save transcripts',
                trailing: AppSwitch(
                  value: s.saveTranscripts,
                  label: 'Save transcripts',
                  onChanged: (v) => store.updateSettings((x) => x.saveTranscripts = v),
                ),
              ),
              ListRow(
                icon: AppIcons.trash,
                label: 'Delete conversation history',
                color: c.danger,
                topBorder: true,
                showChevron: false,
                onTap: () async {
                  final ok = await showConfirmSheet(
                    context,
                    title: 'Delete all conversations?',
                    message: 'Every transcript and its audio will be removed from this phone. This cannot be undone.',
                    confirmLabel: 'Delete history',
                    icon: AppIcons.trash,
                  );
                  if (ok == true) {
                    await store.deleteAllConversations();
                    if (context.mounted) showToast(context, 'Conversation history deleted');
                  }
                },
              ),
            ]),
            const SizedBox(height: 18),
            const SectionLabel('About'),
            const SizedBox(height: 8),
            GroupCard(children: [
              ListRow(
                icon: AppIcons.sparkle,
                label: 'AI connection',
                value: AppConfig.hasOpenAiKey ? 'Ready' : 'Key missing',
                showChevron: false,
              ),
              ListRow(
                icon: AppIcons.watch,
                label: 'Demo band',
                subtitle: 'Try the app without hardware',
                topBorder: true,
                trailing: AppSwitch(
                  value: s.demoMode,
                  label: 'Demo band',
                  onChanged: (v) => store.updateSettings((x) => x.demoMode = v),
                ),
              ),
              const ListRow(
                  icon: AppIcons.chip, label: 'App version', value: '1.0.0', topBorder: true, showChevron: false),
            ]),
            const SizedBox(height: 24),
          ]);
        },
      ),
    );
  }
}

/// Small preview of a theme: background, two text lines and an accent pill.
class _ThemeOption extends StatelessWidget {
  const _ThemeOption({required this.mode, required this.selected, required this.onTap});
  final AppThemeMode mode;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final p = AppColors.of(mode);
    final (icon, label) = switch (mode) {
      AppThemeMode.light => (AppIcons.sun, 'Light'),
      AppThemeMode.dark => (AppIcons.contrast, 'Dark'),
      AppThemeMode.night => (AppIcons.moon, 'Night'),
    };
    return Semantics(
      selected: selected,
      button: true,
      label: '$label theme',
      child: Pressable(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.fromLTRB(6, 6, 6, 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: selected ? c.accent : Colors.transparent, width: 2),
          ),
          child: Column(children: [
            Container(
              height: 58,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: p.bg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: p.border),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                FractionallySizedBox(
                  widthFactor: 0.6,
                  child: Container(
                      height: 6, decoration: BoxDecoration(color: p.text, borderRadius: BorderRadius.circular(99))),
                ),
                const SizedBox(height: 6),
                FractionallySizedBox(
                  widthFactor: 0.4,
                  child: Container(
                      height: 6, decoration: BoxDecoration(color: p.muted, borderRadius: BorderRadius.circular(99))),
                ),
                const Spacer(),
                Container(
                    width: 28,
                    height: 12,
                    decoration: BoxDecoration(color: p.accent, borderRadius: BorderRadius.circular(99))),
              ]),
            ),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              AppIcon(icon, size: 14, color: c.text, strokeWidth: 2),
              const SizedBox(width: 6),
              Text(label, style: AppText.label(c, size: 13)),
            ]),
          ]),
        ),
      ),
    );
  }
}
