import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/scope.dart';
import '../theme/tokens.dart';
import '../ui/icons.dart';
import '../ui/widgets.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  String _q = '';

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
          final langs = AppLanguage.all
              .where((l) => _q.isEmpty || l.name.toLowerCase().contains(_q) || l.native.toLowerCase().contains(_q))
              .toList();
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const SubHeader(title: 'Language', backLabel: 'Back to settings'),
            const SizedBox(height: 14),
            GroupCard(children: [
              ListRow(
                icon: AppIcons.sparkle,
                label: 'Detect automatically',
                subtitle: 'Understand whichever language you speak',
                height: 60,
                trailing: AppSwitch(
                  value: s.autoDetectLanguage,
                  label: 'Detect automatically',
                  onChanged: (v) => store.updateSettings((x) => x.autoDetectLanguage = v),
                ),
              ),
              ListRow(
                icon: AppIcons.chat,
                label: 'Reply in the same language',
                subtitle: 'Answer in the language of your question',
                height: 60,
                topBorder: true,
                trailing: AppSwitch(
                  value: s.replyInSameLanguage,
                  label: 'Reply in the same language',
                  onChanged: (v) => store.updateSettings((x) => x.replyInSameLanguage = v),
                ),
              ),
            ]),
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
                      hintText: 'Search languages',
                      hintStyle: AppText.body(c, color: c.muted, height: 1.2),
                    ),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 16),
            const SectionLabel('Main speaking language'),
            const SizedBox(height: 8),
            GroupCard(children: [
              for (var i = 0; i < langs.length; i++)
                Pressable(
                  pressedScale: 0.98,
                  onTap: () => store.updateSettings((x) => x.language = langs[i].code),
                  child: Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(border: i == 0 ? null : Border(top: BorderSide(color: c.border))),
                    child: Row(children: [
                      Expanded(
                        child: Text.rich(TextSpan(children: [
                          TextSpan(
                            text: langs[i].name,
                            style: AppText.body(c,
                                weight: s.language == langs[i].code ? FontWeight.w600 : FontWeight.w500),
                          ),
                          TextSpan(text: '   ${langs[i].native}', style: AppText.muted(c)),
                        ])),
                      ),
                      AnimatedScale(
                        scale: s.language == langs[i].code ? 1 : 0,
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutBack,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(color: c.accent, shape: BoxShape.circle),
                          alignment: Alignment.center,
                          child: AppIcon(AppIcons.check, size: 14, color: c.onAccent, strokeWidth: 3),
                        ),
                      ),
                    ]),
                  ),
                ),
            ]),
            const SizedBox(height: 10),
            Text(
              s.autoDetectLanguage
                  ? 'With automatic detection on, the main language is used as a hint only.'
                  : 'Your speech is transcribed in this language.',
              style: AppText.muted(c, size: 12),
            ),
            const SizedBox(height: 24),
          ]);
        },
      ),
    );
  }
}
