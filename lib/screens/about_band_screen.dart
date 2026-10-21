import 'package:flutter/material.dart';

import '../state/scope.dart';
import '../theme/tokens.dart';
import '../ui/icons.dart';
import '../ui/widgets.dart';

class AboutBandScreen extends StatelessWidget {
  const AboutBandScreen({super.key});

  Future<void> _rename(BuildContext context) async {
    final s = context.services;
    final c = AppTheme.of(context);
    final controller = TextEditingController(text: s.store.band?.displayName ?? 'My Band');
    final name = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (ctx) => AppTheme(
        colors: c,
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 24 + MediaQuery.of(ctx).padding.bottom),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text('Rename band', style: AppText.title(c)),
              const SizedBox(height: 16),
              AppField(label: 'Band name', controller: controller, textInputAction: TextInputAction.done),
              const SizedBox(height: 16),
              PillButton(label: 'Save', onTap: () => Navigator.of(ctx).pop(controller.text)),
            ]),
          ),
        ),
      ),
    );
    if (name != null) {
      await s.store.renameBand(name);
      await s.band.setName(s.store.band!.displayName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final s = context.services;
    return PageScaffold(
      scroll: true,
      child: Watch(
        listenables: [s.store, s.band],
        builder: (context) {
          final saved = s.store.band;
          final band = s.band;
          final rows = <(String, String, bool)>[
            ('Model', 'AI Band MVP', false),
            ('Chip', 'ESP32 S3', false),
            ('Firmware', band.firmware.isEmpty ? 'Unknown' : band.firmware, true),
            ('Bluetooth ID', saved?.id ?? 'None', true),
            ('Connection', band.connected ? 'Connected' : 'Not connected', false),
            ('Water resistance', 'Rating pending test', false),
          ];
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const SubHeader(title: 'About this band', backLabel: 'Back to device'),
            const SizedBox(height: 14),
            AppCard(
              radius: 24,
              child: Row(children: [
                const BandMark(size: 72, strokeWidth: 4, showSpeaker: false),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(saved?.displayName ?? 'My Band', style: AppText.label(c, size: 18)),
                    const SizedBox(height: 3),
                    Text.rich(
                        TextSpan(children: [
                          const TextSpan(text: 'AI Band '),
                          TextSpan(text: saved?.shortCode ?? '', style: const TextStyle(fontFamily: AppFonts.mono)),
                        ]),
                        style: AppText.muted(c)),
                  ]),
                ),
                PillButton(
                  label: 'Rename',
                  icon: AppIcons.pencil,
                  tone: ButtonTone.outline,
                  expand: false,
                  height: 40,
                  fontSize: 13,
                  onTap: saved == null ? null : () => _rename(context),
                ),
              ]),
            ),
            const SizedBox(height: 14),
            GroupCard(children: [
              for (var i = 0; i < rows.length; i++)
                Container(
                  constraints: const BoxConstraints(minHeight: 46),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(border: i == 0 ? null : Border(top: BorderSide(color: c.border))),
                  child: Row(children: [
                    Text(rows[i].$1, style: AppText.body(c, size: 14, color: c.muted)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        rows[i].$2,
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            rows[i].$3 ? AppText.mono(c, size: 13) : AppText.body(c, size: 14, weight: FontWeight.w500),
                      ),
                    ),
                  ]),
                ),
            ]),
            const SizedBox(height: 14),
            GroupCard(children: [
              ListRow(
                icon: AppIcons.restart,
                label: 'Restart band',
                showChevron: false,
                onTap: band.connected
                    ? () {
                        band.restart();
                        showToast(context, 'Your band is restarting');
                      }
                    : null,
              ),
              ListRow(
                icon: AppIcons.bluetoothOff,
                label: band.connected ? 'Disconnect for now' : 'Reconnect',
                topBorder: true,
                showChevron: false,
                onTap: saved == null ? null : () => band.connected ? band.disconnect() : band.reconnect(),
              ),
              ListRow(
                icon: AppIcons.trash,
                label: 'Remove this band',
                color: c.danger,
                topBorder: true,
                showChevron: false,
                onTap: saved == null
                    ? null
                    : () async {
                        final ok = await showConfirmSheet(
                          context,
                          title: 'Remove ${saved.displayName}?',
                          message:
                              'You will need to pair it again to use it. Your saved conversations will stay in the app.',
                          confirmLabel: 'Remove band',
                          icon: AppIcons.trash,
                        );
                        if (ok == true) {
                          await band.disconnect(forget: true);
                          if (context.mounted) Navigator.of(context).pop();
                        }
                      },
              ),
              ListRow(
                icon: AppIcons.reset,
                label: 'Factory reset',
                color: c.danger,
                topBorder: true,
                showChevron: false,
                onTap: band.connected
                    ? () async {
                        final ok = await showConfirmSheet(
                          context,
                          title: 'Factory reset the band?',
                          message: 'This erases all settings on the band and removes it from this phone.',
                          confirmLabel: 'Reset band',
                          icon: AppIcons.reset,
                        );
                        if (ok == true) {
                          await band.factoryReset();
                          await band.disconnect(forget: true);
                          if (context.mounted) Navigator.of(context).pop();
                        }
                      }
                    : null,
              ),
            ]),
          ]);
        },
      ),
    );
  }
}
