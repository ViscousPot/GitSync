import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:GitSync/api/ai_provider_validator.dart';
import 'package:GitSync/api/ai_tools.dart';
import 'package:GitSync/type/ai_chat.dart';
import 'package:http/http.dart' as http;

sealed class StreamEvent {}

class TextDelta extends StreamEvent {
  final String text;
  TextDelta(this.text);
}

class ToolCallStart extends StreamEvent {
  final String id;
  final String name;
  ToolCallStart(this.id, this.name);
}

class ToolCallInputDelta extends StreamEvent {
  final String id;
  final String jsonFragment;
  ToolCallInputDelta(this.id, this.jsonFragment);
}

class ToolCallEnd extends StreamEvent {
  final String id;
  ToolCallEnd(this.id);
}

class UsageUpdate extends StreamEvent {
  final TokenUsage usage;
  UsageUpdate(this.usage);
}

class StreamComplete extends StreamEvent {
  final String? stopReason;
  StreamComplete(this.stopReason);
}

class StreamError extends StreamEvent {
  final String message;
  StreamError(this.message);
}

Stream<StreamEvent> streamCompletion({
  required AiProvider provider,
  required String systemPrompt,
  required List<Map<String, dynamic>> messages,
  required List<AiTool> tools,
  required String apiKey,
  required String model,
  String? endpoint,
  bool Function()? isCancelled,
}) async* {
  final Uri url;
  final Map<String, String> headers;
  final Map<String, dynamic> body;

  switch (provider) {
    case AiProvider.anthropic:
      url = Uri.parse('https://api.anthropic.com/v1/messages');
      headers = {'x-api-key': apiKey, 'anthropic-version': '2023-06-01', 'Content-Type': 'application/json'};
      body = {
        'model': model,
        'max_tokens': 4096,
        'system': systemPrompt,
        'messages': messages,
        'stream': true,
        if (tools.isNotEmpty) 'tools': tools.map((t) => t.toAnthropic()).toList(),
      };

    case AiProvider.openai:
      url = Uri.parse('https://api.openai.com/v1/chat/completions');
      headers = {'Authorization': 'Bearer $apiKey', 'Content-Type': 'application/json'};
      body = {
        'model': model,
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          ...messages,
        ],
        'stream': true,
        'stream_options': {'include_usage': true},
        if (tools.isNotEmpty) 'tools': tools.map((t) => t.toOpenAI()).toList(),
      };

    case AiProvider.google:
      url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$model:streamGenerateContent?alt=sse&key=$apiKey');
      headers = {'Content-Type': 'application/json'};
      body = {
        'system_instruction': {
          'parts': [
            {'text': systemPrompt},
          ],
        },
        'contents': messages.map((m) => _toGoogleMessage(m)).toList(),
        if (tools.isNotEmpty)
          'tools': [
            {'functionDeclarations': tools.map((t) => t.toGoogle()).toList()},
          ],
      };

    case AiProvider.selfHosted:
      final base = normalizeEndpoint(endpoint ?? '');
      url = Uri.parse('$base/chat/completions');
      headers = {'Authorization': 'Bearer $apiKey', 'Content-Type': 'application/json'};
      body = {
        'model': model,
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          ...messages,
        ],
        'stream': true,
        'stream_options': {'include_usage': true},
        if (tools.isNotEmpty) 'tools': tools.map((t) => t.toOpenAI()).toList(),
      };
  }

  final request = http.Request('POST', url);
  request.headers.addAll(headers);
  request.body = jsonEncode(body);

  final client = http.Client();
  try {
    final response = await client.send(request).timeout(const Duration(seconds: 120));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final errorBody = await response.stream.bytesToString();
      // Surface the full upstream body in logcat so we can debug 4xx/5xx
      // without having to chase the banner UI on-device.
      print('[AI Stream] $provider HTTP ${response.statusCode} body=$errorBody');
      yield StreamError('API error ${response.statusCode}: $errorBody');
      return;
    }

    final anthropicBlockIds = <int, String>{};

    final lineBuffer = StringBuffer();
    await for (final chunk in response.stream.transform(utf8.decoder)) {
      if (isCancelled?.call() == true) {
        client.close();
        return;
      }
      lineBuffer.write(chunk);
      final raw = lineBuffer.toString();
      final lines = raw.split('\n');

      lineBuffer.clear();
      lineBuffer.write(lines.removeLast());

      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) continue;
        if (trimmed == 'data: [DONE]') {
          yield StreamComplete(null);
          continue;
        }
        if (!trimmed.startsWith('data: ')) continue;
        final jsonStr = trimmed.substring(6);
        try {
          final json = jsonDecode(jsonStr) as Map<String, dynamic>;
          final events = _parse(provider, json, anthropicBlockIds);
          for (final e in events) {
            yield e;
          }
        } catch (e) {
          print('[AI Stream] Malformed chunk: $e');
        }
      }
    }

    final remaining = lineBuffer.toString().trim();
    if (remaining.isNotEmpty && remaining.startsWith('data: ') && remaining != 'data: [DONE]') {
      try {
        final json = jsonDecode(remaining.substring(6)) as Map<String, dynamic>;
        for (final e in _parse(provider, json, anthropicBlockIds)) {
          yield e;
        }
      } catch (e) {
        print('[AI Stream] Buffer flush error: $e');
      }
    }
  } catch (e) {
    yield StreamError(e.toString());
  } finally {
    client.close();
  }
}

List<StreamEvent> _parse(AiProvider provider, Map<String, dynamic> json, Map<int, String> anthropicBlockIds) {
  switch (provider) {
    case AiProvider.anthropic:
      return _parseAnthropic(json, anthropicBlockIds);
    case AiProvider.openai:
    case AiProvider.selfHosted:
      return _parseOpenAI(json);
    case AiProvider.google:
      return _parseGoogle(json);
  }
}

List<StreamEvent> _parseAnthropic(Map<String, dynamic> json, Map<int, String> blockIds) {
  final events = <StreamEvent>[];
  final type = json['type'] as String?;

  switch (type) {
    case 'message_start':
      final usage = json['message']?['usage'];
      if (usage != null) {
        events.add(UsageUpdate(TokenUsage((usage['input_tokens'] as int?) ?? 0, 0)));
      }

    case 'content_block_start':
      final index = json['index'] as int? ?? 0;
      final block = json['content_block'];
      if (block != null && block['type'] == 'tool_use') {
        final id = block['id'] ?? '';
        blockIds[index] = id;
        events.add(ToolCallStart(id, block['name'] ?? ''));
      }

    case 'content_block_delta':
      final delta = json['delta'];
      if (delta != null) {
        if (delta['type'] == 'text_delta') {
          events.add(TextDelta(delta['text'] ?? ''));
        } else if (delta['type'] == 'input_json_delta') {
          final index = json['index'] as int? ?? 0;
          final id = blockIds[index] ?? '$index';
          events.add(ToolCallInputDelta(id, delta['partial_json'] ?? ''));
        }
      }

    case 'content_block_stop':
      final index = json['index'] as int? ?? 0;
      final id = blockIds[index] ?? '$index';
      events.add(ToolCallEnd(id));

    case 'message_delta':
      final usage = json['usage'];
      final stopReason = json['delta']?['stop_reason'] as String?;
      if (usage != null) {
        events.add(UsageUpdate(TokenUsage(0, (usage['output_tokens'] as int?) ?? 0)));
      }
      if (stopReason != null) {
        events.add(StreamComplete(stopReason));
      }
  }
  return events;
}

List<StreamEvent> _parseOpenAI(Map<String, dynamic> json) {
  final events = <StreamEvent>[];

  final usage = json['usage'];
  if (usage != null) {
    events.add(UsageUpdate(TokenUsage((usage['prompt_tokens'] as int?) ?? 0, (usage['completion_tokens'] as int?) ?? 0)));
  }

  final choices = json['choices'] as List?;
  if (choices == null || choices.isEmpty) return events;

  final choice = choices[0] as Map<String, dynamic>;
  final delta = choice['delta'] as Map<String, dynamic>?;
  final finishReason = choice['finish_reason'] as String?;

  if (delta != null) {
    final content = delta['content'] as String?;
    if (content != null) events.add(TextDelta(content));

    final toolCalls = delta['tool_calls'] as List?;
    if (toolCalls != null) {
      for (final tc in toolCalls) {
        final index = tc['index'] as int? ?? 0;
        final id = tc['id'] as String?;
        final function = tc['function'] as Map<String, dynamic>?;

        if (id != null && function != null && function['name'] != null) {
          events.add(ToolCallStart(id, function['name']));
        }
        if (function != null && function['arguments'] != null) {
          final fragment = function['arguments'] as String;
          if (fragment.isNotEmpty) {
            events.add(ToolCallInputDelta(id ?? '$index', fragment));
          }
        }
      }
    }
  }

  if (finishReason != null) {
    events.add(StreamComplete(finishReason));
  }

  return events;
}

List<StreamEvent> _parseGoogle(Map<String, dynamic> json) {
  final events = <StreamEvent>[];

  final usageMeta = json['usageMetadata'];
  if (usageMeta != null) {
    events.add(UsageUpdate(TokenUsage((usageMeta['promptTokenCount'] as int?) ?? 0, (usageMeta['candidatesTokenCount'] as int?) ?? 0)));
  }

  final candidates = json['candidates'] as List?;
  if (candidates == null || candidates.isEmpty) return events;

  final content = candidates[0]['content'] as Map<String, dynamic>?;
  if (content == null) return events;

  final parts = content['parts'] as List?;
  if (parts == null) return events;

  for (final part in parts) {
    if (part['text'] != null) {
      events.add(TextDelta(part['text'] as String));
    }
    if (part['functionCall'] != null) {
      final fc = part['functionCall'] as Map<String, dynamic>;
      final name = fc['name'] as String? ?? '';
      final args = fc['args'] as Map<String, dynamic>?;
      final id = 'google_${name}_${_uuid()}';
      events.add(ToolCallStart(id, name));
      if (args != null) {
        events.add(ToolCallInputDelta(id, jsonEncode(args)));
      }
      events.add(ToolCallEnd(id));
    }
  }

  final finishReason = candidates[0]['finishReason'] as String?;
  if (finishReason != null && finishReason != 'STOP') {
    events.add(StreamComplete(finishReason));
  }

  return events;
}

final _rng = Random.secure();
String _uuid() {
  final bytes = List<int>.generate(16, (_) => _rng.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
  bytes[8] = (bytes[8] & 0x3f) | 0x80; // variant 1
  final h = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
}

Map<String, dynamic> _toGoogleMessage(Map<String, dynamic> msg) {
  final role = msg['role'] as String;

  if (role == 'function') return msg;

  if (role == 'tool') {
    return {
      'role': 'function',
      'parts': [
        {
          'functionResponse': {
            'name': msg['name'] ?? '',
            'response': {'result': msg['content']},
          },
        },
      ],
    };
  }

  final toolCalls = msg['tool_calls'] as List?;
  if (toolCalls != null) {
    final parts = <Map<String, dynamic>>[];
    final content = msg['content'] as String?;
    if (content != null && content.isNotEmpty) {
      parts.add({'text': content});
    }
    for (final tc in toolCalls) {
      final fn = tc['function'] as Map<String, dynamic>;
      parts.add({
        'functionCall': {'name': fn['name'], 'args': jsonDecode(fn['arguments'] as String? ?? '{}')},
      });
    }
    return {'role': 'model', 'parts': parts};
  }

  return {
    'role': role == 'assistant' ? 'model' : 'user',
    'parts': [
      {'text': msg['content'] ?? ''},
    ],
  };
}
