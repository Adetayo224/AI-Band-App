import 'package:esp32_wristband_app/models/models.dart';
import 'package:esp32_wristband_app/theme/tokens.dart';
import 'package:esp32_wristband_app/ui/format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('settings survive a JSON round trip', () {
    final s = AppSettings(theme: AppThemeMode.night, voiceId: 'atlas', language: 'de', autoDetectLanguage: false);
    final back = AppSettings.fromJson(s.toJson());
    expect(back.theme, AppThemeMode.night);
    expect(back.voiceId, 'atlas');
    expect(back.language, 'de');
    expect(back.autoDetectLanguage, isFalse);
  });

  test('profile call name prefers the nickname', () {
    final p = UserProfile(name: 'Lena', nickname: 'Leni');
    expect(p.callName, 'Leni');
    expect(UserProfile.fromJson(p.toJson()).name, 'Lena');
  });

  test('conversation keeps its messages', () {
    final c = Conversation(id: '1', createdAt: DateTime(2026, 10, 20, 20, 42), source: MicSource.band)
      ..messages.add(ChatMessage(fromUser: true, text: 'Hallo', durationMs: 1200))
      ..messages.add(ChatMessage(fromUser: false, text: 'Hallo Lena', durationMs: 800));
    final back = Conversation.fromJson(c.toJson());
    expect(back.messages.length, 2);
    expect(back.preview, 'Hallo Lena');
    expect(back.totalMs, 2000);
  });

  test('band short code comes from the advertised name', () {
    expect(SavedBand(id: 'aa:bb', advertisedName: 'AI Band 4F2A').shortCode, '4F2A');
  });

  test('formatting', () {
    expect(Fmt.duration(48000), '0:48');
    expect(Fmt.time(DateTime(2026, 1, 1, 9, 5)), '09:05');
    expect(Fmt.longDate(DateTime(2026, 10, 19)), 'Monday, 19 October');
  });

  test('languages are the European set', () {
    expect(AppLanguage.all.map((l) => l.code), containsAll(['en', 'de', 'nl', 'es']));
  });
}
