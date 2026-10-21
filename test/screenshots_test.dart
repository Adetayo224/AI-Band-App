// Renders every screen at phone size (390x844) in each of the three themes
// and writes a PNG to test/goldens/. Run with:
//   flutter test test/screenshots_test.dart --update-goldens
// After running, files land at test/goldens/<screen>_<theme>.png.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:esp32_wristband_app/models/models.dart';
import 'package:esp32_wristband_app/screens/about_band_screen.dart';
import 'package:esp32_wristband_app/screens/chat_detail_screen.dart';
import 'package:esp32_wristband_app/screens/find_band_screen.dart';
import 'package:esp32_wristband_app/screens/firmware_screen.dart';
import 'package:esp32_wristband_app/screens/help_screen.dart';
import 'package:esp32_wristband_app/screens/home_shell.dart';
import 'package:esp32_wristband_app/screens/language_screen.dart';
import 'package:esp32_wristband_app/screens/notifications_screen.dart';
import 'package:esp32_wristband_app/screens/onboarding.dart';
import 'package:esp32_wristband_app/screens/personal_data_screen.dart';
import 'package:esp32_wristband_app/screens/splash_screen.dart';
import 'package:esp32_wristband_app/screens/talk_screen.dart';
import 'package:esp32_wristband_app/screens/voice_screen.dart';
import 'package:esp32_wristband_app/services/assistant.dart';
import 'package:esp32_wristband_app/services/band_service.dart';
import 'package:esp32_wristband_app/services/firmware.dart';
import 'package:esp32_wristband_app/services/openai_service.dart';
import 'package:esp32_wristband_app/services/phone_audio.dart';
import 'package:esp32_wristband_app/state/app_store.dart';
import 'package:esp32_wristband_app/state/scope.dart';
import 'package:esp32_wristband_app/theme/tokens.dart';

const _size = Size(390, 844);

void _stubPluginChannels() {
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  Future<Object?> noop(MethodCall _) async => null;
  for (final name in const [
    'com.llfbandit.record/messages',
    'xyz.luan/audioplayers.global',
    'xyz.luan/audioplayers',
    'universal_ble',
  ]) {
    messenger.setMockMethodCallHandler(MethodChannel(name), noop);
  }
  for (final name in const [
    'xyz.luan/audioplayers.global/events',
    'universal_ble/scan',
    'universal_ble/connection',
    'universal_ble/value',
    'universal_ble/availability',
  ]) {
    messenger.setMockStreamHandler(EventChannel(name), _NoopStream());
  }
}

class _NoopStream extends MockStreamHandler {
  @override
  void onCancel(Object? arguments) {}
  @override
  void onListen(Object? arguments, MockStreamHandlerEventSink events) {}
}

Future<Services> _mkServices({AppThemeMode theme = AppThemeMode.dark}) async {
  SharedPreferences.setMockInitialValues({});
  final store = await AppStore.load();
  store.profile = UserProfile(
    name: 'Alex Morgan',
    nickname: 'Alex',
    birthday: '1990-04-12',
    city: 'Amsterdam',
  );
  store.settings
    ..theme = theme
    ..autoNight = false
    ..demoMode = true
    ..volume = 70;
  await store.saveSettings();
  await store.saveProfile();
  await store.setOnboarded(true);
  await store.setBand(SavedBand(
    id: 'demo-band',
    advertisedName: 'AI Band 4F2A',
    displayName: 'My Band',
    demo: true,
  ));

  final c1 = store.startConversation(MicSource.band)
    ..title = 'What is the weather today?'
    ..messages.addAll([
      ChatMessage(fromUser: true, text: 'What is the weather today in Amsterdam?', durationMs: 3200),
      ChatMessage(
          fromUser: false,
          text: 'It is 14 degrees and partly cloudy in Amsterdam, with light winds from the west.',
          durationMs: 7100),
    ]);
  final c2 = store.startConversation(MicSource.phone)
    ..title = 'Remind me to call mum'
    ..pinned = true
    ..messages.addAll([
      ChatMessage(fromUser: true, text: 'Remind me to call mum tomorrow at 6pm', durationMs: 2900),
      ChatMessage(fromUser: false, text: 'Reminder set for tomorrow at 18:00.', durationMs: 2500),
    ]);
  store.conversations
    ..clear()
    ..addAll([c2, c1]);
  await store.addNotice(NoticeKind.firmware, 'Firmware 1.1.0 available', 'Clearer audio and faster startup.');
  await store.addNotice(NoticeKind.battery, 'Battery low', 'The band is at 15%.');
  await store.addNotice(NoticeKind.paired, 'Band paired', 'You can start talking any time.');

  final band = BandService(store);
  band.state = LinkState.connected;
  band.battery = 72;
  band.charging = false;
  band.firmware = '1.0.0';
  band.rssi = -58;
  band.lastSeen = DateTime.now();
  band.volume = 70;

  final ai = OpenAiService();
  final audio = PhoneAudio();
  final assistant = Assistant(store: store, band: band, ai: ai, audio: audio);
  final firmware = FirmwareUpdater(band: band, store: store, net: ai);
  return Services(store: store, band: band, assistant: assistant, audio: audio, ai: ai, firmware: firmware);
}

Widget _wrap(Services s, Widget child) {
  final colors = AppColors.of(s.store.effectiveTheme);
  return AppScope(
    services: s,
    child: AppTheme(
      colors: colors,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          scaffoldBackgroundColor: colors.bg,
          canvasColor: colors.bg,
          colorScheme: (colors.isLight ? const ColorScheme.light() : const ColorScheme.dark()).copyWith(
            primary: colors.accent,
            onPrimary: colors.onAccent,
            surface: colors.surface,
            onSurface: colors.text,
          ),
          textTheme: const TextTheme().apply(
            fontFamily: AppFonts.sans,
            bodyColor: colors.text,
            displayColor: colors.text,
          ),
          sliderTheme: SliderThemeData(
            activeTrackColor: colors.accent,
            inactiveTrackColor: colors.track,
            thumbColor: colors.accent,
            overlayColor: colors.accent.withValues(alpha: 0.15),
            trackHeight: 6,
          ),
          splashFactory: NoSplash.splashFactory,
        ),
        builder: (context, w) => AppTheme(colors: colors, child: w!),
        home: Material(type: MaterialType.transparency, child: child),
      ),
    ),
  );
}

Future<void> _snap(
  WidgetTester tester,
  String name,
  Widget Function(Services s) build, {
  void Function(Services s)? setup,
  Duration pumpFor = const Duration(milliseconds: 900),
}) async {
  for (final mode in AppThemeMode.values) {
    final s = await _mkServices(theme: mode);
    if (setup != null) setup(s);
    await tester.binding.setSurfaceSize(_size);
    tester.view.physicalSize = _size;
    tester.view.devicePixelRatio = 1.0;
    await tester.pumpWidget(_wrap(s, build(s)));
    // Pump many small frames so AnimationControllers and Future.delayed-
    // scheduled intros actually tick, instead of jumping with one big frame.
    final step = const Duration(milliseconds: 50);
    final steps = (pumpFor.inMilliseconds / step.inMilliseconds).ceil();
    for (var i = 0; i < steps; i++) {
      await tester.pump(step);
    }
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/${name}_${mode.name}.png'),
    );
    await tester.pumpWidget(const SizedBox.shrink());
    s.store.dispose();
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  }
}

/// A HomeShell that lands on a given tab for the screenshot.
class _ShellOnTab extends StatefulWidget {
  const _ShellOnTab(this.tab);
  final AppTab tab;
  @override
  State<_ShellOnTab> createState() => _ShellOnTabState();
}

class _ShellOnTabState extends State<_ShellOnTab> {
  final GlobalKey<HomeShellState> _k = GlobalKey<HomeShellState>();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _k.currentState?.goTo(widget.tab);
    });
  }

  @override
  Widget build(BuildContext context) => HomeShell(key: _k);
}

Future<void> _loadFonts() async {
  Future<void> load(String family, List<String> paths) async {
    final loader = FontLoader(family);
    for (final p in paths) {
      loader.addFont(File(p).readAsBytes().then((b) => ByteData.view(b.buffer)));
    }
    await loader.load();
  }
  await load(AppFonts.sans, [
    'assets/fonts/Geist-Regular.ttf',
    'assets/fonts/Geist-Medium.ttf',
    'assets/fonts/Geist-SemiBold.ttf',
    'assets/fonts/Geist-Bold.ttf',
  ]);
  await load(AppFonts.mono, [
    'assets/fonts/GeistMono-Regular.ttf',
    'assets/fonts/GeistMono-Medium.ttf',
    'assets/fonts/GeistMono-SemiBold.ttf',
  ]);
}

void main() {
  // The screens include "now" timestamps, so goldens only match on the run
  // that writes them. Skip the comparison during a plain `flutter test` so
  // we don't fail CI; this file is a dev tool run with --update-goldens.
  if (!autoUpdateGoldenFiles) {
    test('screenshots suite — run with --update-goldens to regenerate', () {});
    return;
  }
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(_loadFonts);
  setUp(_stubPluginChannels);

  // Splash: pump just under its 1700ms auto-navigation timer so the Rise
  // and Pop intros finish painting but we never navigate away.
  testWidgets('splash', (t) => _snap(t, 'splash', (_) => const SplashScreen(),
      pumpFor: const Duration(milliseconds: 1500)));

  testWidgets('welcome', (t) => _snap(t, 'welcome', (_) => const WelcomeScreen()));
  testWidgets('about_you', (t) => _snap(t, 'about_you', (_) => const AboutYouScreen()));
  testWidgets('permissions', (t) => _snap(t, 'permissions', (_) => const PermissionsScreen()));
  testWidgets('pairing', (t) => _snap(t, 'pairing', (_) => const PairingScreen()));
  testWidgets('pair_fail', (t) => _snap(t, 'pair_fail', (_) => const PairFailScreen()));
  testWidgets('paired', (t) => _snap(t, 'paired', (_) => const PairedScreen()));

  testWidgets('home_normal', (t) => _snap(t, 'home_normal', (_) => const HomeShell()));
  testWidgets('home_disconnected', (t) async {
    await _snap(t, 'home_disconnected', (_) => const HomeShell(), setup: (s) {
      s.band.state = LinkState.idle;
      s.band.battery = null;
    });
  });
  testWidgets('home_charging', (t) async {
    await _snap(t, 'home_charging', (_) => const HomeShell(), setup: (s) {
      s.band.charging = true;
      s.band.battery = 48;
    });
  });

  testWidgets('talk', (t) => _snap(t, 'talk', (_) => const TalkScreen()));

  testWidgets('conversation_detail', (t) async {
    await _snap(t, 'conversation_detail', (s) {
      final c = s.store.conversations.firstWhere((x) => x.messages.isNotEmpty);
      return ChatDetailScreen(id: c.id);
    });
  });

  testWidgets('notifications', (t) => _snap(t, 'notifications', (_) => const NotificationsScreen()));
  testWidgets('find_band', (t) => _snap(t, 'find_band', (_) => const FindBandScreen()));
  testWidgets('firmware', (t) => _snap(t, 'firmware', (_) => const FirmwareScreen()));
  testWidgets('about_band', (t) => _snap(t, 'about_band', (_) => const AboutBandScreen()));

  testWidgets('conversations', (t) => _snap(t, 'conversations', (_) => const _ShellOnTab(AppTab.chats)));
  testWidgets('device', (t) => _snap(t, 'device', (_) => const _ShellOnTab(AppTab.device)));
  testWidgets('settings', (t) => _snap(t, 'settings', (_) => const _ShellOnTab(AppTab.settings)));

  testWidgets('personal_data', (t) => _snap(t, 'personal_data', (_) => const PersonalDataScreen()));
  testWidgets('voice', (t) => _snap(t, 'voice', (_) => const VoiceScreen()));
  testWidgets('language', (t) => _snap(t, 'language', (_) => const LanguageScreen()));
  testWidgets('help', (t) => _snap(t, 'help', (_) => const HelpScreen()));
}
