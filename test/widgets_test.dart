import 'package:esp32_wristband_app/theme/tokens.dart';
import 'package:esp32_wristband_app/ui/icons.dart';
import 'package:esp32_wristband_app/ui/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget wrap(Widget child, {AppColors colors = AppColors.dark}) => MaterialApp(
      home: AppTheme(colors: colors, child: Scaffold(body: Center(child: child))),
    );

void main() {
  testWidgets('switch toggles', (tester) async {
    var value = false;
    await tester.pumpWidget(wrap(StatefulBuilder(
      builder: (context, set) => AppSwitch(value: value, label: 'Test', onChanged: (v) => set(() => value = v)),
    )));
    await tester.tap(find.byType(AppSwitch));
    await tester.pumpAndSettle();
    expect(value, isTrue);
  });

  testWidgets('segmented control picks an option', (tester) async {
    var value = 'a';
    await tester.pumpWidget(wrap(SizedBox(
      width: 300,
      child: StatefulBuilder(
        builder: (context, set) => Segmented<String>(
          value: value,
          onChanged: (v) => set(() => value = v),
          options: const [SegmentOption('a', 'One'), SegmentOption('b', 'Two')],
        ),
      ),
    )));
    await tester.tap(find.text('Two'));
    await tester.pumpAndSettle();
    expect(value, 'b');
  });

  testWidgets('icons and band mark paint in every theme', (tester) async {
    for (final c in [AppColors.light, AppColors.dark, AppColors.night]) {
      await tester.pumpWidget(wrap(
        const Column(mainAxisSize: MainAxisSize.min, children: [
          AppIcon(AppIcons.help),
          AppIcon(AppIcons.bluetooth),
          BandMark(progress: 0.82),
        ]),
        colors: c,
      ));
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('pill button fires', (tester) async {
    var taps = 0;
    await tester.pumpWidget(wrap(PillButton(label: 'Go', onTap: () => taps++)));
    await tester.tap(find.text('Go'));
    expect(taps, 1);
  });
}
