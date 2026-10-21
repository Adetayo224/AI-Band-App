import 'dart:async';

import 'package:flutter/material.dart';

import '../app.dart';
import '../models/models.dart';
import '../services/band_service.dart';
import '../services/firmware.dart';
import '../state/scope.dart';
import '../theme/tokens.dart';
import '../ui/format.dart';
import '../ui/icons.dart';
import '../ui/motion.dart';
import '../ui/widgets.dart';
import 'about_band_screen.dart';
import 'find_band_screen.dart';
import 'firmware_screen.dart';
import 'onboarding.dart';

class DeviceScreen extends StatefulWidget {
  const DeviceScreen({super.key});

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  Timer? _debounce;
  double? _volumeDrag;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _setVolume(double v) {
    setState(() => _volumeDrag = v);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 150), () {
      final s = context.services;
      s.store.updateSettings((x) => x.volume = v.round());
      s.band.setVolume(v.round());
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final s = context.services;
    return PageScaffold(
      scroll: true,
      safeBottom: false,
      child: Watch(
        listenables: [s.store, s.band, s.firmware],
        builder: (context) {
          final band = s.band;
          final saved = s.store.band;
          final settings = s.store.settings;
          final volume = _volumeDrag ?? settings.volume.toDouble();
          final fw = s.firmware;
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(saved?.displayName ?? 'No band', style: AppText.display(c)),
                        const SizedBox(height: 2),
                        Row(children: [
                          Dot(color: band.connected ? c.accent : c.danger),
                          const SizedBox(width: 6),
                          Text.rich(
                            TextSpan(children: [
                              const TextSpan(text: 'AI Band '),
                              TextSpan(text: saved?.shortCode ?? '', style: const TextStyle(fontFamily: AppFonts.mono)),
                              TextSpan(text: band.connected ? ', connected' : ', not connected'),
                            ]),
                            style: AppText.muted(c),
                          ),
                        ]),
                      ]),
                ),
                if (saved != null)
                  CircleIconButton(
                    icon: AppIcons.dots,
                    label: 'About this band',
                    onTap: () => Navigator.of(context).push(slideRoute(const AboutBandScreen())),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (!band.connected) ...[
              Rise(
                child: AppCard(
                  color: c.dangerSoft,
                  borderColor: Colors.transparent,
                  child: Row(children: [
                    AppIcon(AppIcons.bluetoothOff, size: 20, color: c.danger),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(saved == null ? 'No band paired yet.' : 'Your band is not connected.',
                          style: AppText.body(c, size: 14, weight: FontWeight.w500)),
                    ),
                    PillButton(
                      label: band.state == LinkState.connecting ? 'Connecting' : (saved == null ? 'Pair' : 'Reconnect'),
                      expand: false,
                      height: 38,
                      fontSize: 13,
                      onTap: band.state == LinkState.connecting
                          ? null
                          : () => saved == null ? openPairing(context) : band.reconnect(),
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Row(children: [
              Expanded(
                child: _Stat(
                  icon: AppIcons.battery,
                  label: 'Battery',
                  value: band.battery == null ? '...' : '${band.battery}%',
                  mono: true,
                  note: band.battery == null
                      ? ''
                      : (band.charging ? 'Charging' : Fmt.batteryLeft(band.battery!).replaceAll(' left', '')),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Stat(
                  icon: AppIcons.bluetooth,
                  label: 'Signal',
                  value: band.connected ? band.signalWord : 'None',
                  note: band.connected ? (band.signalBars >= 3 ? 'Within 2 m' : 'Move closer') : '',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Stat(
                  icon: AppIcons.chip,
                  label: 'Firmware',
                  value: band.firmware.isEmpty ? '...' : band.firmware,
                  mono: true,
                  note: fw.updateAvailable ? 'Update ready' : 'Up to date',
                  noteAccent: fw.updateAvailable,
                ),
              ),
            ]),
            const SizedBox(height: 12),
            Pressable(
              pressedScale: 0.98,
              onTap: () => Navigator.of(context).push(slideRoute(const FindBandScreen())),
              child: AppCard(
                padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
                child: Row(children: [
                  IconTile(
                      icon: AppIcons.target,
                      background: c.accentSoft,
                      foreground: c.accentText,
                      circle: true,
                      iconSize: 22),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Find my band', style: AppText.label(c, size: 16)),
                      const SizedBox(height: 2),
                      Text('Plays a tone and vibrates', style: AppText.muted(c)),
                    ]),
                  ),
                  AppIcon(AppIcons.chevronRight, size: 18, color: c.muted, strokeWidth: 2),
                ]),
              ),
            ),
            const SizedBox(height: 12),
            AppCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Row(children: [
                  AppIcon(AppIcons.volumeLow, size: 18, color: c.text),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Speaker volume', style: AppText.label(c))),
                  Text('${volume.round()}%', style: AppText.mono(c, size: 13, color: c.muted)),
                ]),
                const SizedBox(height: 6),
                Slider(
                  value: volume,
                  min: 0,
                  max: 100,
                  onChanged: _setVolume,
                  onChangeEnd: (_) => setState(() => _volumeDrag = null),
                ),
                const SizedBox(height: 8),
                Row(children: [
                  AppIcon(AppIcons.vibrationSmall, size: 18, color: c.text),
                  const SizedBox(width: 8),
                  Text('Vibration strength', style: AppText.label(c)),
                ]),
                const SizedBox(height: 10),
                Segmented<VibrationStrength>(
                  background: c.bg,
                  value: settings.vibration,
                  onChanged: (v) {
                    s.store.updateSettings((x) => x.vibration = v);
                    band.setVibration(v);
                    if (v != VibrationStrength.off) band.vibrate(1);
                  },
                  options: const [
                    SegmentOption(VibrationStrength.off, 'Off'),
                    SegmentOption(VibrationStrength.light, 'Light'),
                    SegmentOption(VibrationStrength.medium, 'Medium'),
                    SegmentOption(VibrationStrength.strong, 'Strong'),
                  ],
                ),
                const SizedBox(height: 18),
                Row(children: [
                  AppIcon(AppIcons.button, size: 18, color: c.text),
                  const SizedBox(width: 8),
                  Text('Band button', style: AppText.label(c)),
                ]),
                const SizedBox(height: 10),
                Segmented<ButtonMode>(
                  background: c.bg,
                  value: settings.buttonMode,
                  onChanged: (v) {
                    s.store.updateSettings((x) => x.buttonMode = v);
                    band.setButtonMode(v);
                  },
                  options: const [
                    SegmentOption(ButtonMode.tap, 'Tap to talk'),
                    SegmentOption(ButtonMode.hold, 'Hold to talk'),
                  ],
                ),
              ]),
            ),
            const SizedBox(height: 12),
            _FirmwareCard(fw: fw, current: band.firmware),
            if (band.isDemo) ...[
              const SizedBox(height: 12),
              Center(
                child: LinkButton(
                  label: band.charging ? 'Demo: take band off the charger' : 'Demo: put band on the charger',
                  size: 13,
                  color: c.muted,
                  icon: AppIcons.magnet,
                  onTap: band.demoToggleCharging,
                ),
              ),
            ],
            const SizedBox(height: 24),
          ]);
        },
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.icon,
    required this.label,
    required this.value,
    this.note = '',
    this.mono = false,
    this.noteAccent = false,
  });

  final List<IconPart> icon;
  final String label;
  final String value;
  final String note;
  final bool mono;
  final bool noteAccent;

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return AppCard(
      radius: 20,
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          AppIcon(icon, size: 14, color: c.muted),
          const SizedBox(width: 6),
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis, style: AppText.muted(c, size: 12))),
        ]),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(value, style: mono ? AppText.mono(c, size: 22) : AppText.title(c, size: 22)),
        ),
        const SizedBox(height: 6),
        Text(note,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.body(c, size: 11, color: noteAccent ? c.accentText : c.muted)),
      ]),
    );
  }
}

class _FirmwareCard extends StatelessWidget {
  const _FirmwareCard({required this.fw, required this.current});
  final FirmwareUpdater fw;
  final String current;

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final busy = fw.stage == FirmwareStage.sending ||
        fw.stage == FirmwareStage.downloading ||
        fw.stage == FirmwareStage.installing;
    final title = busy
        ? 'Installing update'
        : fw.updateAvailable
            ? 'Update available'
            : fw.stage == FirmwareStage.checking
                ? 'Checking for updates'
                : 'Firmware is up to date';
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: AppText.label(c, size: 15)),
              const SizedBox(height: 2),
              if (fw.updateAvailable || busy)
                Text.rich(
                    TextSpan(children: [
                      const TextSpan(text: 'Version '),
                      TextSpan(text: fw.latestVersion, style: const TextStyle(fontFamily: AppFonts.mono)),
                      TextSpan(text: fw.notes.isEmpty ? '' : ', ${fw.notes.first.toLowerCase()}'),
                    ]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.muted(c))
              else
                Text(current.isEmpty ? 'Connect your band to check.' : 'Version $current is the newest.',
                    style: AppText.muted(c)),
              if (fw.updateAvailable)
                Pressable(
                  onTap: () => Navigator.of(context).push(slideRoute(const FirmwareScreen())),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text('See what is new', style: AppText.label(c, size: 13, color: c.accentText)),
                  ),
                ),
            ]),
          ),
          if (fw.updateAvailable)
            PillButton(
              label: 'Install',
              icon: AppIcons.download,
              expand: false,
              height: 40,
              fontSize: 13,
              onTap: () {
                fw.install();
                Navigator.of(context).push(slideRoute(const FirmwareScreen()));
              },
            )
          else if (busy)
            Text('${(fw.progress * 100).round()}%', style: AppText.mono(c, size: 15, color: c.accentText))
          else
            CircleIconButton(icon: AppIcons.sync, label: 'Check for updates', size: 40, iconSize: 18, onTap: fw.check),
        ]),
        if (busy) ...[
          const SizedBox(height: 12),
          ShineProgress(value: fw.progress, height: 6),
          const SizedBox(height: 8),
          Text('Keep your band close to your phone until it finishes.', style: AppText.muted(c, size: 12)),
        ],
      ]),
    );
  }
}
