import 'package:flutter/widgets.dart';

import '../services/assistant.dart';
import '../services/band_service.dart';
import '../services/firmware.dart';
import '../services/openai_service.dart';
import '../services/phone_audio.dart';
import 'app_store.dart';

/// Gives every screen access to the app services.
class Services {
  Services({
    required this.store,
    required this.band,
    required this.assistant,
    required this.audio,
    required this.ai,
    required this.firmware,
  });

  final AppStore store;
  final BandService band;
  final Assistant assistant;
  final PhoneAudio audio;
  final OpenAiService ai;
  final FirmwareUpdater firmware;

  static Future<Services> create() async {
    final store = await AppStore.load();
    // Each service is built in isolation so one failing plugin can't keep the
    // app stuck on the Flutter launch screen. Native plugin work (Bluetooth,
    // microphone, speaker) is deferred until the user actually triggers it.
    BandService band;
    try {
      band = BandService(store);
    } catch (e, s) {
      debugPrint('BandService init failed: $e\n$s');
      rethrow;
    }
    OpenAiService ai;
    try {
      ai = OpenAiService();
    } catch (e, s) {
      debugPrint('OpenAiService init failed: $e\n$s');
      rethrow;
    }
    PhoneAudio audio;
    try {
      audio = PhoneAudio();
    } catch (e, s) {
      debugPrint('PhoneAudio init failed: $e\n$s');
      rethrow;
    }
    Assistant assistant;
    try {
      assistant = Assistant(store: store, band: band, ai: ai, audio: audio);
    } catch (e, s) {
      debugPrint('Assistant init failed: $e\n$s');
      rethrow;
    }
    final firmware = FirmwareUpdater(band: band, store: store, net: ai);
    return Services(
        store: store, band: band, assistant: assistant, audio: audio, ai: ai, firmware: firmware);
  }
}

class AppScope extends InheritedWidget {
  const AppScope({super.key, required this.services, required super.child});

  final Services services;

  static Services of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<AppScope>()!.services;

  @override
  bool updateShouldNotify(AppScope oldWidget) => oldWidget.services != services;
}

/// Shortcuts: `context.store`, `context.band` and so on.
extension ScopeX on BuildContext {
  Services get services => AppScope.of(this);
  AppStore get store => AppScope.of(this).store;
  BandService get band => AppScope.of(this).band;
  Assistant get assistant => AppScope.of(this).assistant;
}

/// Rebuilds when any of [listenables] changes.
class Watch extends StatelessWidget {
  const Watch({super.key, required this.listenables, required this.builder});
  final List<Listenable> listenables;
  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) =>
      ListenableBuilder(listenable: Listenable.merge(listenables), builder: (context, _) => builder(context));
}
