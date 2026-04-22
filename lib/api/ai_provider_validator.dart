import 'dart:convert';

import 'package:GitSync/api/helper.dart';
import 'package:http/http.dart' as http;

enum AiProvider { anthropic, openai, google, selfHosted }

Future<String?> validateAiApiKey({required AiProvider provider, required String apiKey, String? endpoint}) async {
  if (apiKey.trim().isEmpty) return "API key cannot be empty";
  if (provider == AiProvider.selfHosted && (endpoint == null || endpoint.trim().isEmpty)) {
    return "Endpoint URL is required for self-hosted providers";
  }

  try {
    final http.Response response;
    switch (provider) {
      case AiProvider.anthropic:
        response = await httpGet(Uri.parse('https://api.anthropic.com/v1/models'), headers: {'x-api-key': apiKey, 'anthropic-version': '2023-06-01'});
      case AiProvider.openai:
        response = await httpGet(Uri.parse('https://api.openai.com/v1/models'), headers: {'Authorization': 'Bearer $apiKey'});
      case AiProvider.google:
        response = await httpGet(Uri.parse('https://generativelanguage.googleapis.com/v1/models?key=$apiKey'));
      case AiProvider.selfHosted:
        final normalized = normalizeEndpoint(endpoint!);
        response = await httpGet(Uri.parse('$normalized/models'), headers: {'Authorization': 'Bearer $apiKey'});
    }

    if (response.statusCode == 408) return "Connection timed out";
    if (response.statusCode == 401 || response.statusCode == 403) return "Invalid API key";
    if (response.statusCode >= 200 && response.statusCode < 300) return null;
    return "Unexpected response (${response.statusCode})";
  } catch (e) {
    return "Connection failed: ${e.toString()}";
  }
}

String normalizeEndpoint(String endpoint) {
  var e = endpoint.trim();
  if (e.endsWith('/')) e = e.substring(0, e.length - 1);
  if (!e.startsWith('http://') && !e.startsWith('https://')) {
    e = 'http://$e';
  }
  return e;
}

AiProvider? aiProviderFromString(String? name) {
  switch (name) {
    case 'Anthropic':
      return AiProvider.anthropic;
    case 'OpenAI':
      return AiProvider.openai;
    case 'Google':
      return AiProvider.google;
    case 'Self-hosted':
      return AiProvider.selfHosted;
    default:
      return null;
  }
}

Future<(List<String>, String?)> fetchAvailableModels({required AiProvider provider, required String apiKey, String? endpoint}) async {
  try {
    final http.Response response;
    switch (provider) {
      case AiProvider.anthropic:
        response = await httpGet(Uri.parse('https://api.anthropic.com/v1/models'), headers: {'x-api-key': apiKey, 'anthropic-version': '2023-06-01'});
      case AiProvider.openai:
        response = await httpGet(Uri.parse('https://api.openai.com/v1/models'), headers: {'Authorization': 'Bearer $apiKey'});
      case AiProvider.google:
        response = await httpGet(Uri.parse('https://generativelanguage.googleapis.com/v1/models?key=$apiKey'));
      case AiProvider.selfHosted:
        final normalized = normalizeEndpoint(endpoint ?? '');
        response = await httpGet(Uri.parse('$normalized/models'), headers: {'Authorization': 'Bearer $apiKey'});
    }

    if (response.statusCode == 408) return (<String>[], "Connection timed out. Check your network and try again.");
    if (response.statusCode == 401 || response.statusCode == 403) return (<String>[], "Invalid API key. Please check your key and try again.");
    if (response.statusCode == 429) return (<String>[], "Rate limited. Please wait a moment and try again.");
    if (response.statusCode < 200 || response.statusCode >= 300) return (<String>[], "Failed to load models (${response.statusCode})");

    final json = jsonDecode(utf8.decode(response.bodyBytes));

    switch (provider) {
      case AiProvider.selfHosted:
      case AiProvider.openai:
        final data = json['data'] as List?;
        if (data == null) return (<String>[], null);
        return (data.map<String>((m) => m['id']?.toString() ?? '').where((id) => id.isNotEmpty).toList(), null);
      case AiProvider.anthropic:
        final data = json['data'] as List?;
        if (data == null) return (<String>[], null);
        return (data.map<String>((m) => m['id']?.toString() ?? '').where((id) => id.isNotEmpty).toList(), null);
      case AiProvider.google:
        final models = json['models'] as List?;
        if (models == null) return (<String>[], null);
        return (models.map<String>((m) => (m['name']?.toString() ?? '').replaceFirst('models/', '')).where((id) => id.isNotEmpty).toList(), null);
    }
  } catch (e) {
    final msg = e.toString();
    if (msg.contains('SocketException')) return (<String>[], "Network error. Check your connection.");
    return (<String>[], "Connection failed: $msg");
  }
}

String aiProviderToString(AiProvider provider) {
  switch (provider) {
    case AiProvider.anthropic:
      return 'Anthropic';
    case AiProvider.openai:
      return 'OpenAI';
    case AiProvider.google:
      return 'Google';
    case AiProvider.selfHosted:
      return 'Self-hosted';
  }
}
