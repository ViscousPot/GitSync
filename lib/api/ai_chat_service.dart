import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:mixin_logger/mixin_logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:GitSync/api/ai_provider_validator.dart';
import 'package:GitSync/api/ai_stream_client.dart';
import 'package:GitSync/api/ai_system_prompt.dart';
import 'package:GitSync/api/ai_tool_executor.dart';
import 'package:GitSync/api/ai_tools.dart';
import 'package:GitSync/api/ai_tools_file.dart';
import 'package:GitSync/api/ai_tools_git.dart';
import 'package:GitSync/api/ai_tools_provider.dart';
import 'package:GitSync/api/manager/auth/git_provider_manager.dart';
import 'package:GitSync/api/manager/git_manager.dart';
import 'package:GitSync/api/manager/storage.dart';
import 'package:GitSync/global.dart';
import 'package:GitSync/type/ai_chat.dart';

const _maxToolRounds = 25;

class _RepoConversation {
  List<ChatMessage> messages = [];
  TokenUsage sessionUsage = const TokenUsage(0, 0);
  TokenUsage lastTurnUsage = const TokenUsage(0, 0);
  int messageCounter = 0;
  Set<String> activatedTools = {};

  bool isStreaming = false;
  String streamingText = '';
  String? error;
  bool cancelled = false;

  String nextId() => 'msg_${messageCounter++}_${DateTime.now().millisecondsSinceEpoch}';

  Map<String, dynamic> toJson() => {
    'messages': messages.map((m) => m.toJson()).toList(),
    'sessionUsage': {'input': sessionUsage.inputTokens, 'output': sessionUsage.outputTokens},
    'lastTurnUsage': {'input': lastTurnUsage.inputTokens, 'output': lastTurnUsage.outputTokens},
    'messageCounter': messageCounter,
    'activatedTools': activatedTools.toList(),
  };

  static _RepoConversation fromJson(Map<String, dynamic> json) {
    final conv = _RepoConversation();
    conv.messages = (json['messages'] as List?)?.map((m) => ChatMessage.fromJson(m)).toList() ?? [];
    final su = json['sessionUsage'] as Map<String, dynamic>?;
    if (su != null) conv.sessionUsage = TokenUsage(su['input'] ?? 0, su['output'] ?? 0);
    final ltu = json['lastTurnUsage'] as Map<String, dynamic>?;
    if (ltu != null) conv.lastTurnUsage = TokenUsage(ltu['input'] ?? 0, ltu['output'] ?? 0);
    conv.messageCounter = json['messageCounter'] ?? conv.messages.length;
    conv.activatedTools = (json['activatedTools'] as List?)?.cast<String>().toSet() ?? {};
    return conv;
  }
}

class AiChatService {
  final ValueNotifier<List<ChatMessage>> messages = ValueNotifier([]);
  final ValueNotifier<bool> isStreaming = ValueNotifier(false);
  final ValueNotifier<String> streamingText = ValueNotifier('');
  final ValueNotifier<TokenUsage> sessionUsage = ValueNotifier(const TokenUsage(0, 0));
  final ValueNotifier<TokenUsage> lastTurnUsage = ValueNotifier(const TokenUsage(0, 0));
  final ValueNotifier<String?> error = ValueNotifier(null);

  final ToolRegistry _toolRegistry = ToolRegistry();
  late final ToolExecutor _toolExecutor;

  Future<bool> Function(AiTool tool, Map<String, dynamic> input)? onConfirmationRequired;

  final Map<int, _RepoConversation> _conversations = {};
  int _activeRepoIndex = -1;

  AiChatService() {
    _toolRegistry.registerAll(allGitTools());
    _toolRegistry.registerAll(allFileTools());
    _toolRegistry.registerAll(allProviderTools());
    _toolRegistry.register(ListAvailableToolsTool(_toolRegistry));
    _toolExecutor = ToolExecutor(
      registry: _toolRegistry,
      onConfirmationRequired: (tool, input) async {
        if (onConfirmationRequired != null) return onConfirmationRequired!(tool, input);
        return false;
      },
    );
  }

  _RepoConversation _convFor(int index) {
    return _conversations.putIfAbsent(index, () => _RepoConversation());
  }

  _RepoConversation _conv() => _convFor(_activeRepoIndex);

  Future<void> switchToRepo() async {
    final index = await repoManager.getInt(StorageKey.repoman_repoIndex);
    if (index == _activeRepoIndex) return;
    _activeRepoIndex = index;
    if (!_conversations.containsKey(index)) {
      await _loadFromDisk(index);
    }
    _syncNotifiers();
  }

  void _syncNotifiers() {
    final conv = _conv();
    messages.value = conv.messages;
    sessionUsage.value = conv.sessionUsage;
    lastTurnUsage.value = conv.lastTurnUsage;
    isStreaming.value = conv.isStreaming;
    streamingText.value = conv.streamingText;
    error.value = conv.error;
  }

  void _syncIfActive(int repoIndex) {
    if (repoIndex == _activeRepoIndex) _syncNotifiers();
  }

  Future<void> clearConversation() async {
    final conv = _conv();
    conv.cancelled = true;
    _conversations.remove(_activeRepoIndex);
    await _deleteDiskFile(_activeRepoIndex);
    _syncNotifiers();
  }

  void stop() {
    _conv().cancelled = true;
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    await switchToRepo();
    final repoIndex = _activeRepoIndex;
    final conv = _convFor(repoIndex);

    conv.cancelled = false;
    conv.error = null;

    final userMsg = ChatMessage(id: conv.nextId(), role: ChatRole.user, content: [TextBlock(text)]);
    conv.messages = [...conv.messages, userMsg];
    _syncIfActive(repoIndex);
    _saveToDisk(repoIndex);

    final providerName = await repoManager.getStringNullable(StorageKey.repoman_aiProvider);
    if (providerName == null) {
      conv.error = 'AI not configured. Set up your API key first.';
      e('AiChatService.sendMessage: AI not configured');
      _syncIfActive(repoIndex);
      return;
    }
    final provider = aiProviderFromString(providerName);
    if (provider == null) {
      conv.error = 'Unknown provider: $providerName';
      e('AiChatService.sendMessage: unknown provider $providerName');
      _syncIfActive(repoIndex);
      return;
    }

    final apiKey = await repoManager.getStringNullable(StorageKey.repoman_aiApiKey);
    final endpoint = await repoManager.getStringNullable(StorageKey.repoman_aiEndpoint);
    final storedChatModel = await repoManager.getStringNullable(StorageKey.repoman_aiChatModel);
    final storedToolModel = await repoManager.getStringNullable(StorageKey.repoman_aiToolModel);

    if (apiKey == null || apiKey.isEmpty) {
      conv.error = 'AI not configured. Set up your API key first.';
      e('AiChatService.sendMessage: ${conv.error}');
      _syncIfActive(repoIndex);
      return;
    }

    if (storedChatModel == null || storedChatModel.isEmpty || storedToolModel == null || storedToolModel.isEmpty) {
      conv.error = 'Chat or tool model not selected. Please configure both in AI Settings.';
      e('AiChatService.sendMessage: chat/tool model not selected');
      _syncIfActive(repoIndex);
      return;
    }
    final chatModel = storedChatModel;
    final toolModel = storedToolModel;

    final gitProvider = await uiSettingsManager.getGitProvider();
    final githubAppOauth = await uiSettingsManager.getBool(StorageKey.setman_githubScopedOauth);
    final credentials = await uiSettingsManager.getGitHttpAuthCredentials();
    final remote = await GitManager.getRemoteUrlLink(repoIndex: repoIndex);
    final segments = remote != null ? Uri.parse(remote.$1).pathSegments : <String>[];
    final toolContext = ToolContext(
      repoIndex: repoIndex,
      repoPath: (await uiSettingsManager.getGitDirPath())?.$1 ?? '',
      gitProvider: gitProvider,
      githubAppOauth: githubAppOauth,
      accessToken: credentials.$2,
      username: credentials.$1,
      owner: segments.length >= 2 ? segments[segments.length - 2] : '',
      repo: segments.length >= 2 ? segments[segments.length - 1].replaceAll('.git', '') : '',
      providerManager: gitProvider.isOAuthProvider ? GitProviderManager.getGitProviderManager(gitProvider, githubAppOauth) : null,
      authorName: await uiSettingsManager.getAuthorName(),
      authorEmail: await uiSettingsManager.getAuthorEmail(),
    );

    // Two prompts: a long detailed one for the tool model rounds (which both
    // benefits from explicit tool guidance and acts as cache filler to keep
    // us above Haiku 4.5's 4,096-token cache minimum), and a short one for
    // the chat model final synthesis (which doesn't see tools and just needs
    // persona + style).
    final toolSystemPrompt = await buildToolModelSystemPrompt(repoIndex: repoIndex);
    final chatSystemPrompt = await buildChatModelSystemPrompt(repoIndex: repoIndex);

    await _runAgenticLoop(repoIndex, toolContext, provider, apiKey, chatModel, toolModel, endpoint, toolSystemPrompt, chatSystemPrompt);
  }

  Future<void> _runAgenticLoop(
    int repoIndex,
    ToolContext toolContext,
    AiProvider provider,
    String apiKey,
    String chatModel,
    String toolModel,
    String? endpoint,
    String toolSystemPrompt,
    String chatSystemPrompt,
  ) async {
    final conv = _convFor(repoIndex);
    conv.isStreaming = true;
    _syncIfActive(repoIndex);

    final hasOAuth = toolContext.providerManager != null && toolContext.accessToken.isNotEmpty;
    final modelsDiffer = chatModel != toolModel;

    try {
      for (var round = 0; round < _maxToolRounds; round++) {
        if (conv.cancelled) break;

        var roundResult = await _streamRound(
          repoIndex: repoIndex,
          provider: provider,
          apiKey: apiKey,
          model: toolModel,
          endpoint: endpoint,
          systemPrompt: toolSystemPrompt,
          hasOAuth: hasOAuth,
          activatedTools: conv.activatedTools,
          includeTools: true,
        );

        if (conv.cancelled) break;

        final hadToolCalls = roundResult.contentBlocks.any((b) => b is ToolUseBlock);

        // When chat and tool models differ and the tool model produced no tool
        // calls, this round is the final synthesis. Re-stream with the chat
        // model so the user-facing reply comes from the chat model. We do NOT
        // pre-clear streamingText here — the tool model's draft stays visible
        // until the chat model's first delta replaces it, which avoids a
        // blank gap during sonnet's TTFT.
        if (modelsDiffer && !hadToolCalls) {
          final chatResult = await _streamRound(
            repoIndex: repoIndex,
            provider: provider,
            apiKey: apiKey,
            model: chatModel,
            endpoint: endpoint,
            systemPrompt: chatSystemPrompt,
            hasOAuth: hasOAuth,
            activatedTools: conv.activatedTools,
            includeTools: false,
          );

          if (conv.cancelled) break;

          final combinedUsage = TokenUsage(
            roundResult.usage.inputTokens + chatResult.usage.inputTokens,
            roundResult.usage.outputTokens + chatResult.usage.outputTokens,
          );
          // Adopt the chat model's content only if it actually produced
          // something usable. If sonnet errored or returned an empty stream,
          // keep the tool model's text so the assistant bubble is never
          // empty (which would render as an invisible widget and look like
          // the message "disappeared").
          final chatHasContent = chatResult.contentBlocks.any((b) => (b is TextBlock && b.text.isNotEmpty) || b is ToolUseBlock);
          roundResult = (contentBlocks: chatHasContent ? chatResult.contentBlocks : roundResult.contentBlocks, usage: combinedUsage);
        }

        final turnUsage = roundResult.usage;
        conv.lastTurnUsage = turnUsage;
        conv.sessionUsage = conv.sessionUsage + turnUsage;

        final assistantMsg = ChatMessage(id: conv.nextId(), role: ChatRole.assistant, content: roundResult.contentBlocks, usage: turnUsage);
        conv.messages = [...conv.messages, assistantMsg];
        conv.streamingText = '';
        _syncIfActive(repoIndex);
        _saveToDisk(repoIndex);

        final toolCalls = assistantMsg.toolCalls;
        if (toolCalls.isEmpty || conv.cancelled) break;

        for (final toolCall in toolCalls) {
          if (conv.cancelled) break;

          final tool = _toolRegistry.get(toolCall.toolName);
          if (tool != null && tool.tier == ToolTier.advanced) {
            conv.activatedTools.add(toolCall.toolName);
          }

          final result = await _toolExecutor.execute(toolCall, toolContext);

          final toolResultMsg = ChatMessage(id: conv.nextId(), role: ChatRole.tool, content: [TextBlock(result)]);
          conv.messages = [...conv.messages, toolResultMsg];
          _syncIfActive(repoIndex);
          _saveToDisk(repoIndex);
        }

        if (toolCalls.every((tc) => tc.status == ToolCallStatus.rejected)) break;
      }
    } catch (err, st) {
      conv.error = err.toString();
      e('AiChatService._runAgenticLoop: $err\n$st');
      _syncIfActive(repoIndex);
    } finally {
      conv.isStreaming = false;
      conv.streamingText = '';
      _syncIfActive(repoIndex);
      _saveToDisk(repoIndex);
    }
  }

  Future<({List<ContentBlock> contentBlocks, TokenUsage usage})> _streamRound({
    required int repoIndex,
    required AiProvider provider,
    required String apiKey,
    required String model,
    required String? endpoint,
    required String systemPrompt,
    required bool hasOAuth,
    required Set<String> activatedTools,
    required bool includeTools,
  }) async {
    final conv = _convFor(repoIndex);
    final apiMessages = _buildApiMessages(provider, conv.messages);
    final filteredTools = includeTools ? _toolRegistry.getFiltered(hasOAuth: hasOAuth, activated: activatedTools) : <AiTool>[];
    // Note: we deliberately do NOT clear `conv.streamingText` here. The
    // chat-synthesis path needs the tool model's draft to stay visible until
    // the chat model's first TextDelta replaces it, otherwise the user sees
    // a blank gap during the chat model's TTFT. For all other rounds the
    // previous round's epilogue (line ~312) already left streamingText empty.

    final contentBlocks = <ContentBlock>[];
    var currentTextBlock = TextBlock('');
    contentBlocks.add(currentTextBlock);

    final toolCallBuilders = <String, _ToolCallBuilder>{};
    var turnInputTokens = 0;
    var turnOutputTokens = 0;

    await for (final event in streamCompletion(
      provider: provider,
      systemPrompt: systemPrompt,
      messages: apiMessages,
      tools: filteredTools,
      apiKey: apiKey,
      model: model,
      endpoint: endpoint,
      isCancelled: () => conv.cancelled,
    )) {
      if (conv.cancelled) break;

      switch (event) {
        case TextDelta(:final text):
          currentTextBlock.text += text;
          conv.streamingText = currentTextBlock.text;
          _syncIfActive(repoIndex);

        case ToolCallStart(:final id, :final name):
          toolCallBuilders[id] = _ToolCallBuilder(id: id, name: name);
          if (currentTextBlock.text.isNotEmpty) {
            currentTextBlock = TextBlock('');
            contentBlocks.add(currentTextBlock);
          }

        case ToolCallInputDelta(:final id, :final jsonFragment):
          toolCallBuilders[id]?.argsBuffer.write(jsonFragment);

        case ToolCallEnd(:final id):
          final builder = toolCallBuilders[id];
          if (builder != null && builder.name.isNotEmpty) {
            Map<String, dynamic> args = {};
            try {
              args = jsonDecode(builder.argsBuffer.toString()) as Map<String, dynamic>;
            } catch (_) {}
            contentBlocks.add(ToolUseBlock(toolCallId: builder.id, toolName: builder.name, input: args));
            currentTextBlock = TextBlock('');
            contentBlocks.add(currentTextBlock);
          }

        case UsageUpdate(:final usage):
          turnInputTokens += usage.inputTokens;
          turnOutputTokens += usage.outputTokens;

        case StreamComplete _:
          break;

        case StreamError(:final message):
          conv.error = message;
          e('AiChatService._streamRound: $message');
          _syncIfActive(repoIndex);
      }
    }

    contentBlocks.removeWhere((b) => b is TextBlock && b.text.isEmpty);

    for (final entry in toolCallBuilders.entries) {
      final builder = entry.value;
      if (builder.name.isNotEmpty && !contentBlocks.any((b) => b is ToolUseBlock && b.toolCallId == builder.id)) {
        Map<String, dynamic> args = {};
        try {
          args = jsonDecode(builder.argsBuffer.toString()) as Map<String, dynamic>;
        } catch (_) {}
        contentBlocks.add(ToolUseBlock(toolCallId: builder.id, toolName: builder.name, input: args));
      }
    }

    return (contentBlocks: contentBlocks, usage: TokenUsage(turnInputTokens, turnOutputTokens));
  }

  Future<String> _chatDir() async {
    final dir = await getApplicationSupportDirectory();
    return '${dir.path}/ai_chats';
  }

  Future<void> _saveToDisk(int repoIndex) async {
    try {
      final dir = await _chatDir();
      await Directory(dir).create(recursive: true);
      final file = File('$dir/$repoIndex.json');
      final conv = _convFor(repoIndex);
      await file.writeAsString(jsonEncode(conv.toJson()));
    } catch (e) {
      print('[AI Chat] Failed to save: $e');
    }
  }

  Future<void> _loadFromDisk(int repoIndex) async {
    try {
      final dir = await _chatDir();
      final file = File('$dir/$repoIndex.json');
      if (!await file.exists()) return;
      final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      _conversations[repoIndex] = _RepoConversation.fromJson(json);
    } catch (e) {
      print('[AI Chat] Failed to load: $e');
    }
  }

  Future<void> _deleteDiskFile(int repoIndex) async {
    try {
      final dir = await _chatDir();
      final file = File('$dir/$repoIndex.json');
      if (await file.exists()) await file.delete();
    } catch (e) {
      print('[AI Chat] Failed to delete disk file: $e');
    }
  }

  List<Map<String, dynamic>> _buildApiMessages(AiProvider provider, List<ChatMessage> msgs) {
    final apiMessages = <Map<String, dynamic>>[];

    final isAnthropicShape = provider == AiProvider.anthropic;

    // Anthropic requires that all tool_result blocks for parallel tool_use
    // calls be packed into a single user turn. Google's functionResponse is
    // analogous: one role:function message containing all parts. We buffer
    // consecutive ChatRole.tool messages and flush at the next role boundary.
    final pendingToolEntries = <Map<String, dynamic>>[];

    void flushTools() {
      if (pendingToolEntries.isEmpty) return;
      if (isAnthropicShape) {
        apiMessages.add({'role': 'user', 'content': List<Map<String, dynamic>>.from(pendingToolEntries)});
      } else if (provider == AiProvider.google) {
        apiMessages.add({'role': 'function', 'parts': List<Map<String, dynamic>>.from(pendingToolEntries)});
      } else {
        // OpenAI / self-hosted: each tool result is its own role:tool message.
        for (final entry in pendingToolEntries) {
          apiMessages.add(Map<String, dynamic>.from(entry));
        }
      }
      pendingToolEntries.clear();
    }

    for (final msg in msgs) {
      if (msg.role == ChatRole.tool) {
        final toolCall = _findToolCallForResult(msg, msgs);
        if (isAnthropicShape) {
          pendingToolEntries.add({'type': 'tool_result', 'tool_use_id': toolCall?.toolCallId ?? '', 'content': msg.textContent});
        } else if (provider == AiProvider.google) {
          pendingToolEntries.add({
            'functionResponse': {
              'name': toolCall?.toolName ?? '',
              'response': {'result': msg.textContent},
            },
          });
        } else {
          pendingToolEntries.add({'role': 'tool', 'tool_call_id': toolCall?.toolCallId ?? '', 'content': msg.textContent});
        }
        continue;
      }

      flushTools();

      switch (msg.role) {
        case ChatRole.user:
          apiMessages.add({'role': 'user', 'content': msg.textContent});

        case ChatRole.assistant:
          // Skip empty-content assistant turns rather than emitting an empty
          // text block — Anthropic rejects `{type:'text', text:''}`, and
          // historically a single bad round (cancelled/errored stream) would
          // poison the entire chat until cleared. The skip is safe because
          // tool_use rounds always have content (the ToolUseBlock itself), so
          // we never drop a turn that sits between a tool_use and its
          // tool_result.
          Map<String, dynamic>? built;
          if (isAnthropicShape) {
            built = _anthropicAssistantMessage(msg);
          } else if (provider == AiProvider.google) {
            built = _googleAssistantMessage(msg);
          } else {
            built = _openaiAssistantMessage(msg);
          }
          if (built != null) apiMessages.add(built);

        case ChatRole.tool:
          // Unreachable: handled above.
          break;
      }
    }
    flushTools();
    return apiMessages;
  }

  Map<String, dynamic>? _anthropicAssistantMessage(ChatMessage msg) {
    final content = <Map<String, dynamic>>[];
    for (final block in msg.content) {
      if (block is TextBlock && block.text.isNotEmpty) {
        content.add({'type': 'text', 'text': block.text});
      } else if (block is ToolUseBlock) {
        content.add({'type': 'tool_use', 'id': block.toolCallId, 'name': block.toolName, 'input': block.input});
      }
    }
    // Anthropic rejects `{type:'text', text:''}`. If the assistant turn produced
    // nothing usable (cancelled/errored stream, etc.) skip it entirely so a
    // single bad round can't poison the whole chat.
    if (content.isEmpty) return null;
    return {'role': 'assistant', 'content': content};
  }

  Map<String, dynamic> _openaiAssistantMessage(ChatMessage msg) {
    final toolCalls = msg.toolCalls;
    final text = msg.textContent;
    final result = <String, dynamic>{'role': 'assistant'};
    if (text.isNotEmpty) result['content'] = text;
    if (toolCalls.isNotEmpty) {
      result['tool_calls'] = toolCalls
          .map(
            (tc) => {
              'id': tc.toolCallId,
              'type': 'function',
              'function': {'name': tc.toolName, 'arguments': jsonEncode(tc.input)},
            },
          )
          .toList();
    }
    if (text.isEmpty && toolCalls.isEmpty) result['content'] = '';
    return result;
  }

  Map<String, dynamic>? _googleAssistantMessage(ChatMessage msg) {
    final parts = <Map<String, dynamic>>[];
    for (final block in msg.content) {
      if (block is TextBlock && block.text.isNotEmpty) {
        parts.add({'text': block.text});
      } else if (block is ToolUseBlock) {
        parts.add({
          'functionCall': {'name': block.toolName, 'args': block.input},
        });
      }
    }
    if (parts.isEmpty) return null;
    return {'role': 'model', 'parts': parts};
  }

  ToolUseBlock? _findToolCallForResult(ChatMessage toolResultMsg, List<ChatMessage> msgs) {
    final idx = msgs.indexOf(toolResultMsg);
    if (idx < 0) return null;

    var toolResultCount = 0;
    for (var i = idx - 1; i >= 0; i--) {
      final m = msgs[i];
      if (m.role == ChatRole.tool) {
        toolResultCount++;
      } else if (m.role == ChatRole.assistant) {
        final calls = m.toolCalls;
        if (toolResultCount < calls.length) {
          return calls[toolResultCount];
        }
        return calls.isNotEmpty ? calls.last : null;
      } else {
        break;
      }
    }
    return null;
  }
}

class _ToolCallBuilder {
  final String id;
  final String name;
  final StringBuffer argsBuffer = StringBuffer();
  _ToolCallBuilder({required this.id, required this.name});
}
