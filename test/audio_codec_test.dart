import 'dart:math';
import 'dart:typed_data';

import 'package:esp32_wristband_app/services/audio_codec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Int16List tone(int n) {
    final pcm = Int16List(n);
    for (var i = 0; i < n; i++) {
      pcm[i] = (sin(2 * pi * 440 * i / 16000) * 12000).round();
    }
    return pcm;
  }

  test('IMA ADPCM packs two samples per byte and decodes close to the input', () {
    final pcm = tone(16000);
    final enc = ImaAdpcm().encode(pcm);
    expect(enc.length, 8000);
    final dec = ImaAdpcm().decode(enc);
    var err = 0;
    for (var i = 0; i < pcm.length; i++) {
      err += (pcm[i] - dec[i]).abs();
    }
    expect(err / pcm.length, lessThan(400));
  });

  test('WAV header is valid', () {
    final bytes = Pcm.toBytes(tone(1600));
    final wav = Pcm.wav(bytes, 16000);
    expect(String.fromCharCodes(wav.sublist(0, 4)), 'RIFF');
    expect(String.fromCharCodes(wav.sublist(8, 12)), 'WAVE');
    expect(wav.length, bytes.length + 44);
  });

  test('resample keeps duration', () {
    expect(Pcm.resample(tone(24000), 24000, 16000).length, 16000);
    expect(Pcm.durationMs(32000, 16000), 1000);
  });
}
