import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:record/record.dart';

/// Phone microphone and speaker. Used when the user talks from the phone,
/// when the band is away or charging, and to replay saved messages.
class PhoneAudio {
  AudioRecorder? _recorderInst;
  AudioPlayer? _playerInst;
  AudioRecorder get _recorder => _recorderInst ??= AudioRecorder();
  AudioPlayer get _player => _playerInst ??= AudioPlayer();
  StreamSubscription<Uint8List>? _micSub;

  static const micRate = 16000;

  Future<bool> hasMicPermission({bool request = true}) => _recorder.hasPermission(request: request);

  /// Starts the phone microphone; [onPcm] receives 16 bit mono PCM at 16 kHz.
  Future<void> startMic(void Function(Uint8List pcm) onPcm) async {
    if (!await _recorder.hasPermission()) {
      throw Exception('Microphone permission was not granted.');
    }
    final stream = await _recorder.startStream(const RecordConfig(
      encoder: AudioEncoder.pcm16bits,
      sampleRate: micRate,
      numChannels: 1,
      echoCancel: true,
      noiseSuppress: true,
    ));
    _micSub = stream.listen(onPcm);
  }

  Future<void> stopMic() async {
    await _micSub?.cancel();
    _micSub = null;
    try {
      await _recorder.stop();
    } catch (_) {}
  }

  /// Plays a WAV file and completes when it finishes or is stopped.
  Future<void> playFile(String path) async {
    final done = Completer<void>();
    late final StreamSubscription<void> sub;
    late final StreamSubscription<PlayerState> stateSub;
    sub = _player.onPlayerComplete.listen((_) {
      if (!done.isCompleted) done.complete();
    });
    stateSub = _player.onPlayerStateChanged.listen((s) {
      if (s == PlayerState.stopped && !done.isCompleted) done.complete();
    });
    await _player.play(DeviceFileSource(path));
    await done.future;
    await sub.cancel();
    await stateSub.cancel();
  }

  Future<void> stopPlayback() => _playerInst?.stop() ?? Future.value();

  /// Folder for saved message audio (kept until the conversation is deleted).
  static Future<Directory> audioDir() async {
    final d = Directory('${Directory.systemTemp.path}/band_audio');
    if (!await d.exists()) await d.create(recursive: true);
    return d;
  }

  Future<void> dispose() async {
    await stopMic();
    await _recorderInst?.dispose();
    await _playerInst?.dispose();
  }
}
