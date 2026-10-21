import 'package:flutter/material.dart';

import '../services/firmware.dart';
import '../state/scope.dart';
import '../theme/tokens.dart';
import '../ui/icons.dart';
import '../ui/motion.dart';
import '../ui/widgets.dart';

class FirmwareScreen extends StatelessWidget {
  const FirmwareScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final s = context.services;
    final fw = s.firmware;
    return PageScaffold(
      child: Watch(
        listenables: [fw, s.band],
        builder: (context) {
          final stage = fw.stage;
          final busy =
              stage == FirmwareStage.downloading || stage == FirmwareStage.sending || stage == FirmwareStage.installing;
          final done = stage == FirmwareStage.done;
          final failed = stage == FirmwareStage.failed;
          final upToDate = stage == FirmwareStage.upToDate || stage == FirmwareStage.checking;
          final step = switch (stage) {
            FirmwareStage.downloading => 0,
            FirmwareStage.sending => 1,
            FirmwareStage.installing => 2,
            _ => 3,
          };
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const SubHeader(title: 'Firmware update', backLabel: 'Back to device'),
            const SizedBox(height: 16),
            AppCard(
              radius: AppSpace.radiusHero,
              padding: const EdgeInsets.all(20),
              child: Row(children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: done
                      ? Pop(
                          key: const ValueKey('done'),
                          child: IconTile(
                            icon: AppIcons.check,
                            background: c.accent,
                            foreground: c.onAccent,
                            size: 64,
                            radius: 20,
                            iconSize: 30,
                          ),
                        )
                      : IconTile(
                          key: const ValueKey('chip'),
                          icon: AppIcons.chipCore,
                          background: c.accentSoft,
                          foreground: c.accentText,
                          size: 64,
                          radius: 20,
                          iconSize: 30,
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(
                      done
                          ? 'Installed'
                          : busy
                              ? 'Installing'
                              : upToDate
                                  ? 'Your band is up to date'
                                  : 'New version available',
                      style: AppText.muted(c),
                    ),
                    const SizedBox(height: 4),
                    Text(upToDate ? (s.band.firmware.isEmpty ? '...' : s.band.firmware) : fw.latestVersion,
                        style: AppText.mono(c, size: 28)),
                    const SizedBox(height: 4),
                    Text(
                        done
                            ? 'Up to date'
                            : 'Current version ${s.band.firmware.isEmpty ? 'unknown' : s.band.firmware}',
                        style: AppText.muted(c)),
                  ]),
                ),
              ]),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: busy
                      ? _Progress(key: const ValueKey('busy'), fw: fw, step: step)
                      : done
                          ? AppCard(
                              key: const ValueKey('done'),
                              padding: const EdgeInsets.all(20),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text('Your band is up to date', style: AppText.label(c, size: 18)),
                                const SizedBox(height: 8),
                                Text(
                                  'It restarted with version ${fw.latestVersion} and reconnected automatically. '
                                  'You will feel a short vibration when it is ready.',
                                  style: AppText.body(c, size: 14, color: c.muted, height: 1.5),
                                ),
                              ]),
                            )
                          : Column(
                              key: const ValueKey('idle'),
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                  if (failed) ...[
                                    AppCard(
                                      color: c.dangerSoft,
                                      borderColor: Colors.transparent,
                                      child: Text(fw.error ?? 'The update failed. Please try again.',
                                          style: AppText.body(c, size: 14, color: c.danger)),
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                  if (fw.notes.isNotEmpty && !upToDate) ...[
                                    const SectionLabel('What is new'),
                                    const SizedBox(height: 8),
                                    AppCard(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                      child: Column(children: [
                                        for (final n in fw.notes)
                                          Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 10),
                                            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                              Padding(
                                                padding: const EdgeInsets.only(top: 1),
                                                child: AppIcon(AppIcons.check,
                                                    size: 18, color: c.accentText, strokeWidth: 2.2),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(child: Text(n, style: AppText.body(c, size: 14))),
                                            ]),
                                          ),
                                      ]),
                                    ),
                                    const SizedBox(height: 16),
                                    const SectionLabel('Before you start'),
                                    const SizedBox(height: 8),
                                    Row(children: [
                                      Expanded(
                                        child: _Check(
                                          label: 'Band battery',
                                          value: s.band.battery == null ? '...' : '${s.band.battery}%',
                                          ok: (s.band.battery ?? 0) >= 30 || s.band.charging,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: _Check(
                                          label: 'Distance',
                                          value: s.band.signalBars >= 3 ? 'Within 1 m' : 'Move closer',
                                          ok: s.band.signalBars >= 3,
                                        ),
                                      ),
                                    ]),
                                  ],
                                  if (upToDate)
                                    Text(
                                      'There is no newer firmware for your band right now. The app checks again each time your band connects.',
                                      style: AppText.body(c, size: 14, color: c.muted, height: 1.5),
                                    ),
                                ]),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (done || upToDate)
              PillButton(label: 'Back to device', onTap: () => Navigator.of(context).pop())
            else if (busy)
              PillButton(
                  label: 'Cancel update',
                  tone: ButtonTone.outline,
                  onTap: stage == FirmwareStage.installing ? null : fw.cancel)
            else
              PillButton(label: failed ? 'Try again' : 'Install update', onTap: fw.install),
          ]);
        },
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({super.key, required this.fw, required this.step});
  final FirmwareUpdater fw;
  final int step;

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    const labels = ['Downloading update', 'Sending to your band', 'Installing', 'Restarting band'];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      AppCard(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
            Expanded(child: Text(labels[step.clamp(0, 3)], style: AppText.label(c, size: 15))),
            Text('${(fw.progress * 100).round()}%', style: AppText.mono(c, size: 20, color: c.accentText)),
          ]),
          const SizedBox(height: 16),
          ShineProgress(value: fw.progress),
          const SizedBox(height: 16),
          for (var i = 0; i < labels.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Center(
                    child: i < step
                        ? Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(color: c.accent, shape: BoxShape.circle),
                            alignment: Alignment.center,
                            child: AppIcon(AppIcons.check, size: 13, color: c.onAccent, strokeWidth: 3),
                          )
                        : i == step
                            ? Spinner(color: c.accent, size: 20)
                            : Container(
                                width: 10,
                                height: 10,
                                decoration:
                                    BoxDecoration(shape: BoxShape.circle, border: Border.all(color: c.track, width: 2)),
                              ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(labels[i],
                    style: AppText.body(c,
                        size: 14,
                        weight: i == step ? FontWeight.w600 : FontWeight.w500,
                        color: i > step ? c.muted : c.text)),
              ]),
            ),
        ]),
      ),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: c.warnSoft, borderRadius: BorderRadius.circular(20)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          AppIcon(AppIcons.warning, size: 18, color: c.warn, strokeWidth: 2),
          const SizedBox(width: 12),
          Expanded(
            child: Text('Keep the app open and your band close to the phone. Do not remove it from the charger.',
                style: AppText.body(c, size: 13, color: c.warn)),
          ),
        ]),
      ),
    ]);
  }
}

class _Check extends StatelessWidget {
  const _Check({required this.label, required this.value, required this.ok});
  final String label;
  final String value;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return AppCard(
      radius: 20,
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: AppText.muted(c, size: 12)),
        const SizedBox(height: 6),
        Row(children: [
          Dot(color: ok ? c.accent : c.warn, size: 8),
          const SizedBox(width: 6),
          Flexible(child: Text(value, style: AppText.label(c, size: 15))),
        ]),
      ]),
    );
  }
}
