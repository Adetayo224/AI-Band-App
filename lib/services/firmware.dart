import 'package:flutter/foundation.dart';

import '../config.dart';
import '../models/models.dart';
import '../state/app_store.dart';
import 'band_service.dart';
import 'openai_service.dart';

enum FirmwareStage { checking, upToDate, available, downloading, sending, installing, done, failed }

/// Checks for new band firmware and installs it over Bluetooth.
///
/// The newest version is described by a small JSON file whose address is set
/// with --dart-define=FIRMWARE_MANIFEST_URL=... (see README). Without it the
/// band is reported as up to date.
class FirmwareUpdater extends ChangeNotifier {
  FirmwareUpdater({required this.band, required this.store, required this.net});

  final BandService band;
  final AppStore store;
  final OpenAiService net;

  FirmwareStage stage = FirmwareStage.upToDate;
  String latestVersion = '';
  List<String> notes = const [];
  Uri? _imageUrl;
  double progress = 0;
  String? error;

  bool get updateAvailable => stage == FirmwareStage.available;

  static int _cmp(String a, String b) {
    List<int> parts(String v) =>
        v.split('.').map((e) => int.tryParse(e.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0).toList();
    final x = parts(a), y = parts(b);
    for (var i = 0; i < 3; i++) {
      final d = (i < x.length ? x[i] : 0) - (i < y.length ? y[i] : 0);
      if (d != 0) return d;
    }
    return 0;
  }

  Future<void> check() async {
    if (band.isDemo) {
      latestVersion = '1.1.0';
      notes = const [
        'Clearer audio when replies play on the band speaker',
        'Faster voice transfer to your phone over Bluetooth',
        'Longer battery life when the band is idle',
        'Fixes for button presses being missed',
      ];
      stage = _cmp(latestVersion, band.firmware) > 0 ? FirmwareStage.available : FirmwareStage.upToDate;
      notifyListeners();
      return;
    }
    if (AppConfig.firmwareManifestUrl.isEmpty || band.firmware.isEmpty) {
      stage = FirmwareStage.upToDate;
      notifyListeners();
      return;
    }
    stage = FirmwareStage.checking;
    notifyListeners();
    try {
      final m = await net.getJson(Uri.parse(AppConfig.firmwareManifestUrl));
      latestVersion = m['version'] as String? ?? '';
      notes = ((m['notes'] as List?) ?? const []).map((e) => '$e').toList();
      _imageUrl = Uri.tryParse(m['url'] as String? ?? '');
      final newer = _cmp(latestVersion, band.firmware) > 0 && _imageUrl != null;
      stage = newer ? FirmwareStage.available : FirmwareStage.upToDate;
      if (newer) {
        await store.addNotice(
            NoticeKind.firmware, 'Firmware $latestVersion is ready', 'Tap to install it on your band.');
      }
    } catch (e) {
      stage = FirmwareStage.upToDate;
      error = '$e';
    }
    notifyListeners();
  }

  Future<void> install() async {
    if (!band.connected) {
      error = 'Connect your band first.';
      stage = FirmwareStage.failed;
      notifyListeners();
      return;
    }
    error = null;
    progress = 0;
    try {
      Uint8List image;
      if (band.isDemo) {
        image = Uint8List(1);
      } else {
        stage = FirmwareStage.downloading;
        notifyListeners();
        image = await net.download(_imageUrl!);
      }
      stage = FirmwareStage.sending;
      notifyListeners();
      final ok = await band.sendFirmware(image, (p) {
        progress = p;
        notifyListeners();
      });
      if (!ok) throw Exception(band.lastError ?? 'The band did not accept the update.');
      stage = FirmwareStage.installing;
      notifyListeners();
      await Future<void>.delayed(const Duration(seconds: 2));
      if (band.isDemo) band.firmware = latestVersion;
      stage = FirmwareStage.done;
    } catch (e) {
      error = '$e';
      stage = FirmwareStage.failed;
    }
    notifyListeners();
  }

  void cancel() {
    if (stage == FirmwareStage.sending || stage == FirmwareStage.downloading) {
      stage = FirmwareStage.available;
      notifyListeners();
    }
  }
}
