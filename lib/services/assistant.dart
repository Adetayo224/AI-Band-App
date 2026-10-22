import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import '../models/models.dart';
import '../state/app_store.dart';
import 'audio_codec.dart';
import 'band_service.dart';
import 'ble_protocol.dart';
import 'openai_service.dart';
import 'phone_audio.dart';

enum TalkPhase { idle, listening, thinking, speaking }

/// Runs one voice exchange end to end:
/// band or phone microphone, then speech to text, then the chat model,
/// then text to speech, then playback on the band speaker or the phone.
class Assistant extends ChangeNotifier {
  Assistant({required this.store, required this.band, required this.ai, required this.audio}) {
    _bandSub = band.events.listen(_onBandEvent);
  }

  final AppStore store;
  final BandService band;
  final OpenAiService ai;
  final PhoneAudio audio;

  TalkPhase phase = TalkPhase.idle;
  MicSource source = MicSource.band;
  bool muted = false;
  String userText = '';
  String replyText = '';
  String? error;
  double level = 0;
  Conversation? conversation;

  /// Called when the band button starts a talk session while the app is on
  /// another screen, so the UI can open the Live talk screen.
  VoidCallback? onBandSession;

  StreamSubscription<BandEvent>? _bandSub;
  StreamSubscription<Uint8List>? _bandMicSub;
  final BytesBuilder _pcm = BytesBuilder(copy: false);
  int _micRate = 16000;
  bool _busy = false;

  /// True when the current question was recorded on the band.
  bool _usingBand = false;

  bool get bandReady => band.connected && !band.isDemo;

  /// Source to use for a new exchange: the band when it is connected and
  /// the user picked it, otherwise the phone.
  MicSource get effectiveSource => (source == MicSource.band && bandReady) ? MicSource.band : MicSource.phone;

  void setSource(MicSource s) {
    if (phase == TalkPhase.listening) return;
    source = s;
    store.updateSettings((x) => x.micSource = s);
    notifyListeners();
  }

  void prepare() {
    source = store.settings.micSource;
    error = null;
    notifyListeners();
  }

  // ------------------------------------------------------------ listening

  Future<void> startListening({bool fromBand = false}) async {
    if (_busy || phase == TalkPhase.listening) return;
    error = null;
    userText = '';
    replyText = '';
    _pcm.clear();
    level = 0;
    conversation ??= store.startConversation(fromBand ? MicSource.band : effectiveSource);
    _usingBand = fromBand || effectiveSource == MicSource.band;
    phase = TalkPhase.listening;
    notifyListeners();
    try {
      if (fromBand || effectiveSource == MicSource.band) {
        _micRate = band.micSampleRate;
        await _bandMicSub?.cancel();
        _bandMicSub = band.micPcm.listen(_onPcm);
        if (!fromBand) await band.startListening();
      } else {
        _micRate = PhoneAudio.micRate;
        await audio.startMic(_onPcm);
      }
    } catch (e) {
      _fail('$e');
    }
  }

  void _onPcm(Uint8List chunk) {
    if (phase != TalkPhase.listening) return;
    if (muted) {
      level = 0;
    } else {
      _pcm.add(chunk);
      level = Pcm.level(chunk);
    }
    notifyListeners();
  }

  /// Ends recording and sends the question to the assistant.
  Future<void> stopListening() async {
    if (phase != TalkPhase.listening) return;
    await _stopMics();
    final pcm = _pcm.takeBytes();
    await _process(pcm, _micRate);
  }

  Future<void> _stopMics() async {
    await _bandMicSub?.cancel();
    _bandMicSub = null;
    if (band.connected) await band.stopListening();
    await audio.stopMic();
  }

  void toggleMute() {
    muted = !muted;
    notifyListeners();
  }

  // ----------------------------------------------------------- processing

  Future<void> _process(Uint8List pcm, int rate) async {
    _busy = true;
    phase = TalkPhase.thinking;
    notifyListeners();
    final convo = conversation ?? store.startConversation(effectiveSource);
    conversation = convo;
    try {
      final ms = Pcm.durationMs(pcm.length, rate);
      if (!ai.configured) {
        await _demoReply(convo, ms);
        return;
      }
      if (ms < 400) {
        _fail('That was too short. Hold on a moment longer and try again.', voice: BandVoice.notHeard);
        return;
      }
      final wav = Pcm.wav(pcm, rate);
      final s = store.settings;
      final text = await ai.transcribe(wav, language: s.autoDetectLanguage ? null : s.language);
      if (text.isEmpty) {
        _fail('I did not catch that. Please try again.', voice: BandVoice.notHeard);
        return;
      }
      userText = text;
      final userMsg = ChatMessage(fromUser: true, text: text, durationMs: ms, audioPath: await _saveWav(wav));
      convo.messages.add(userMsg);
      notifyListeners();

      final reply = await ai.chat(_buildMessages(convo), maxTokens: _maxTokens);
      replyText = reply;
      final voice = AssistantVoice.byId(s.voiceId).openAiVoice;
      final speech = await ai.speak(reply, voice: voice, speed: s.speed);
      const ttsRate = 24000;
      final replyWav = Pcm.wav(speech, ttsRate);
      convo.messages.add(ChatMessage(
        fromUser: false,
        text: reply,
        durationMs: Pcm.durationMs(speech.length, ttsRate),
        audioPath: await _saveWav(replyWav),
      ));
      await store.commitConversation(convo);

      phase = TalkPhase.speaking;
      notifyListeners();
      if (s.vibrateOnReply && band.connected) await band.vibrate(1);
      await _play(speech, ttsRate, replyWav);
    } on OpenAiException catch (e) {
      final voice = switch (e.statusCode) {
        401 || 403 => BandVoice.keyRejected,
        429 || 500 || 502 || 503 => BandVoice.busy,
        _ => BandVoice.error,
      };
      _fail(e.message, voice: voice);
      return;
    } on SocketException {
      _fail('No internet connection. Check your network and try again.', voice: BandVoice.noInternet);
      return;
    } on HandshakeException {
      _fail('No internet connection. Check your network and try again.', voice: BandVoice.noInternet);
      return;
    } catch (e) {
      _fail('$e');
      return;
    } finally {
      _busy = false;
    }
    if (phase == TalkPhase.speaking) {
      phase = TalkPhase.idle;
      notifyListeners();
    }
  }

  /// Without an API key the app still works end to end with a clear notice,
  /// so the screens and the band link can be tested before the key arrives.
  Future<void> _demoReply(Conversation convo, int ms) async {
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    userText = 'Test recording (${(ms / 1000).toStringAsFixed(1)} s)';
    convo.messages.add(ChatMessage(fromUser: true, text: userText, durationMs: ms));
    replyText = 'I heard you. Add the OpenAI API key to get real answers.';
    convo.messages.add(ChatMessage(fromUser: false, text: replyText, durationMs: 2500));
    await store.commitConversation(convo);
    phase = TalkPhase.speaking;
    notifyListeners();
    if (band.connected && _usingBand) await band.say(BandVoice.testMode);
    await Future<void>.delayed(const Duration(milliseconds: 2500));
    _busy = false;
    if (phase == TalkPhase.speaking) {
      phase = TalkPhase.idle;
      notifyListeners();
    }
  }

  int get _maxTokens {
    switch (store.settings.replyLength) {
      case ReplyLength.short:
        return 120;
      case ReplyLength.balanced:
        return 260;
      case ReplyLength.detailed:
        return 600;
    }
  }

  List<Map<String, String>> _buildMessages(Conversation convo) {
    final s = store.settings;
    final p = store.profile;
    final now = DateTime.now();
    final length = switch (s.replyLength) {
      ReplyLength.short => 'Keep every answer to one or two short sentences.',
      ReplyLength.balanced => 'Keep answers to about three or four sentences.',
      ReplyLength.detailed => 'You may give fuller answers, but stay easy to listen to.',
    };
    final lang = s.replyInSameLanguage
        ? 'Reply in the language the user speaks.'
        : 'Always reply in ${AppLanguage.byCode(s.language).name}.';
    final sb = StringBuffer()
      ..writeln('You are a helpful voice assistant that lives in a small wristband. '
          'Your replies are spoken aloud through a tiny speaker, so write plain spoken sentences: '
          'no markdown, no lists, no emojis, no links.')
      ..writeln(length)
      ..writeln(lang)
      ..writeln('Current local date and time: ${now.toIso8601String().substring(0, 16).replaceAll('T', ' ')}.');
    if (p.useInReplies) {
      if (p.callName.isNotEmpty) sb.writeln('The user likes to be called ${p.callName}.');
      if (p.city.isNotEmpty) sb.writeln('The user lives in ${p.city}.');
      if (p.birthday.isNotEmpty) sb.writeln('The user\'s birthday is ${p.birthday}.');
      sb.writeln(p.metric ? 'Use metric units.' : 'Use imperial units.');
    }
    final msgs = <Map<String, String>>[
      {'role': 'system', 'content': sb.toString()},
    ];
    // Last few turns give the model context without growing forever.
    final history = convo.messages.length > 12 ? convo.messages.sublist(convo.messages.length - 12) : convo.messages;
    for (final m in history) {
      msgs.add({'role': m.fromUser ? 'user' : 'assistant', 'content': m.text});
    }
    return msgs;
  }

  Future<void> _play(Uint8List pcm, int rate, Uint8List wav) async {
    final toBand = bandReady && !band.charging && effectiveSource == MicSource.band;
    if (toBand) {
      // The band speaker runs at 16 kHz.
      final samples = Pcm.resample(Pcm.fromBytes(pcm), rate, 16000);
      final done = band.events.firstWhere((e) => e.type == BandEventType.playDone).timeout(
            Duration(milliseconds: Pcm.durationMs(pcm.length, rate) + 4000),
            onTimeout: () => const BandEvent(BandEventType.playDone),
          );
      await band.playOnBand(samples, 16000);
      await done;
    } else {
      final path = conversation?.messages.last.audioPath ?? await _saveWav(wav);
      if (path != null) await audio.playFile(path);
    }
  }

  Future<String?> _saveWav(Uint8List wav) async {
    try {
      final dir = await PhoneAudio.audioDir();
      final f = File('${dir.path}/${store.newId()}.wav');
      await f.writeAsBytes(wav, flush: true);
      return f.path;
    } catch (_) {
      return null;
    }
  }

  /// Shows the error in the app and, when the question came from the band,
  /// makes the band say what went wrong.
  void _fail(String message, {int voice = BandVoice.error}) {
    error = message;
    phase = TalkPhase.idle;
    _busy = false;
    notifyListeners();
    if (_usingBand && band.connected) band.say(voice);
  }

  // ------------------------------------------------------------- control

  /// The big circle on Live talk: start, stop, or skip the reply.
  Future<void> orbTapped() async {
    switch (phase) {
      case TalkPhase.idle:
        await startListening();
      case TalkPhase.listening:
        await stopListening();
      case TalkPhase.thinking:
        break;
      case TalkPhase.speaking:
        await stopSpeaking();
    }
  }

  Future<void> stopSpeaking() async {
    await band.abortPlayback();
    await audio.stopPlayback();
    phase = TalkPhase.idle;
    notifyListeners();
  }

  /// Leaves the Live talk screen.
  Future<void> end() async {
    if (phase == TalkPhase.listening) await _stopMics();
    if (phase == TalkPhase.speaking) await stopSpeaking();
    if (conversation != null) await store.commitConversation(conversation!);
    conversation = null;
    phase = TalkPhase.idle;
    muted = false;
    userText = '';
    replyText = '';
    error = null;
    notifyListeners();
  }

  /// Continues an earlier conversation from its detail page.
  void resume(Conversation c) {
    conversation = c;
    notifyListeners();
  }

  void _onBandEvent(BandEvent e) {
    final hold = store.settings.buttonMode == ButtonMode.hold;
    switch (e.type) {
      case BandEventType.buttonDown:
      case BandEventType.listenStarted:
        if (phase == TalkPhase.idle) {
          source = MicSource.band;
          onBandSession?.call();
          startListening(fromBand: true);
        } else if (phase == TalkPhase.listening && !hold && e.type == BandEventType.buttonDown) {
          stopListening();
        } else if (phase == TalkPhase.speaking) {
          stopSpeaking();
        }
      case BandEventType.buttonUp:
      case BandEventType.listenEnded:
        if (phase == TalkPhase.listening && (hold || e.type == BandEventType.listenEnded)) stopListening();
      case BandEventType.playDone:
      case BandEventType.otaResult:
        break;
    }
  }

  @override
  void dispose() {
    _bandSub?.cancel();
    _bandMicSub?.cancel();
    super.dispose();
  }
}
