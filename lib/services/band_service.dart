import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:universal_ble/universal_ble.dart';

import '../models/models.dart';
import '../state/app_store.dart';
import 'audio_codec.dart';
import 'ble_protocol.dart';

enum LinkState { idle, scanning, connecting, connected }

/// A band found while scanning.
class FoundBand {
  FoundBand({required this.id, required this.name, required this.rssi, this.demo = false});
  final String id;
  final String name;
  int rssi;
  final bool demo;

  /// 1 to 4 bars from the signal strength.
  int get bars {
    if (rssi >= -60) return 4;
    if (rssi >= -70) return 3;
    if (rssi >= -82) return 2;
    return 1;
  }

  String get signalLabel => bars >= 3 ? 'Strong signal' : (bars == 2 ? 'Good signal' : 'Weak signal');
}

/// Something the band told the app.
enum BandEventType { buttonDown, buttonUp, listenStarted, listenEnded, playDone, otaResult }

class BandEvent {
  const BandEvent(this.type, [this.value = 0]);
  final BandEventType type;
  final int value;
}

/// Talks to the ESP32 S3 band over Bluetooth Low Energy using the protocol in
/// ble_protocol.dart. A built in demo band lets the whole app be tried
/// without hardware (Help, or the pairing screen, turns it on).
class BandService extends ChangeNotifier {
  BandService(this.store);

  final AppStore store;

  bool _bleWired = false;

  /// Wires up the native BLE callbacks the first time anything actually needs
  /// Bluetooth. Doing this lazily keeps a plugin failure from blocking startup.
  void _ensureBle() {
    if (_bleWired) return;
    try {
      UniversalBle.onScanResult = _onScanResult;
      UniversalBle.onConnectionChange = _onConnectionChange;
      UniversalBle.onValueChange = _onValue;
      UniversalBle.onAvailabilityChange = (s) {
        bluetoothState = s;
        notifyListeners();
      };
      _bleWired = true;
    } catch (e) {
      lastError = '$e';
    }
  }

  LinkState state = LinkState.idle;
  AvailabilityState bluetoothState = AvailabilityState.unknown;
  final List<FoundBand> found = [];

  int? battery;
  bool charging = false;
  String firmware = '';
  int rssi = -60;
  DateTime? lastSeen;
  int volume = 70;
  bool ringing = false;
  bool vibrating = false;
  String? lastError;

  String? _deviceId;
  bool _demo = false;
  int _mtu = 23;
  Timer? _rssiTimer;
  Timer? _demoTimer;
  bool _userDisconnect = false;

  final _events = StreamController<BandEvent>.broadcast();
  final _mic = StreamController<Uint8List>.broadcast();
  final _adpcmIn = ImaAdpcm();
  int _micCodec = Codec.imaAdpcm;

  /// Sample rate of the band microphone stream.
  int micSampleRate = 16000;

  /// Band events (button presses, playback finished and so on).
  Stream<BandEvent> get events => _events.stream;

  /// Microphone audio from the band as 16 bit little endian PCM.
  Stream<Uint8List> get micPcm => _mic.stream;

  bool get connected => state == LinkState.connected;
  bool get isDemo => _demo;
  int get signalBars => rssi >= -60 ? 4 : (rssi >= -70 ? 3 : (rssi >= -82 ? 2 : 1));
  String get signalWord => signalBars >= 3 ? 'Strong' : (signalBars == 2 ? 'Good' : 'Weak');

  /// Distance band from signal strength, used by Find my band.
  int get proximityLevel {
    if (rssi >= -55) return 3;
    if (rssi >= -67) return 2;
    if (rssi >= -80) return 1;
    return 0;
  }

  // ----------------------------------------------------------- permissions

  /// Asks for the Bluetooth permissions. Returns true when Bluetooth can be used.
  Future<bool> requestPermissions() async {
    _ensureBle();
    try {
      await UniversalBle.requestPermissions();
      bluetoothState = await UniversalBle.getBluetoothAvailabilityState();
      notifyListeners();
      return bluetoothState == AvailabilityState.poweredOn;
    } catch (e) {
      lastError = '$e';
      return false;
    }
  }

  Future<bool> hasPermissions() async {
    _ensureBle();
    try {
      return await UniversalBle.hasPermissions();
    } catch (_) {
      return false;
    }
  }

  // ------------------------------------------------------------- scanning

  Future<void> startScan() async {
    _ensureBle();
    found.clear();
    if (store.settings.demoMode) _addDemoResult();
    state = LinkState.scanning;
    notifyListeners();
    try {
      await UniversalBle.requestPermissions();
      bluetoothState = await UniversalBle.getBluetoothAvailabilityState();
      if (bluetoothState != AvailabilityState.poweredOn) {
        lastError = 'Bluetooth is off';
        notifyListeners();
        return;
      }
      await UniversalBle.startScan();
    } catch (e) {
      lastError = '$e';
      notifyListeners();
    }
  }

  Future<void> stopScan() async {
    try {
      await UniversalBle.stopScan();
    } catch (_) {}
    if (state == LinkState.scanning) {
      state = LinkState.idle;
      notifyListeners();
    }
  }

  void _addDemoResult() {
    if (found.any((f) => f.demo)) return;
    found.add(FoundBand(id: 'demo-band', name: 'AI Band 4F2A', rssi: -55, demo: true));
  }

  void enableDemo() {
    store.updateSettings((s) => s.demoMode = true);
    _addDemoResult();
    notifyListeners();
  }

  void _onScanResult(BleDevice d) {
    final name = d.name ?? '';
    final ours =
        name.startsWith(BandUuids.namePrefix) || d.services.map((s) => s.toLowerCase()).contains(BandUuids.service);
    if (!ours) return;
    final existing = found.where((f) => f.id == d.deviceId);
    if (existing.isNotEmpty) {
      existing.first.rssi = d.rssi ?? existing.first.rssi;
    } else {
      found.add(FoundBand(id: d.deviceId, name: name.isEmpty ? 'AI Band' : name, rssi: d.rssi ?? -80));
    }
    if (d.deviceId == _deviceId) {
      rssi = d.rssi ?? rssi;
      lastSeen = DateTime.now();
    }
    notifyListeners();
  }

  // ----------------------------------------------------------- connecting

  /// Connects to a band found during the scan and remembers it.
  Future<bool> connect(FoundBand band) async {
    _ensureBle();
    await stopScan();
    final ok = band.demo ? await _connectDemo() : await _connectReal(band.id);
    if (ok) {
      final saved = SavedBand(
        id: band.id,
        advertisedName: band.name,
        displayName: store.band?.id == band.id ? store.band!.displayName : 'My Band',
        demo: band.demo,
      );
      await store.setBand(saved);
      await store.addNotice(NoticeKind.paired, 'Band paired', '${band.name} is ready to use.');
      await pushSettings();
    }
    return ok;
  }

  /// Reconnects to the remembered band (called at start up and from the
  /// Reconnect button).
  Future<bool> reconnect() async {
    _ensureBle();
    final b = store.band;
    if (b == null) return false;
    if (b.demo) return _connectDemo();
    return _connectReal(b.id);
  }

  Future<bool> _connectReal(String id) async {
    _demo = false;
    _userDisconnect = false;
    _deviceId = id;
    state = LinkState.connecting;
    lastError = null;
    notifyListeners();
    try {
      await UniversalBle.connect(id, timeout: const Duration(seconds: 15));
      await UniversalBle.discoverServices(id);
      try {
        _mtu = await UniversalBle.requestMtu(id, 247);
      } catch (_) {
        _mtu = 23;
      }
      await UniversalBle.subscribeNotifications(id, BandUuids.service, BandUuids.events);
      await UniversalBle.subscribeNotifications(id, BandUuids.service, BandUuids.audioUp);
      try {
        await UniversalBle.subscribeNotifications(id, BandUuids.batteryService, BandUuids.batteryLevel);
        final b = await UniversalBle.read(id, BandUuids.batteryService, BandUuids.batteryLevel);
        if (b.isNotEmpty) battery = b[0];
      } catch (_) {}
      try {
        final fw = await UniversalBle.read(id, BandUuids.deviceInfoService, BandUuids.firmwareRevision);
        firmware = utf8.decode(fw, allowMalformed: true).trim();
      } catch (_) {}
      state = LinkState.connected;
      lastSeen = DateTime.now();
      _startRssi();
      await _write(Cmd.getStatus);
      notifyListeners();
      return true;
    } catch (e) {
      lastError = '$e';
      state = LinkState.idle;
      notifyListeners();
      return false;
    }
  }

  Future<bool> _connectDemo() async {
    _demo = true;
    _deviceId = 'demo-band';
    state = LinkState.connecting;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 900));
    battery = 82;
    charging = false;
    firmware = '1.0.3';
    rssi = -55;
    lastSeen = DateTime.now();
    state = LinkState.connected;
    _demoTimer?.cancel();
    _demoTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      // Gentle signal wobble so the radar and signal labels feel alive.
      rssi = _demoAnchor + Random().nextInt(5) - 2;
      lastSeen = DateTime.now();
      notifyListeners();
    });
    notifyListeners();
    return true;
  }

  void _startRssi() {
    _rssiTimer?.cancel();
    _rssiTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      final id = _deviceId;
      if (id == null || !connected || _demo) return;
      try {
        rssi = await UniversalBle.readRssi(id);
        lastSeen = DateTime.now();
        notifyListeners();
      } catch (_) {}
    });
  }

  /// Disconnects. When [forget] is true the band is removed from this phone.
  Future<void> disconnect({bool forget = false}) async {
    _userDisconnect = true;
    _rssiTimer?.cancel();
    _demoTimer?.cancel();
    final id = _deviceId;
    if (id != null && !_demo) {
      try {
        await UniversalBle.disconnect(id);
      } catch (_) {}
    }
    state = LinkState.idle;
    ringing = false;
    vibrating = false;
    if (forget) {
      _deviceId = null;
      battery = null;
      firmware = '';
      await store.setBand(null);
    }
    notifyListeners();
  }

  void _onConnectionChange(BleConnectionChange ch) {
    if (ch.deviceId != _deviceId || _demo) return;
    if (ch.isConnected) {
      state = LinkState.connected;
    } else if (state == LinkState.connected) {
      state = LinkState.idle;
      _rssiTimer?.cancel();
      if (!_userDisconnect) {
        store.addNotice(
            NoticeKind.disconnected, 'Band disconnected', 'Last seen near your phone at ${_hhmm(DateTime.now())}.');
      }
    }
    notifyListeners();
  }

  String _hhmm(DateTime t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  // --------------------------------------------------------------- values

  void _onValue(BleCharacteristicValue v) {
    if (v.deviceId != _deviceId) return;
    final ch = v.characteristicId.toLowerCase();
    final data = v.value;
    if (ch == BandUuids.audioUp) {
      _onMicChunk(data);
    } else if (ch == BandUuids.events) {
      _onEvent(data);
    } else if (ch == BandUuids.batteryLevel && data.isNotEmpty) {
      _setBattery(data[0]);
    }
  }

  void _setBattery(int level) {
    final before = battery;
    battery = level.clamp(0, 100);
    if (battery! <= 15 && (before == null || before > 15) && !charging) {
      store.addNotice(NoticeKind.battery, 'Battery at $battery%', 'Place your band on the magnetic charger.');
    }
    notifyListeners();
  }

  void _onMicChunk(Uint8List data) {
    if (_micCodec == Codec.imaAdpcm) {
      _mic.add(Pcm.toBytes(_adpcmIn.decode(data)));
    } else {
      _mic.add(data);
    }
  }

  void _onEvent(Uint8List d) {
    if (d.isEmpty) return;
    switch (d[0]) {
      case Evt.buttonDown:
        _events.add(const BandEvent(BandEventType.buttonDown));
      case Evt.buttonUp:
        _events.add(const BandEvent(BandEventType.buttonUp));
      case Evt.listenStarted:
        _micCodec = d.length > 1 ? d[1] : Codec.imaAdpcm;
        if (d.length > 3) micSampleRate = d[2] | (d[3] << 8);
        _adpcmIn.reset();
        _events.add(const BandEvent(BandEventType.listenStarted));
      case Evt.listenEnded:
        _events.add(const BandEvent(BandEventType.listenEnded));
      case Evt.playDone:
        _events.add(const BandEvent(BandEventType.playDone));
      case Evt.status:
        if (d.length >= 8) {
          _setBattery(d[1]);
          charging = d[2] == 1;
          firmware = '${d[3]}.${d[4]}.${d[5]}';
          volume = d[6];
        }
      case Evt.charging:
        charging = d.length > 1 && d[1] == 1;
      case Evt.otaProgress:
        if (d.length > 1) otaProgress = d[1] / 100;
      case Evt.otaResult:
        _events.add(BandEvent(BandEventType.otaResult, d.length > 1 ? d[1] : 0));
    }
    notifyListeners();
  }

  // ------------------------------------------------------------- commands

  Future<void> _write(int cmd, [List<int> payload = const []]) async {
    final id = _deviceId;
    if (id == null || !connected) return;
    if (_demo) return _demoCommand(cmd, payload);
    try {
      await UniversalBle.write(id, BandUuids.service, BandUuids.control, Uint8List.fromList([cmd, ...payload]));
    } catch (e) {
      lastError = '$e';
    }
  }

  void _demoCommand(int cmd, List<int> payload) {
    if (cmd == Cmd.restart) {
      state = LinkState.connecting;
      notifyListeners();
      Future.delayed(const Duration(seconds: 2), () {
        state = LinkState.connected;
        notifyListeners();
      });
    }
  }

  /// Sends the stored settings to the band (after connecting or changing them).
  Future<void> pushSettings() async {
    final s = store.settings;
    await setVolume(s.volume);
    await setVibration(s.vibration);
    await setButtonMode(s.buttonMode);
    if (store.band != null) await setName(store.band!.displayName);
  }

  Future<void> setVolume(int v) async {
    volume = v;
    await _write(Cmd.setVolume, [v.clamp(0, 100)]);
  }

  Future<void> setVibration(VibrationStrength v) => _write(Cmd.setVibration, [v.index]);
  Future<void> setButtonMode(ButtonMode m) => _write(Cmd.setButtonMode, [m.index]);
  Future<void> vibrate([int pattern = 1]) => _write(Cmd.vibrate, [pattern]);
  Future<void> setName(String name) => _write(Cmd.setName, utf8.encode(name).take(20).toList());
  Future<void> restart() => _write(Cmd.restart);
  Future<void> factoryReset() => _write(Cmd.factoryReset);

  Future<void> setRinging(bool on) async {
    ringing = on;
    notifyListeners();
    await _write(Cmd.find, [on ? 1 : 0]);
  }

  Future<void> setFindVibrate(bool on) async {
    vibrating = on;
    notifyListeners();
    await _write(Cmd.findVibrateOnly, [on ? 1 : 0]);
  }

  Future<void> startListening() => _write(Cmd.startListen);
  Future<void> stopListening() => _write(Cmd.stopListen);

  // ------------------------------------------------------------- playback

  bool _abortPlay = false;

  /// Streams reply audio (16 bit PCM at [rate]) to the band speaker as IMA
  /// ADPCM, paced slightly ahead of real time so the band buffer never runs
  /// dry or overflows. Completes when everything has been sent.
  Future<void> playOnBand(Int16List pcm, int rate) async {
    final id = _deviceId;
    if (id == null || !connected || _demo) return;
    _abortPlay = false;
    final enc = ImaAdpcm();
    final data = enc.encode(pcm);
    await _write(Cmd.playStart, [
      Codec.imaAdpcm,
      rate & 0xFF,
      (rate >> 8) & 0xFF,
      data.length & 0xFF,
      (data.length >> 8) & 0xFF,
      (data.length >> 16) & 0xFF,
      (data.length >> 24) & 0xFF,
    ]);
    final chunk = max(20, _mtu - 3);
    final bytesPerSecond = rate / 2; // 4 bits per sample
    const lead = 0.6; // seconds of audio kept ahead in the band buffer
    final sw = Stopwatch()..start();
    var sent = 0;
    while (sent < data.length && !_abortPlay && connected) {
      final allowed = (sw.elapsedMilliseconds / 1000 + lead) * bytesPerSecond;
      if (sent > allowed) {
        await Future<void>.delayed(const Duration(milliseconds: 15));
        continue;
      }
      final end = min(sent + chunk, data.length);
      try {
        await UniversalBle.write(id, BandUuids.service, BandUuids.audioDown, data.sublist(sent, end),
            withoutResponse: true);
      } catch (_) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        continue;
      }
      sent = end;
    }
    await _write(_abortPlay ? Cmd.playAbort : Cmd.playEnd);
  }

  Future<void> abortPlayback() async {
    _abortPlay = true;
    await _write(Cmd.playAbort);
  }

  // ------------------------------------------------------------------ OTA

  double otaProgress = 0;

  /// Sends a firmware image to the band. [onProgress] gets 0..1.
  Future<bool> sendFirmware(Uint8List image, void Function(double) onProgress) async {
    final id = _deviceId;
    if (id == null || !connected) return false;
    if (_demo) {
      for (var i = 0; i <= 100; i += 2) {
        await Future<void>.delayed(const Duration(milliseconds: 80));
        onProgress(i / 100);
      }
      return true;
    }
    final size = image.length;
    await _write(Cmd.otaBegin, [size & 0xFF, (size >> 8) & 0xFF, (size >> 16) & 0xFF, (size >> 24) & 0xFF]);
    final chunk = max(20, _mtu - 3);
    var sent = 0;
    try {
      while (sent < size) {
        final end = min(sent + chunk, size);
        await UniversalBle.write(id, BandUuids.service, BandUuids.ota, image.sublist(sent, end));
        sent = end;
        onProgress(sent / size);
      }
      await _write(Cmd.otaEnd);
      final result = await events
          .firstWhere((e) => e.type == BandEventType.otaResult)
          .timeout(const Duration(seconds: 60), onTimeout: () => const BandEvent(BandEventType.otaResult, 1));
      return result.value == 1;
    } catch (e) {
      lastError = '$e';
      await _write(Cmd.otaAbort);
      return false;
    }
  }

  // --------------------------------------------------------------- demo

  int _demoAnchor = -55;

  /// Demo only: moves the pretend band one step closer on Find my band.
  void demoCycleDistance() {
    if (!_demo) return;
    const steps = [-88, -74, -62, -50];
    final i = steps.indexWhere((v) => v > _demoAnchor + 3);
    _demoAnchor = i < 0 ? steps.first : steps[i];
    rssi = _demoAnchor;
    notifyListeners();
  }

  /// Demo only: toggles the charging state so the Charging screen can be seen.
  void demoToggleCharging() {
    if (!_demo) return;
    charging = !charging;
    notifyListeners();
  }

  @override
  void dispose() {
    _rssiTimer?.cancel();
    _demoTimer?.cancel();
    _events.close();
    _mic.close();
    super.dispose();
  }
}
