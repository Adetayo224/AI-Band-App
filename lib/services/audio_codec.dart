import 'dart:typed_data';

/// IMA ADPCM encoder and decoder. Four bits per sample cuts the Bluetooth
/// audio load by four, which keeps voice smooth on every phone.
class ImaAdpcm {
  static const _indexTable = [-1, -1, -1, -1, 2, 4, 6, 8, -1, -1, -1, -1, 2, 4, 6, 8];
  static const _stepTable = [
    7, 8, 9, 10, 11, 12, 13, 14, 16, 17, 19, 21, 23, 25, 28, 31, 34, 37, 41, 45, 50, 55, 60, 66, 73, 80, 88, 97, //
    107, 118, 130, 143, 157, 173, 190, 209, 230, 253, 279, 307, 337, 371, 408, 449, 494, 544, 598, 658, 724, 796,
    876, 963, 1060, 1166, 1282, 1411, 1552, 1707, 1878, 2066, 2272, 2499, 2749, 3024, 3327, 3660, 4026, 4428, 4871,
    5358, 5894, 6484, 7132, 7845, 8630, 9493, 10442, 11487, 12635, 13899, 15289, 16818, 18500, 20350, 22385, 24623,
    27086, 29794, 32767,
  ];

  int _pred = 0;
  int _index = 0;

  void reset() {
    _pred = 0;
    _index = 0;
  }

  int _decodeNibble(int nibble) {
    final step = _stepTable[_index];
    var diff = step >> 3;
    if (nibble & 4 != 0) diff += step;
    if (nibble & 2 != 0) diff += step >> 1;
    if (nibble & 1 != 0) diff += step >> 2;
    if (nibble & 8 != 0) {
      _pred -= diff;
    } else {
      _pred += diff;
    }
    _pred = _pred.clamp(-32768, 32767);
    _index = (_index + _indexTable[nibble]).clamp(0, 88);
    return _pred;
  }

  /// Decodes ADPCM bytes into 16 bit PCM samples (two samples per byte).
  Int16List decode(Uint8List data) {
    final out = Int16List(data.length * 2);
    var o = 0;
    for (final b in data) {
      out[o++] = _decodeNibble(b & 0x0F);
      out[o++] = _decodeNibble((b >> 4) & 0x0F);
    }
    return out;
  }

  int _encodeSample(int sample) {
    final step = _stepTable[_index];
    var diff = sample - _pred;
    var nibble = 0;
    if (diff < 0) {
      nibble = 8;
      diff = -diff;
    }
    var vpdiff = step >> 3;
    if (diff >= step) {
      nibble |= 4;
      diff -= step;
      vpdiff += step;
    }
    if (diff >= step >> 1) {
      nibble |= 2;
      diff -= step >> 1;
      vpdiff += step >> 1;
    }
    if (diff >= step >> 2) {
      nibble |= 1;
      vpdiff += step >> 2;
    }
    if (nibble & 8 != 0) {
      _pred -= vpdiff;
    } else {
      _pred += vpdiff;
    }
    _pred = _pred.clamp(-32768, 32767);
    _index = (_index + _indexTable[nibble]).clamp(0, 88);
    return nibble;
  }

  /// Encodes 16 bit PCM samples into ADPCM bytes.
  Uint8List encode(Int16List pcm) {
    final out = Uint8List((pcm.length + 1) ~/ 2);
    for (var i = 0; i < pcm.length; i += 2) {
      final lo = _encodeSample(pcm[i]);
      final hi = i + 1 < pcm.length ? _encodeSample(pcm[i + 1]) : 0;
      out[i ~/ 2] = lo | (hi << 4);
    }
    return out;
  }
}

/// Helpers for raw PCM audio.
class Pcm {
  /// Reads little endian 16 bit samples from bytes.
  static Int16List fromBytes(Uint8List bytes) {
    final n = bytes.length ~/ 2;
    final out = Int16List(n);
    final bd = ByteData.sublistView(bytes);
    for (var i = 0; i < n; i++) {
      out[i] = bd.getInt16(i * 2, Endian.little);
    }
    return out;
  }

  static Uint8List toBytes(Int16List samples) {
    final out = Uint8List(samples.length * 2);
    final bd = ByteData.sublistView(out);
    for (var i = 0; i < samples.length; i++) {
      bd.setInt16(i * 2, samples[i], Endian.little);
    }
    return out;
  }

  /// Linear resampler, good enough for speech.
  static Int16List resample(Int16List input, int fromRate, int toRate) {
    if (fromRate == toRate || input.isEmpty) return input;
    final outLen = (input.length * toRate / fromRate).floor();
    final out = Int16List(outLen);
    final ratio = fromRate / toRate;
    for (var i = 0; i < outLen; i++) {
      final pos = i * ratio;
      final i0 = pos.floor();
      final i1 = (i0 + 1).clamp(0, input.length - 1);
      final frac = pos - i0;
      out[i] = (input[i0.clamp(0, input.length - 1)] * (1 - frac) + input[i1] * frac).round().clamp(-32768, 32767);
    }
    return out;
  }

  /// Scales samples by a volume between 0 and 1.
  static Int16List gain(Int16List input, double g) {
    if (g >= 0.999) return input;
    final out = Int16List(input.length);
    for (var i = 0; i < input.length; i++) {
      out[i] = (input[i] * g).round();
    }
    return out;
  }

  /// Wraps 16 bit mono PCM in a WAV header (what the transcription API and
  /// the phone player expect).
  static Uint8List wav(Uint8List pcmBytes, int sampleRate) {
    final header = ByteData(44);
    void ascii(int offset, String s) {
      for (var i = 0; i < s.length; i++) {
        header.setUint8(offset + i, s.codeUnitAt(i));
      }
    }

    ascii(0, 'RIFF');
    header.setUint32(4, 36 + pcmBytes.length, Endian.little);
    ascii(8, 'WAVE');
    ascii(12, 'fmt ');
    header.setUint32(16, 16, Endian.little);
    header.setUint16(20, 1, Endian.little); // PCM
    header.setUint16(22, 1, Endian.little); // mono
    header.setUint32(24, sampleRate, Endian.little);
    header.setUint32(28, sampleRate * 2, Endian.little);
    header.setUint16(32, 2, Endian.little);
    header.setUint16(34, 16, Endian.little);
    ascii(36, 'data');
    header.setUint32(40, pcmBytes.length, Endian.little);
    final out = BytesBuilder(copy: false)
      ..add(header.buffer.asUint8List())
      ..add(pcmBytes);
    return out.toBytes();
  }

  /// Rough loudness (0..1) of a chunk, used for the live waveform.
  static double level(Uint8List pcmBytes) {
    if (pcmBytes.length < 2) return 0;
    final s = fromBytes(pcmBytes);
    var peak = 0;
    for (final v in s) {
      final a = v.abs();
      if (a > peak) peak = a;
    }
    return (peak / 32768).clamp(0, 1);
  }

  static int durationMs(int pcmByteCount, int sampleRate) => (pcmByteCount / 2 / sampleRate * 1000).round();
}
