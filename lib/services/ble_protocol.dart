/// The Bluetooth Low Energy protocol between the app and the ESP32 S3 band.
///
/// The firmware must expose exactly these UUIDs and opcodes. The same table
/// is written out for the firmware side in docs/BLE_PROTOCOL.md.
class BandUuids {
  /// Custom wristband service. The band advertises this UUID and a name that
  /// starts with "AI Band".
  static const service = '4ab10001-1e2d-4c5b-9a00-7f2a3b0c5e01';

  /// App to band commands (write with response).
  static const control = '4ab10002-1e2d-4c5b-9a00-7f2a3b0c5e01';

  /// Band to app events (notify).
  static const events = '4ab10003-1e2d-4c5b-9a00-7f2a3b0c5e01';

  /// Microphone audio from the band (notify).
  static const audioUp = '4ab10004-1e2d-4c5b-9a00-7f2a3b0c5e01';

  /// Reply audio to the band speaker (write without response).
  static const audioDown = '4ab10005-1e2d-4c5b-9a00-7f2a3b0c5e01';

  /// Firmware image chunks (write without response).
  static const ota = '4ab10006-1e2d-4c5b-9a00-7f2a3b0c5e01';

  /// Standard Battery Service and Battery Level characteristic.
  static const batteryService = '0000180f-0000-1000-8000-00805f9b34fb';
  static const batteryLevel = '00002a19-0000-1000-8000-00805f9b34fb';

  /// Standard Device Information Service, Firmware Revision String.
  static const deviceInfoService = '0000180a-0000-1000-8000-00805f9b34fb';
  static const firmwareRevision = '00002a26-0000-1000-8000-00805f9b34fb';

  static const namePrefix = 'AI Band';
}

/// First byte of every write to [BandUuids.control].
class Cmd {
  static const startListen = 0x01; // band opens its mic and streams audioUp
  static const stopListen = 0x02; // band stops the mic
  static const playStart = 0x03; // [codec u8][sampleRate u16 LE][totalBytes u32 LE]
  static const playEnd = 0x04; // no more audio will follow
  static const playAbort = 0x05; // stop playback now
  static const setVolume = 0x10; // [0..100]
  static const setVibration = 0x11; // [0 off, 1 light, 2 medium, 3 strong]
  static const setButtonMode = 0x12; // [0 tap to talk, 1 hold to talk]
  static const vibrate = 0x13; // [pattern: 1 short, 2 double, 3 long]
  static const find = 0x14; // [1 ring and vibrate, 0 stop]
  static const setName = 0x15; // [utf8 bytes, max 20]
  static const restart = 0x16;
  static const factoryReset = 0x17;
  static const getStatus = 0x18; // band answers with Evt.status
  static const otaBegin = 0x20; // [imageSize u32 LE]
  static const otaEnd = 0x21; // all chunks sent, band verifies and reboots
  static const otaAbort = 0x22;
  static const findVibrateOnly = 0x23; // [1 on, 0 off] vibrate without sound
}

/// First byte of every notification on [BandUuids.events].
class Evt {
  static const buttonDown = 0x81;
  static const buttonUp = 0x82;
  static const listenStarted = 0x83; // [codec u8][sampleRate u16 LE]
  static const listenEnded = 0x84;
  static const playDone = 0x85;
  static const status = 0x86; // [battery][charging][fwMajor][fwMinor][fwPatch][volume][vibration][buttonMode]
  static const otaProgress = 0x87; // [percent]
  static const otaResult = 0x88; // [1 ok, 0 failed]
  static const charging = 0x89; // [1 on charger, 0 off]
  static const bufferLevel = 0x8A; // [free bytes u16 LE] playback flow control
}

/// Audio codecs used on the audio characteristics.
class Codec {
  static const pcm16 = 0; // signed 16 bit little endian, mono
  static const imaAdpcm = 1; // IMA ADPCM, 4 bits per sample, low nibble first
}
