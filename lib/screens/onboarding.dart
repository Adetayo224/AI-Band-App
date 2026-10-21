import 'dart:async';

import 'package:flutter/material.dart';

import '../app.dart';
import '../services/band_service.dart';
import '../state/scope.dart';
import '../theme/tokens.dart';
import '../ui/icons.dart';
import '../ui/motion.dart';
import '../ui/widgets.dart';
import 'help_screen.dart';
import 'home_shell.dart';

/// Back button, four step bar and "x of 4" counter shown on every
/// onboarding step.
class OnboardingTop extends StatelessWidget {
  const OnboardingTop({super.key, required this.step, this.errorStep, this.canGoBack = true});
  final int step;
  final int? errorStep;
  final bool canGoBack;

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return SizedBox(
      height: 44,
      child: Row(children: [
        Opacity(
          opacity: canGoBack ? 1 : 0.4,
          child: CircleIconButton(
            icon: AppIcons.chevronLeft,
            label: 'Back',
            onTap: canGoBack ? () => Navigator.of(context).maybePop() : null,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(child: StepBar(step: step, errorStep: errorStep)),
        SizedBox(
          width: 52,
          child: Text('${step + 1} of 4',
              textAlign: TextAlign.right, style: AppText.mono(c, size: 12, weight: FontWeight.w400, color: c.muted)),
        ),
      ]),
    );
  }
}

// ----------------------------------------------------------------- welcome

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return PageScaffold(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const OnboardingTop(step: 0, canGoBack: false),
        Expanded(
          child: Center(
            child: SizedBox(
              width: 260,
              height: 260,
              child: Stack(alignment: Alignment.center, children: [
                Positioned.fill(child: PingRings(color: c.accent)),
                const Pop(child: BandMark(size: 140, strokeWidth: 3)),
              ]),
            ),
          ),
        ),
        Rise(
          child: Text('Your assistant,\non your wrist', style: AppText.display(c, size: 34)),
        ),
        const SizedBox(height: 14),
        Rise(
          delay: const Duration(milliseconds: 80),
          child: Text(
            'Press the button, ask anything, and hear the answer right from your band. No screen needed.',
            style: AppText.body(c, size: 16, color: c.muted, height: 1.5),
          ),
        ),
        const SizedBox(height: 32),
        PillButton(
          label: 'Get started',
          onTap: () => Navigator.of(context).push(slideRoute(const AboutYouScreen())),
        ),
        const SizedBox(height: 8),
      ]),
    );
  }
}

// --------------------------------------------------------------- about you

/// Personal details, stored on the phone only. There is no login.
class AboutYouScreen extends StatefulWidget {
  const AboutYouScreen({super.key});

  @override
  State<AboutYouScreen> createState() => _AboutYouScreenState();
}

class _AboutYouScreenState extends State<AboutYouScreen> {
  final _name = TextEditingController();
  final _nick = TextEditingController();
  final _birthday = TextEditingController();
  final _city = TextEditingController();
  bool _metric = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final p = context.store.profile;
    if (_name.text.isEmpty) {
      _name.text = p.name;
      _nick.text = p.nickname;
      _birthday.text = p.birthday;
      _city.text = p.city;
      _metric = p.metric;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _nick.dispose();
    _birthday.dispose();
    _city.dispose();
    super.dispose();
  }

  Future<void> _continue({bool save = true}) async {
    if (save) {
      final p = context.store.profile
        ..name = _name.text.trim()
        ..nickname = _nick.text.trim()
        ..birthday = _birthday.text.trim()
        ..city = _city.text.trim()
        ..metric = _metric;
      context.store.profile = p;
      await context.store.saveProfile();
    }
    if (!mounted) return;
    Navigator.of(context).push(slideRoute(const PermissionsScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return PageScaffold(
      scroll: true,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SizedBox(
          height: 44,
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const BackCircle(),
            LinkButton(label: 'Skip', color: c.muted, onTap: () => _continue(save: false)),
          ]),
        ),
        const SizedBox(height: 22),
        Text('Tell us about you', style: AppText.display(c, size: 30)),
        const SizedBox(height: 10),
        Text(
          'So your assistant can greet you by name and give answers that fit where you live. No account needed.',
          style: AppText.body(c, color: c.muted, height: 1.5),
        ),
        const SizedBox(height: 18),
        Rise(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            AppField(
                label: 'Your name',
                hint: 'First name',
                controller: _name,
                autofillHints: const [AutofillHints.givenName]),
            const SizedBox(height: 12),
            AppField(
                label: 'What should the assistant call you?', optional: true, hint: 'A nickname', controller: _nick),
            const SizedBox(height: 12),
            BirthdayField(controller: _birthday),
            const SizedBox(height: 12),
            AppField(
              label: 'City',
              hint: 'For weather',
              controller: _city,
              autofillHints: const [AutofillHints.addressCity],
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 12),
            Text('Units', style: AppText.body(c, size: 13, weight: FontWeight.w500, color: c.muted)),
            const SizedBox(height: 6),
            Segmented<bool>(
              solid: true,
              height: 40,
              fontSize: 14,
              value: _metric,
              onChanged: (v) => setState(() => _metric = v),
              options: const [SegmentOption(true, 'Metric (km, °C)'), SegmentOption(false, 'Imperial (mi, °F)')],
            ),
          ]),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(color: c.accentSoft, borderRadius: BorderRadius.circular(18)),
          child: Row(children: [
            AppIcon(AppIcons.lock, size: 20, color: c.accentText),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Saved only on this phone. You can change or delete it any time in Settings.',
                  style: AppText.body(c, size: 13)),
            ),
          ]),
        ),
        const SizedBox(height: 24),
        PillButton(label: 'Continue', onTap: _continue),
      ]),
    );
  }
}

// ------------------------------------------------------------- permissions

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  bool _bt = false;
  bool _mic = false;
  bool _bell = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final s = context.services;
      final bt = await s.band.hasPermissions();
      final mic = await s.audio.hasMicPermission(request: false);
      if (!mounted) return;
      setState(() {
        _bt = bt;
        _mic = mic;
        _bell = s.store.settings.notificationsEnabled;
      });
    });
  }

  Future<void> _toggleBt(bool v) async {
    if (!v) return setState(() => _bt = false);
    final ok = await context.band.requestPermissions();
    if (!mounted) return;
    setState(() => _bt = ok || context.band.bluetoothState.name != 'unauthorized');
    if (!ok) showToast(context, 'Turn on Bluetooth to find your band.');
  }

  Future<void> _toggleMic(bool v) async {
    if (!v) return setState(() => _mic = false);
    final ok = await context.services.audio.hasMicPermission();
    if (!mounted) return;
    setState(() => _mic = ok);
    if (!ok) showToast(context, 'Microphone access is off. You can allow it in your phone settings.');
  }

  void _toggleBell(bool v) {
    setState(() => _bell = v);
    context.store.updateSettings((s) => s.notificationsEnabled = v);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final items = [
      (AppIcons.bluetooth, 'Bluetooth', 'To find your band and stream audio', _bt, _toggleBt),
      (AppIcons.mic, 'Microphone', 'So you can also talk from your phone', _mic, _toggleMic),
      (AppIcons.bell, 'Notifications', 'For reminders and firmware updates', _bell, _toggleBell),
    ];
    return PageScaffold(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const OnboardingTop(step: 1),
        const SizedBox(height: 32),
        Rise(child: Text('Allow a few things', style: AppText.display(c, size: 30))),
        const SizedBox(height: 12),
        Rise(
          delay: const Duration(milliseconds: 80),
          child: Text(
            'The app needs these to reach your band and hear you. You can change them later in Settings.',
            style: AppText.body(c, color: c.muted, height: 1.5),
          ),
        ),
        const SizedBox(height: 28),
        Rise(
          delay: const Duration(milliseconds: 160),
          child: Column(children: [
            for (final it in items) ...[
              AppCard(
                child: Row(children: [
                  IconTile(icon: it.$1, background: c.accentSoft, foreground: c.accentText),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(it.$2, style: AppText.label(c, size: 15)),
                      const SizedBox(height: 3),
                      Text(it.$3, style: AppText.muted(c)),
                    ]),
                  ),
                  AppSwitch(value: it.$4, label: it.$2, onChanged: it.$5),
                ]),
              ),
              const SizedBox(height: 10),
            ],
          ]),
        ),
        const Spacer(),
        PillButton(
          label: 'Continue',
          onTap: () => Navigator.of(context).push(slideRoute(const PairingScreen())),
        ),
      ]),
    );
  }
}

// ----------------------------------------------------------------- pairing

class PairingScreen extends StatefulWidget {
  const PairingScreen({super.key, this.fromSettings = false});
  final bool fromSettings;

  @override
  State<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends State<PairingScreen> {
  late BandService _band;
  String? _connectingId;
  bool _slow = false;
  Timer? _slowTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scan());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _band = context.band;
  }

  void _scan() {
    if (!mounted) return;
    context.band.startScan();
    _slowTimer?.cancel();
    setState(() => _slow = false);
    _slowTimer = Timer(const Duration(seconds: 12), () {
      if (mounted) setState(() => _slow = true);
    });
  }

  @override
  void dispose() {
    _slowTimer?.cancel();
    if (_band.state == LinkState.scanning) _band.stopScan();
    super.dispose();
  }

  Future<void> _connect(FoundBand b) async {
    setState(() => _connectingId = b.id);
    final ok = await context.band.connect(b);
    if (!mounted) return;
    setState(() => _connectingId = null);
    if (ok) {
      await Navigator.of(context).pushReplacement(slideRoute(PairedScreen(fromSettings: widget.fromSettings)));
    } else {
      final retry = await Navigator.of(context).push<bool>(slideRoute(const PairFailScreen()));
      if (retry == true) _scan();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final band = context.band;
    return PageScaffold(
      child: Watch(
        listenables: [band],
        builder: (context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const OnboardingTop(step: 2),
          SizedBox(
            height: 290,
            child: Center(
              child: SizedBox(
                width: 250,
                height: 250,
                child: Stack(alignment: Alignment.center, children: [
                  Positioned.fill(
                    child: PingRings(color: c.accent, fill: c.accentSoft, strokeWidth: 1, startScale: 0.3),
                  ),
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(color: c.accent, shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: AppIcon(AppIcons.bluetooth, size: 34, color: c.onAccent),
                  ),
                ]),
              ),
            ),
          ),
          Text('Looking for your band', style: AppText.display(c)),
          const SizedBox(height: 10),
          Text('Hold the button on your band for 3 seconds until it vibrates twice.',
              style: AppText.body(c, color: c.muted, height: 1.5)),
          const SizedBox(height: 22),
          const SectionLabel('Nearby'),
          const SizedBox(height: 10),
          Expanded(
            child: band.found.isEmpty
                ? Align(
                    alignment: Alignment.topLeft,
                    child: Row(children: [
                      Spinner(color: c.muted, size: 16, strokeWidth: 2),
                      const SizedBox(width: 10),
                      Text(band.lastError == 'Bluetooth is off' ? 'Turn on Bluetooth to search' : 'Searching',
                          style: AppText.muted(c, size: 14)),
                    ]),
                  )
                : ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: band.found.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) => Rise(
                      child: _FoundBandTile(
                        band: band.found[i],
                        connecting: _connectingId == band.found[i].id,
                        onConnect: _connectingId == null ? () => _connect(band.found[i]) : null,
                      ),
                    ),
                  ),
          ),
          if (!context.store.settings.demoMode)
            Center(
              child: LinkButton(
                label: 'No band yet? Try the demo band',
                size: 14,
                color: c.accentText,
                onTap: band.enableDemo,
              ),
            ),
          Center(
            child: LinkButton(
              label: _slow ? 'Still nothing? See what to check' : 'Not finding it? Get help',
              icon: AppIcons.help,
              onTap: () async {
                final retry = await Navigator.of(context).push<bool>(slideRoute(const PairFailScreen()));
                if (retry == true) _scan();
              },
            ),
          ),
        ]),
      ),
    );
  }
}

class _FoundBandTile extends StatelessWidget {
  const _FoundBandTile({required this.band, required this.connecting, required this.onConnect});
  final FoundBand band;
  final bool connecting;
  final VoidCallback? onConnect;

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final words = band.name.split(' ');
    final code = words.length > 2 ? words.last : '';
    final base = code.isEmpty ? band.name : words.sublist(0, words.length - 1).join(' ');
    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
      child: Row(children: [
        IconTile(icon: AppIcons.watch, background: c.surface2, foreground: c.text, circle: true, iconSize: 22),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text.rich(
              TextSpan(children: [
                TextSpan(text: '$base '),
                TextSpan(text: code, style: const TextStyle(fontFamily: AppFonts.mono, fontWeight: FontWeight.w500)),
                if (band.demo) TextSpan(text: '  Demo', style: TextStyle(color: c.accentText, fontSize: 12)),
              ]),
              style: AppText.label(c, size: 15),
            ),
            const SizedBox(height: 4),
            Row(children: [
              SignalBars(bars: band.bars),
              const SizedBox(width: 6),
              Text(band.signalLabel, style: AppText.muted(c, size: 12)),
            ]),
          ]),
        ),
        PillButton(
          label: connecting ? 'Connecting' : 'Connect',
          expand: false,
          height: 44,
          fontSize: 14,
          leading: connecting ? Spinner(color: c.onAccent, size: 14, strokeWidth: 2) : null,
          onTap: onConnect,
        ),
      ]),
    );
  }
}

/// Four little bars showing Bluetooth signal strength.
class SignalBars extends StatelessWidget {
  const SignalBars({super.key, required this.bars});
  final int bars;

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
      for (var i = 0; i < 4; i++) ...[
        if (i > 0) const SizedBox(width: 2),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 3,
          height: 4.0 + i * 3 - (i == 3 ? 1 : 0),
          decoration: BoxDecoration(color: i < bars ? c.accent : c.track, borderRadius: BorderRadius.circular(1)),
        ),
      ],
    ]);
  }
}

// --------------------------------------------------------------- not found

class PairFailScreen extends StatefulWidget {
  const PairFailScreen({super.key});

  @override
  State<PairFailScreen> createState() => _PairFailScreenState();
}

class _PairFailScreenState extends State<PairFailScreen> {
  final Set<int> _done = {};

  static const _steps = [
    ('Charge your band', 'Place it on the magnetic charger for 10 minutes.'),
    ('Bring it closer', 'Keep the band within 1 metre of your phone.'),
    ('Restart Bluetooth', 'Turn Bluetooth off and on again on your phone.'),
    ('Wake the band', 'Hold the band button for 3 seconds until it vibrates twice.'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return PageScaffold(
      scroll: true,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const OnboardingTop(step: 2, errorStep: 2),
        const SizedBox(height: 36),
        Center(
          child: Shake(
            child: IconTile(
              icon: AppIcons.bluetoothOff,
              background: c.dangerSoft,
              foreground: c.danger,
              size: 104,
              iconSize: 44,
              circle: true,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text('We could not find your band', textAlign: TextAlign.center, style: AppText.display(c)),
        const SizedBox(height: 10),
        Text('Try these quick checks, then search again. Tap each one when done.',
            textAlign: TextAlign.center, style: AppText.body(c, color: c.muted, height: 1.5)),
        const SizedBox(height: 24),
        GroupCard(children: [
          for (var i = 0; i < _steps.length; i++)
            Pressable(
              pressedScale: 0.98,
              onTap: () => setState(() => _done.contains(i) ? _done.remove(i) : _done.add(i)),
              child: Container(
                constraints: const BoxConstraints(minHeight: 60),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(border: i == 0 ? null : Border(top: BorderSide(color: c.border))),
                child: Row(children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _done.contains(i) ? c.accent : Colors.transparent,
                      border: Border.all(color: _done.contains(i) ? c.accent : c.border, width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (child, a) => ScaleTransition(scale: a, child: child),
                      child: _done.contains(i)
                          ? AppIcon(AppIcons.check,
                              key: const ValueKey('c'), size: 16, color: c.onAccent, strokeWidth: 2.6)
                          : Text('${i + 1}',
                              key: const ValueKey('n'),
                              style: AppText.mono(c, size: 13, weight: FontWeight.w600, color: c.muted)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(_steps[i].$1, style: AppText.label(c, size: 15)),
                      const SizedBox(height: 2),
                      Text(_steps[i].$2, style: AppText.muted(c)),
                    ]),
                  ),
                ]),
              ),
            ),
        ]),
        const SizedBox(height: 28),
        PillButton(label: 'Search again', icon: AppIcons.sync, onTap: () => Navigator.of(context).pop(true)),
        const SizedBox(height: 6),
        Center(
          child: LinkButton(
            label: 'Contact support',
            onTap: () => Navigator.of(context).push(slideRoute(const HelpScreen())),
          ),
        ),
      ]),
    );
  }
}

// ------------------------------------------------------------------ paired

class PairedScreen extends StatefulWidget {
  const PairedScreen({super.key, this.fromSettings = false});
  final bool fromSettings;

  @override
  State<PairedScreen> createState() => _PairedScreenState();
}

class _PairedScreenState extends State<PairedScreen> {
  late final TextEditingController _name = TextEditingController(text: context.store.band?.displayName ?? 'My Band');

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final s = context.services;
    await s.store.renameBand(_name.text);
    await s.band.setName(s.store.band?.displayName ?? 'My Band');
    await s.store.setOnboarded(true);
    s.firmware.check();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(fadeRoute(const HomeShell()), (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final band = context.band;
    return PageScaffold(
      scroll: true,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const OnboardingTop(step: 3),
        SizedBox(
          height: 260,
          child: Center(
            child: Pop(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(color: c.accent, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: AppIcon(AppIcons.check, size: 52, color: c.onAccent, strokeWidth: 2.2),
              ),
            ),
          ),
        ),
        Rise(child: Text('You are all set', style: AppText.display(c, size: 30))),
        const SizedBox(height: 12),
        Rise(
          delay: const Duration(milliseconds: 80),
          child: Text('Your band is paired. Give it a name so you can spot it easily.',
              style: AppText.body(c, color: c.muted, height: 1.5)),
        ),
        const SizedBox(height: 24),
        Rise(
          delay: const Duration(milliseconds: 160),
          child: AppField(label: 'Band name', controller: _name, textInputAction: TextInputAction.done),
        ),
        const SizedBox(height: 14),
        Watch(
          listenables: [band],
          builder: (context) => Wrap(spacing: 8, runSpacing: 8, children: [
            _InfoChip(label: 'Battery', value: band.battery == null ? '...' : '${band.battery}%'),
            _InfoChip(label: 'Firmware', value: band.firmware.isEmpty ? '...' : band.firmware),
          ]),
        ),
        const SizedBox(height: 40),
        PillButton(label: 'Go to home', onTap: _finish),
      ]),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.border),
      ),
      child: Text.rich(TextSpan(children: [
        TextSpan(text: '$label ', style: AppText.muted(c, size: 12)),
        TextSpan(text: value, style: AppText.mono(c, size: 12)),
      ])),
    );
  }
}

/// Used by other screens to start pairing a new band.
void openPairing(BuildContext context) {
  Navigator.of(context).push(slideRoute(const PairingScreen(fromSettings: true)));
}
