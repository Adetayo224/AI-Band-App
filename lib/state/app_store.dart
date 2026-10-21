import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';
import '../theme/tokens.dart';

/// Holds everything the app remembers. All of it lives on this phone in
/// shared preferences. There is no account and no login.
class AppStore extends ChangeNotifier {
  AppStore._(this._prefs);

  static const _kProfile = 'profile';
  static const _kSettings = 'settings';
  static const _kConversations = 'conversations';
  static const _kNotices = 'notices';
  static const _kBand = 'band';
  static const _kOnboarded = 'onboarded';

  final SharedPreferences _prefs;

  late UserProfile profile;
  late AppSettings settings;
  final List<Conversation> conversations = [];
  final List<AppNotice> notices = [];
  SavedBand? band;
  bool onboarded = false;

  Timer? _clock;

  static Future<AppStore> load() async {
    final prefs = await SharedPreferences.getInstance();
    final s = AppStore._(prefs);
    s._read();
    s._clock = Timer.periodic(const Duration(minutes: 1), (_) => s._tick());
    return s;
  }

  Map<String, dynamic>? _json(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return null;
    }
  }

  List<dynamic> _list(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return const [];
    try {
      return jsonDecode(raw) as List;
    } catch (_) {
      return const [];
    }
  }

  void _read() {
    profile = UserProfile.fromJson(_json(_kProfile) ?? const {});
    settings = AppSettings.fromJson(_json(_kSettings) ?? const {});
    conversations
      ..clear()
      ..addAll(_list(_kConversations).map((e) => Conversation.fromJson(Map<String, dynamic>.from(e as Map))));
    notices
      ..clear()
      ..addAll(_list(_kNotices).map((e) => AppNotice.fromJson(Map<String, dynamic>.from(e as Map))));
    final b = _json(_kBand);
    band = b == null ? null : SavedBand.fromJson(b);
    onboarded = _prefs.getBool(_kOnboarded) ?? false;
  }

  // ---------------------------------------------------------------- theme

  AppThemeMode? _lastResolved;

  /// The theme to paint right now. When "Night mode after 9 PM" is on, the
  /// night palette is used from 21:00 until 06:00.
  AppThemeMode get effectiveTheme {
    if (settings.autoNight) {
      final h = DateTime.now().hour;
      if (h >= 21 || h < 6) return AppThemeMode.night;
    }
    return settings.theme;
  }

  void _tick() {
    final now = effectiveTheme;
    if (now != _lastResolved) {
      _lastResolved = now;
      notifyListeners();
    }
  }

  // --------------------------------------------------------------- saving

  Future<void> saveProfile() async {
    await _prefs.setString(_kProfile, jsonEncode(profile.toJson()));
    notifyListeners();
  }

  Future<void> saveSettings() async {
    await _prefs.setString(_kSettings, jsonEncode(settings.toJson()));
    _lastResolved = effectiveTheme;
    notifyListeners();
  }

  Future<void> updateSettings(void Function(AppSettings s) change) async {
    change(settings);
    await saveSettings();
  }

  Future<void> _saveConversations() =>
      _prefs.setString(_kConversations, jsonEncode(conversations.map((c) => c.toJson()).toList()));

  Future<void> _saveNotices() => _prefs.setString(_kNotices, jsonEncode(notices.map((n) => n.toJson()).toList()));

  Future<void> setOnboarded(bool value) async {
    onboarded = value;
    await _prefs.setBool(_kOnboarded, value);
    notifyListeners();
  }

  Future<void> setBand(SavedBand? value) async {
    band = value;
    if (value == null) {
      await _prefs.remove(_kBand);
    } else {
      await _prefs.setString(_kBand, jsonEncode(value.toJson()));
    }
    notifyListeners();
  }

  Future<void> renameBand(String name) async {
    if (band == null) return;
    band!.displayName = name.trim().isEmpty ? 'My Band' : name.trim();
    await setBand(band);
  }

  // -------------------------------------------------------- conversations

  String newId() => '${DateTime.now().microsecondsSinceEpoch}${Random().nextInt(999)}';

  Conversation startConversation(MicSource source) {
    final c = Conversation(id: newId(), createdAt: DateTime.now(), source: source);
    conversations.insert(0, c);
    notifyListeners();
    return c;
  }

  Future<void> commitConversation(Conversation c) async {
    if (c.messages.isEmpty) {
      conversations.remove(c);
    } else if (c.title.isEmpty) {
      c.title = _titleFrom(c.messages.first.text);
    }
    if (settings.saveTranscripts) await _saveConversations();
    notifyListeners();
  }

  String _titleFrom(String text) {
    var t = text.trim().replaceAll(RegExp(r'[?.!]+$'), '');
    if (t.length > 40) t = '${t.substring(0, 38).trimRight()}…';
    return t.isEmpty ? 'Conversation' : '${t[0].toUpperCase()}${t.substring(1)}';
  }

  Conversation? conversationById(String id) {
    for (final c in conversations) {
      if (c.id == id) return c;
    }
    return null;
  }

  Future<void> togglePin(Conversation c) async {
    c.pinned = !c.pinned;
    await _saveConversations();
    notifyListeners();
  }

  Future<void> deleteConversation(Conversation c) async {
    conversations.remove(c);
    for (final m in c.messages) {
      _deleteFile(m.audioPath);
    }
    await _saveConversations();
    notifyListeners();
  }

  Future<void> deleteAllConversations() async {
    for (final c in conversations) {
      for (final m in c.messages) {
        _deleteFile(m.audioPath);
      }
    }
    conversations.clear();
    await _saveConversations();
    notifyListeners();
  }

  void _deleteFile(String? path) {
    if (path == null) return;
    try {
      final f = File(path);
      if (f.existsSync()) f.deleteSync();
    } catch (_) {}
  }

  // ------------------------------------------------------------- notices

  Future<void> addNotice(NoticeKind kind, String title, String body) async {
    // Avoid stacking the same notice again and again.
    if (notices.isNotEmpty && notices.first.kind == kind && notices.first.title == title && !notices.first.read) {
      return;
    }
    notices.insert(0, AppNotice(id: newId(), kind: kind, title: title, body: body, at: DateTime.now()));
    if (notices.length > 50) notices.removeRange(50, notices.length);
    await _saveNotices();
    notifyListeners();
  }

  bool get hasUnread => notices.any((n) => !n.read);

  Future<void> markAllRead() async {
    for (final n in notices) {
      n.read = true;
    }
    await _saveNotices();
    notifyListeners();
  }

  // -------------------------------------------------------------- export

  String exportJson() => const JsonEncoder.withIndent('  ').convert({
        'profile': profile.toJson(),
        'settings': settings.toJson(),
        'band': band?.toJson(),
        'conversations': conversations.map((c) => c.toJson()).toList(),
      });

  /// Removes every piece of data the app keeps on this phone.
  Future<void> wipeEverything() async {
    for (final c in conversations) {
      for (final m in c.messages) {
        _deleteFile(m.audioPath);
      }
    }
    await _prefs.clear();
    _read();
    notifyListeners();
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }
}
