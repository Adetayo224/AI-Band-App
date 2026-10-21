# Band Bluetooth protocol (firmware side)

This is the contract between the ESP32 S3 firmware and the app. The app side
is `lib/services/ble_protocol.dart` and `lib/services/band_service.dart`.

## Advertising

* Name starts with `AI Band`, followed by the last four hex digits of the MAC,
  for example `AI Band 4F2A`.
* Advertise the service UUID `4ab10001-1e2d-4c5b-9a00-7f2a3b0c5e01` (in the
  scan response if it does not fit).
* Request MTU 247 and 2M PHY where supported. The app asks for MTU 247.

## GATT

| Characteristic | UUID | Properties | Direction |
| --- | --- | --- | --- |
| Service | `4ab10001-1e2d-4c5b-9a00-7f2a3b0c5e01` | | |
| control | `4ab10002-1e2d-4c5b-9a00-7f2a3b0c5e01` | write | app to band |
| events | `4ab10003-1e2d-4c5b-9a00-7f2a3b0c5e01` | notify | band to app |
| audioUp | `4ab10004-1e2d-4c5b-9a00-7f2a3b0c5e01` | notify | band mic to app |
| audioDown | `4ab10005-1e2d-4c5b-9a00-7f2a3b0c5e01` | write without response | app to band speaker |
| ota | `4ab10006-1e2d-4c5b-9a00-7f2a3b0c5e01` | write | firmware image |
| Battery Level | `0x180F` / `0x2A19` | read, notify | standard |
| Firmware Revision | `0x180A` / `0x2A26` | read | standard, for example "1.0.3" |

All multi byte numbers are little endian.

## Commands (write to control, first byte is the opcode)

| Opcode | Name | Payload |
| --- | --- | --- |
| 0x01 | START_LISTEN | none. Open the mic and stream audioUp |
| 0x02 | STOP_LISTEN | none |
| 0x03 | PLAY_START | codec u8, sampleRate u16, totalBytes u32 |
| 0x04 | PLAY_END | none. All audio has been sent |
| 0x05 | PLAY_ABORT | none. Stop playback now |
| 0x10 | SET_VOLUME | 0 to 100 |
| 0x11 | SET_VIBRATION | 0 off, 1 light, 2 medium, 3 strong |
| 0x12 | SET_BUTTON_MODE | 0 tap to talk, 1 hold to talk |
| 0x13 | VIBRATE | pattern: 1 short, 2 double, 3 long |
| 0x14 | FIND | 1 ring tone and vibrate, 0 stop |
| 0x15 | SET_NAME | UTF 8 bytes, up to 20 |
| 0x16 | RESTART | none |
| 0x17 | FACTORY_RESET | none |
| 0x18 | GET_STATUS | none. Band answers with STATUS |
| 0x20 | OTA_BEGIN | imageSize u32 |
| 0x21 | OTA_END | none. Verify, switch partition, reboot |
| 0x22 | OTA_ABORT | none |
| 0x23 | FIND_VIBRATE | 1 vibrate only, 0 stop |

## Events (notify on events, first byte is the opcode)

| Opcode | Name | Payload |
| --- | --- | --- |
| 0x81 | BUTTON_DOWN | none |
| 0x82 | BUTTON_UP | none |
| 0x83 | LISTEN_STARTED | codec u8, sampleRate u16 |
| 0x84 | LISTEN_ENDED | none |
| 0x85 | PLAY_DONE | none. Speaker finished |
| 0x86 | STATUS | battery, charging, fwMajor, fwMinor, fwPatch, volume, vibration, buttonMode (8 bytes after opcode) |
| 0x87 | OTA_PROGRESS | percent |
| 0x88 | OTA_RESULT | 1 ok, 0 failed |
| 0x89 | CHARGING | 1 on the magnetic charger, 0 off |
| 0x8A | BUFFER_LEVEL | free playback buffer bytes u16 (optional) |

## Audio

* Codec 1 is IMA ADPCM: 4 bits per sample, low nibble first, mono, 16 kHz,
  predictor and step index start at 0 for every stream. Codec 0 is raw 16 bit
  PCM. The app uses codec 1 in both directions (64 kbit/s).
* Button flow in tap mode: press, the band sends BUTTON_DOWN and
  LISTEN_STARTED, then streams audioUp. Press again, the band stops and sends
  LISTEN_ENDED. In hold mode, releasing the button ends it (BUTTON_UP).
* Playback: the app sends PLAY_START, then audioDown chunks of MTU minus 3
  bytes, kept about 0.6 s ahead of real time, then PLAY_END. Keep a playback
  buffer of at least 8 KB (about 1 s). Send PLAY_DONE when the last sample
  has been played.
* Send CHARGING whenever the charger state changes. The app plays replies on
  the phone while the band charges.

## OTA

OTA_BEGIN with the image size, then the image in ota writes (with response),
then OTA_END. Report OTA_PROGRESS now and then, and OTA_RESULT after
verifying. Use the ESP-IDF `esp_ota_*` API with two app partitions.
