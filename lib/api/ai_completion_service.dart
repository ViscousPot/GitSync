import 'dart:convert';

import 'package:GitSync/api/ai_provider_validator.dart';
import 'package:GitSync/api/manager/storage.dart';
import 'package:GitSync/global.dart';
import 'package:http/http.dart' as http;

Future<String?> aiComplete({required String systemPrompt, required String userPrompt}) async {
  final providerName = await repoManager.getStringNullable(StorageKey.repoman_aiProvider);
  if (providerName == null) return null;
  final provider = aiProviderFromString(providerName);
  if (provider == null) return null;

  final apiKey = await repoManager.getStringNullable(StorageKey.repoman_aiApiKey);
  final endpoint = await repoManager.getStringNullable(StorageKey.repoman_aiEndpoint);
  final storedModel = await repoManager.getStringNullable(StorageKey.repoman_aiWandModel);

  if (apiKey == null || apiKey.isEmpty) return null;
  if (storedModel == null || storedModel.isEmpty) return null;

  final model = storedModel;

  try {
    final http.Response response;
    final Uri url;
    final Map<String, String> headers;
    final String body;

    switch (provider) {
      case AiProvider.selfHosted:
        final base = normalizeEndpoint(endpoint ?? '');
        url = Uri.parse('$base/chat/completions');
        headers = {'Authorization': 'Bearer $apiKey', 'Content-Type': 'application/json'};
        body = jsonEncode({
          'model': model,
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': userPrompt},
          ],
        });

      case AiProvider.openai:
        url = Uri.parse('https://api.openai.com/v1/chat/completions');
        headers = {'Authorization': 'Bearer $apiKey', 'Content-Type': 'application/json'};
        body = jsonEncode({
          'model': model,
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': userPrompt},
          ],
        });

      case AiProvider.anthropic:
        url = Uri.parse('https://api.anthropic.com/v1/messages');
        headers = {'x-api-key': apiKey, 'anthropic-version': '2023-06-01', 'Content-Type': 'application/json'};
        body = jsonEncode({
          'model': model,
          'max_tokens': 1024,
          'system': systemPrompt,
          'messages': [
            {'role': 'user', 'content': userPrompt},
          ],
        });

      case AiProvider.google:
        url = Uri.parse('https://generativelanguage.googleapis.com/v1/models/$model:generateContent?key=$apiKey');
        headers = {'Content-Type': 'application/json'};
        body = jsonEncode({
          'system_instruction': {
            'parts': [
              {'text': systemPrompt},
            ],
          },
          'contents': [
            {
              'parts': [
                {'text': userPrompt},
              ],
            },
          ],
        });
    }

    response = await http.post(url, headers: headers, body: body).timeout(const Duration(seconds: 60));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      print('[AI Complete] HTTP ${response.statusCode}: ${response.body.length > 200 ? response.body.substring(0, 200) : response.body}');
      return null;
    }

    final json = jsonDecode(utf8.decode(response.bodyBytes));

    String? result;
    switch (provider) {
      case AiProvider.selfHosted:
      case AiProvider.openai:
        result = json['choices']?[0]?['message']?['content'] as String?;
      case AiProvider.anthropic:
        result = json['content']?[0]?['text'] as String?;
      case AiProvider.google:
        result = json['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
    }

    return result;
  } catch (e) {
    print('[AI Complete] $e');
    return null;
  }
}

String formatDiffParts(Map<String, Map<String, String>> diffParts, {int maxChars = 4000}) {
  final buffer = StringBuffer();
  for (final entry in diffParts.entries) {
    if (buffer.length >= maxChars) break;
    buffer.writeln('File: ${entry.key}');
    for (final hunk in entry.value.values) {
      if (buffer.length >= maxChars) break;
      final cleaned = _cleanDiffMarkers(hunk);
      final remaining = maxChars - buffer.length;
      buffer.writeln(cleaned.length > remaining ? cleaned.substring(0, remaining) : cleaned);
    }
    buffer.writeln();
  }
  return buffer.toString();
}

String _cleanDiffMarkers(String raw) {
  return raw.replaceAll('+++++insertion+++++', '+ ').replaceAll('-----deletion-----', '- ');
}
