import '../theme/tokens.dart';

/// Personal details. Stored on this phone only, never in an account.
class UserProfile {
  UserProfile({
    this.name = '',
    this.nickname = '',
    this.birthday = '',
    this.city = '',
    this.metric = true,
    this.useInReplies = true,
  });

  String name;
  String nickname;
  String birthday;
  String city;
  bool metric;
  bool useInReplies;

  /// What the assistant should call the user.
  String get callName => nickname.trim().isNotEmpty ? nickname.trim() : name.trim();

  String get initials {
    final n = callName;
    return n.isEmpty ? '' : n.characters.first.toUpperCase();
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'nickname': nickname,
        'birthday': birthday,
        'city': city,
        'metric': metric,
        'useInReplies': useInReplies,
      };

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
        name: j['name'] as String? ?? '',
        nickname: j['nickname'] as String? ?? '',
        birthday: j['birthday'] as String? ?? '',
        city: j['city'] as String? ?? '',
        metric: j['metric'] as bool? ?? true,
        useInReplies: j['useInReplies'] as bool? ?? true,
      );
}

extension on String {
  Iterable<String> get characters => runes.map(String.fromCharCode);
}

enum ReplyLength { short, balanced, detailed }

enum ButtonMode { tap, hold }

enum VibrationStrength { off, light, medium, strong }

enum MicSource { band, phone }

/// One of the assistant voices shown on the Voice screen. [openAiVoice] is
/// the matching voice id sent to the text to speech API.
class AssistantVoice {
  const AssistantVoice(this.id, this.name, this.description, this.openAiVoice);
  final String id;
  final String name;
  final String description;
  final String openAiVoice;

  static const all = [
    AssistantVoice('nova', 'Nova', 'Warm and clear', 'nova'),
    AssistantVoice('atlas', 'Atlas', 'Deep and calm', 'onyx'),
    AssistantVoice('ember', 'Ember', 'Bright and friendly', 'coral'),
    AssistantVoice('sol', 'Sol', 'Soft and slow', 'sage'),
  ];

  static AssistantVoice byId(String id) => all.firstWhere((v) => v.id == id, orElse: () => all.first);
}

/// Languages shown on the Language screen (European set for the client).
class AppLanguage {
  const AppLanguage(this.code, this.name, this.native);
  final String code;
  final String name;
  final String native;

  static const all = [
    AppLanguage('en', 'English', 'English'),
    AppLanguage('de', 'German', 'Deutsch'),
    AppLanguage('nl', 'Dutch', 'Nederlands'),
    AppLanguage('es', 'Spanish', 'Español'),
    AppLanguage('fr', 'French', 'Français'),
    AppLanguage('it', 'Italian', 'Italiano'),
    AppLanguage('pt', 'Portuguese', 'Português'),
    AppLanguage('pl', 'Polish', 'Polski'),
  ];

  static AppLanguage byCode(String code) => all.firstWhere((l) => l.code == code, orElse: () => all.first);
}

const speedSteps = [0.75, 0.9, 1.0, 1.25, 1.5];
const speedLabels = ['0.75x', '0.9x', '1.0x', '1.25x', '1.5x'];

/// Every app setting. Saved on the phone.
class AppSettings {
  AppSettings({
    this.theme = AppThemeMode.dark,
    this.autoNight = true,
    this.vibrateOnReply = true,
    this.saveTranscripts = true,
    this.voiceId = 'nova',
    this.speedIndex = 2,
    this.replyLength = ReplyLength.short,
    this.language = 'en',
    this.autoDetectLanguage = true,
    this.replyInSameLanguage = true,
    this.volume = 70,
    this.vibration = VibrationStrength.medium,
    this.buttonMode = ButtonMode.tap,
    this.micSource = MicSource.band,
    this.captions = true,
    this.notificationsEnabled = false,
    this.demoMode = false,
  });

  AppThemeMode theme;
  bool autoNight;
  bool vibrateOnReply;
  bool saveTranscripts;
  String voiceId;
  int speedIndex;
  ReplyLength replyLength;
  String language;
  bool autoDetectLanguage;
  bool replyInSameLanguage;
  int volume;
  VibrationStrength vibration;
  ButtonMode buttonMode;
  MicSource micSource;
  bool captions;
  bool notificationsEnabled;
  bool demoMode;

  double get speed => speedSteps[speedIndex.clamp(0, speedSteps.length - 1)];

  Map<String, dynamic> toJson() => {
        'theme': theme.name,
        'autoNight': autoNight,
        'vibrateOnReply': vibrateOnReply,
        'saveTranscripts': saveTranscripts,
        'voiceId': voiceId,
        'speedIndex': speedIndex,
        'replyLength': replyLength.name,
        'language': language,
        'autoDetectLanguage': autoDetectLanguage,
        'replyInSameLanguage': replyInSameLanguage,
        'volume': volume,
        'vibration': vibration.name,
        'buttonMode': buttonMode.name,
        'micSource': micSource.name,
        'captions': captions,
        'notificationsEnabled': notificationsEnabled,
        'demoMode': demoMode,
      };

  factory AppSettings.fromJson(Map<String, dynamic> j) {
    T pick<T extends Enum>(List<T> values, Object? name, T fallback) =>
        values.firstWhere((v) => v.name == name, orElse: () => fallback);
    return AppSettings(
      theme: pick(AppThemeMode.values, j['theme'], AppThemeMode.dark),
      autoNight: j['autoNight'] as bool? ?? true,
      vibrateOnReply: j['vibrateOnReply'] as bool? ?? true,
      saveTranscripts: j['saveTranscripts'] as bool? ?? true,
      voiceId: j['voiceId'] as String? ?? 'nova',
      speedIndex: j['speedIndex'] as int? ?? 2,
      replyLength: pick(ReplyLength.values, j['replyLength'], ReplyLength.short),
      language: j['language'] as String? ?? 'en',
      autoDetectLanguage: j['autoDetectLanguage'] as bool? ?? true,
      replyInSameLanguage: j['replyInSameLanguage'] as bool? ?? true,
      volume: j['volume'] as int? ?? 70,
      vibration: pick(VibrationStrength.values, j['vibration'], VibrationStrength.medium),
      buttonMode: pick(ButtonMode.values, j['buttonMode'], ButtonMode.tap),
      micSource: pick(MicSource.values, j['micSource'], MicSource.band),
      captions: j['captions'] as bool? ?? true,
      notificationsEnabled: j['notificationsEnabled'] as bool? ?? false,
      demoMode: j['demoMode'] as bool? ?? false,
    );
  }
}

/// A single line in a conversation.
class ChatMessage {
  ChatMessage({required this.fromUser, required this.text, this.durationMs = 0, this.audioPath});

  final bool fromUser;
  String text;
  int durationMs;
  String? audioPath;

  Map<String, dynamic> toJson() => {
        'u': fromUser,
        't': text,
        'd': durationMs,
        if (audioPath != null) 'a': audioPath,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
        fromUser: j['u'] as bool? ?? false,
        text: j['t'] as String? ?? '',
        durationMs: j['d'] as int? ?? 0,
        audioPath: j['a'] as String?,
      );
}

/// A saved conversation with the assistant.
class Conversation {
  Conversation({
    required this.id,
    required this.createdAt,
    required this.source,
    this.title = '',
    this.pinned = false,
    List<ChatMessage>? messages,
  }) : messages = messages ?? [];

  final String id;
  final DateTime createdAt;
  final MicSource source;
  String title;
  bool pinned;
  final List<ChatMessage> messages;

  int get totalMs => messages.fold(0, (a, m) => a + m.durationMs);

  String get preview {
    for (final m in messages.reversed) {
      if (!m.fromUser && m.text.isNotEmpty) return m.text;
    }
    return messages.isEmpty ? '' : messages.last.text;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'at': createdAt.millisecondsSinceEpoch,
        'src': source.name,
        'title': title,
        'pin': pinned,
        'm': messages.map((m) => m.toJson()).toList(),
      };

  factory Conversation.fromJson(Map<String, dynamic> j) => Conversation(
        id: j['id'] as String,
        createdAt: DateTime.fromMillisecondsSinceEpoch(j['at'] as int? ?? 0),
        source: j['src'] == 'phone' ? MicSource.phone : MicSource.band,
        title: j['title'] as String? ?? '',
        pinned: j['pin'] as bool? ?? false,
        messages: ((j['m'] as List?) ?? const [])
            .map((e) => ChatMessage.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
}

enum NoticeKind { reminder, firmware, battery, disconnected, paired }

/// An entry on the Notifications screen.
class AppNotice {
  AppNotice({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.at,
    this.read = false,
  });

  final String id;
  final NoticeKind kind;
  final String title;
  final String body;
  final DateTime at;
  bool read;

  Map<String, dynamic> toJson() =>
      {'id': id, 'k': kind.name, 't': title, 'b': body, 'at': at.millisecondsSinceEpoch, 'r': read};

  factory AppNotice.fromJson(Map<String, dynamic> j) => AppNotice(
        id: j['id'] as String,
        kind: NoticeKind.values.firstWhere((k) => k.name == j['k'], orElse: () => NoticeKind.paired),
        title: j['t'] as String? ?? '',
        body: j['b'] as String? ?? '',
        at: DateTime.fromMillisecondsSinceEpoch(j['at'] as int? ?? 0),
        read: j['r'] as bool? ?? false,
      );
}

/// The paired band remembered on this phone.
class SavedBand {
  SavedBand({required this.id, required this.advertisedName, this.displayName = 'My Band', this.demo = false});

  final String id;
  final String advertisedName;
  String displayName;
  final bool demo;

  /// Short code shown after "AI Band", for example 4F2A.
  String get shortCode {
    final m = RegExp(r'([0-9A-Fa-f]{4})$').firstMatch(advertisedName.replaceAll(' ', ''));
    if (m != null) return m.group(1)!.toUpperCase();
    final clean = id.replaceAll(RegExp(r'[^0-9A-Fa-f]'), '');
    return clean.length >= 4 ? clean.substring(clean.length - 4).toUpperCase() : 'BAND';
  }

  Map<String, dynamic> toJson() => {'id': id, 'adv': advertisedName, 'name': displayName, 'demo': demo};

  factory SavedBand.fromJson(Map<String, dynamic> j) => SavedBand(
        id: j['id'] as String,
        advertisedName: j['adv'] as String? ?? 'AI Band',
        displayName: j['name'] as String? ?? 'My Band',
        demo: j['demo'] as bool? ?? false,
      );
}
