import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import '../config.dart';

class OpenAiException implements Exception {
  OpenAiException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Minimal OpenAI client using dart:io only: speech to text, chat and text
/// to speech.
class OpenAiService {
  OpenAiService({String? apiKey}) : _key = apiKey ?? AppConfig.openAiKey;

  final String _key;
  final HttpClient _http = HttpClient()..connectionTimeout = const Duration(seconds: 20);
  static final _base = Uri.parse('https://api.openai.com/v1/');

  bool get configured => _key.trim().isNotEmpty;

  void _check() {
    if (!configured) {
      throw OpenAiException('The OpenAI API key is not set yet. Run the app with --dart-define=OPENAI_API_KEY=...');
    }
  }

  Future<HttpClientResponse> _send(HttpClientRequest req) async {
    final res = await req.close().timeout(const Duration(seconds: 90));
    if (res.statusCode >= 300) {
      final body = await utf8.decodeStream(res);
      var msg = 'OpenAI error ${res.statusCode}';
      try {
        msg = (jsonDecode(body) as Map)['error']['message'] as String? ?? msg;
      } catch (_) {}
      throw OpenAiException(msg);
    }
    return res;
  }

  /// Turns a WAV recording into text. [language] is an ISO code such as "de",
  /// or null to let the model detect it.
  Future<String> transcribe(Uint8List wav, {String? language}) async {
    _check();
    final boundary = '----band${Random().nextInt(1 << 31)}';
    final body = BytesBuilder(copy: false);
    void field(String name, String value) {
      body.add(utf8.encode('--$boundary\r\nContent-Disposition: form-data; name="$name"\r\n\r\n$value\r\n'));
    }

    field('model', AppConfig.transcribeModel);
    field('response_format', 'json');
    if (language != null) field('language', language);
    body.add(utf8.encode('--$boundary\r\nContent-Disposition: form-data; name="file"; filename="speech.wav"\r\n'
        'Content-Type: audio/wav\r\n\r\n'));
    body.add(wav);
    body.add(utf8.encode('\r\n--$boundary--\r\n'));
    final bytes = body.toBytes();

    final req = await _http.postUrl(_base.resolve('audio/transcriptions'));
    req.headers
      ..set(HttpHeaders.authorizationHeader, 'Bearer $_key')
      ..set(HttpHeaders.contentTypeHeader, 'multipart/form-data; boundary=$boundary')
      ..contentLength = bytes.length;
    req.add(bytes);
    final res = await _send(req);
    final json = jsonDecode(await utf8.decodeStream(res)) as Map;
    return (json['text'] as String? ?? '').trim();
  }

  /// Sends the conversation and returns the assistant's reply.
  Future<String> chat(List<Map<String, String>> messages, {int maxTokens = 300}) async {
    _check();
    final req = await _http.postUrl(_base.resolve('chat/completions'));
    req.headers
      ..set(HttpHeaders.authorizationHeader, 'Bearer $_key')
      ..contentType = ContentType.json;
    req.add(utf8.encode(jsonEncode({
      'model': AppConfig.chatModel,
      'messages': messages,
      'max_tokens': maxTokens,
    })));
    final res = await _send(req);
    final json = jsonDecode(await utf8.decodeStream(res)) as Map;
    final choices = json['choices'] as List? ?? const [];
    if (choices.isEmpty) throw OpenAiException('The assistant gave no answer.');
    return ((choices.first as Map)['message']['content'] as String? ?? '').trim();
  }

  /// Text to speech. Returns raw 16 bit mono PCM at 24 kHz.
  Future<Uint8List> speak(String text, {required String voice, double speed = 1.0}) async {
    _check();
    final req = await _http.postUrl(_base.resolve('audio/speech'));
    req.headers
      ..set(HttpHeaders.authorizationHeader, 'Bearer $_key')
      ..contentType = ContentType.json;
    req.add(utf8.encode(jsonEncode({
      'model': AppConfig.speechModel,
      'input': text,
      'voice': voice,
      'speed': speed,
      'response_format': 'pcm',
    })));
    final res = await _send(req);
    final b = BytesBuilder(copy: false);
    await for (final chunk in res) {
      b.add(chunk);
    }
    return b.toBytes();
  }

  /// Downloads a file (used for firmware images).
  Future<Uint8List> download(Uri url) async {
    final req = await _http.getUrl(url);
    final res = await req.close();
    if (res.statusCode >= 300) throw OpenAiException('Download failed (${res.statusCode})');
    final b = BytesBuilder(copy: false);
    await for (final chunk in res) {
      b.add(chunk);
    }
    return b.toBytes();
  }

  Future<Map<String, dynamic>> getJson(Uri url) async {
    final req = await _http.getUrl(url);
    final res = await req.close();
    if (res.statusCode >= 300) throw OpenAiException('Request failed (${res.statusCode})');
    return Map<String, dynamic>.from(jsonDecode(await utf8.decodeStream(res)) as Map);
  }
}
