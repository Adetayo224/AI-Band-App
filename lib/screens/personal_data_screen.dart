import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app.dart';
import '../state/scope.dart';
import '../theme/tokens.dart';
import '../ui/icons.dart';
import '../ui/widgets.dart';
import 'onboarding.dart';

/// Edit the personal details that live on this phone. No account, no login.
class PersonalDataScreen extends StatefulWidget {
  const PersonalDataScreen({super.key});

  @override
  State<PersonalDataScreen> createState() => _PersonalDataScreenState();
}

class _PersonalDataScreenState extends State<PersonalDataScreen> {
  late final TextEditingController _name;
  late final TextEditingController _nick;
  late final TextEditingController _birthday;
  late final TextEditingController _city;
  bool _saved = true;
  bool _ready = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ready) return;
    final p = context.store.profile;
    _name = TextEditingController(text: p.name);
    _nick = TextEditingController(text: p.nickname);
    _birthday = TextEditingController(text: p.birthday);
    _city = TextEditingController(text: p.city);
    _ready = true;
  }

  @override
  void dispose() {
    _name.dispose();
    _nick.dispose();
    _birthday.dispose();
    _city.dispose();
    super.dispose();
  }

  void _dirty(String _) {
    if (_saved) setState(() => _saved = false);
  }

  Future<void> _save() async {
    final store = context.store;
    store.profile
      ..name = _name.text.trim()
      ..nickname = _nick.text.trim()
      ..birthday = _birthday.text.trim()
      ..city = _city.text.trim();
    await store.saveProfile();
    if (!mounted) return;
    FocusScope.of(context).unfocus();
    setState(() => _saved = true);
    showToast(context, 'Saved on this phone');
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
          final p = store.profile;
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            SubHeader(
              title: 'Personal data',
              backLabel: 'Back to settings',
              trailing: PillButton(
                label: _saved ? 'Saved' : 'Save',
                expand: false,
                height: 40,
                fontSize: 14,
                tone: _saved ? ButtonTone.outline : ButtonTone.accent,
                onTap: _saved ? null : _save,
              ),
            ),
            const SizedBox(height: 14),
            AppCard(
              radius: 24,
              child: Row(children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(color: c.accent, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: p.initials.isEmpty
                      ? AppIcon(AppIcons.user, size: 26, color: c.onAccent)
                      : Text(p.initials, style: AppText.title(c, size: 22).copyWith(color: c.onAccent)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(p.callName.isEmpty ? 'You' : p.callName, style: AppText.label(c, size: 18)),
                    const SizedBox(height: 3),
                    Row(children: [
                      AppIcon(AppIcons.lock, size: 14, color: c.muted, strokeWidth: 2),
                      const SizedBox(width: 6),
                      Text('Stored on this phone only', style: AppText.muted(c)),
                    ]),
                  ]),
                ),
              ]),
            ),
            const SizedBox(height: 14),
            AppField(label: 'Your name', controller: _name, onChanged: _dirty),
            const SizedBox(height: 10),
            AppField(label: 'Assistant calls you', controller: _nick, onChanged: _dirty, hint: 'A nickname'),
            const SizedBox(height: 10),
            BirthdayField(controller: _birthday, onChanged: _dirty),
            const SizedBox(height: 10),
            AppField(label: 'City', controller: _city, onChanged: _dirty, textInputAction: TextInputAction.done),
            const SizedBox(height: 12),
            Segmented<bool>(
              solid: true,
              height: 40,
              fontSize: 14,
              value: p.metric,
              onChanged: (v) {
                p.metric = v;
                store.saveProfile();
              },
              options: const [SegmentOption(true, 'Metric (km, °C)'), SegmentOption(false, 'Imperial (mi, °F)')],
            ),
            const SizedBox(height: 14),
            GroupCard(children: [
              ListRow(
                icon: AppIcons.user,
                label: 'Use my details in replies',
                trailing: AppSwitch(
                  value: p.useInReplies,
                  label: 'Use my details in replies',
                  onChanged: (v) {
                    p.useInReplies = v;
                    store.saveProfile();
                  },
                ),
              ),
              ListRow(
                icon: AppIcons.download,
                label: 'Export my data',
                topBorder: true,
                onTap: () {
                  Clipboard.setData(ClipboardData(text: store.exportJson()));
                  showToast(context, 'Your data was copied as text. Paste it anywhere to keep it.');
                },
              ),
              ListRow(
                icon: AppIcons.trash,
                label: 'Delete all data from this phone',
                color: c.danger,
                topBorder: true,
                showChevron: false,
                onTap: () async {
                  final ok = await showConfirmSheet(
                    context,
                    title: 'Delete all data?',
                    message:
                        'This removes your details, conversations and band pairing from this phone. It cannot be undone.',
                    confirmLabel: 'Delete everything',
                  );
                  if (ok == true && context.mounted) {
                    final s = context.services;
                    await s.band.disconnect(forget: true);
                    await s.store.wipeEverything();
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(fadeRoute(const WelcomeScreen()), (_) => false);
                    }
                  }
                },
              ),
            ]),
          ]);
        },
      ),
    );
  }
}
