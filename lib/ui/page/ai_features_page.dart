import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'package:GitSync/api/ai_provider_validator.dart';
import 'package:GitSync/api/ai_tools.dart';
import 'package:GitSync/api/manager/storage.dart';
import 'package:GitSync/global.dart';
import 'package:GitSync/constant/dimens.dart';
import 'package:GitSync/type/ai_chat.dart';
import 'package:GitSync/ui/component/markdown_config.dart';

const _mono = TextStyle(fontFamily: "monospace", height: 1.6);

class AiFeaturesPage extends StatefulWidget {
  const AiFeaturesPage({super.key});
  @override
  State<AiFeaturesPage> createState() => _AiFeaturesPageState();
}

class _AiFeaturesPageState extends State<AiFeaturesPage> {
  bool _initialized = false;
  String? _currentModel;
  String? _currentProvider;

  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  Completer<bool>? _confirmationCompleter;
  AiTool? _pendingTool;

  @override
  void initState() {
    super.initState();
    _checkStoredApiKey();
    aiChatService.onConfirmationRequired = _onConfirmationRequired;
    aiChatService.switchToRepo();
  }

  @override
  void dispose() {
    if (_confirmationCompleter != null && !_confirmationCompleter!.isCompleted) {
      _confirmationCompleter!.complete(false);
    }
    _inputController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _checkStoredApiKey() async {
    final provider = await repoManager.getStringNullable(StorageKey.repoman_aiProvider);
    final apiKey = await repoManager.getStringNullable(StorageKey.repoman_aiApiKey);
    final model = await repoManager.getStringNullable(StorageKey.repoman_aiModel);
    if (provider != null && provider.isNotEmpty && apiKey != null && apiKey.isNotEmpty) {
      if (mounted)
        setState(() {
          _initialized = true;
          _currentModel = model;
          _currentProvider = provider;
        });
    }
  }

  Future<bool> _onConfirmationRequired(AiTool tool, Map<String, dynamic> input) async {
    _confirmationCompleter = Completer<bool>();
    setState(() {
      _pendingTool = tool;
    });
    final result = await _confirmationCompleter!.future;
    setState(() {
      _pendingTool = null;
      _confirmationCompleter = null;
    });
    return result;
  }

  void _sendMessage() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    _inputController.clear();
    aiChatService.sendMessage(text);
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) return _UninitializedPage(onSubscribe: () => _checkStoredApiKey());

    return Container(
      color: colours.primaryDark,
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                ValueListenableBuilder<List<ChatMessage>>(
                  valueListenable: aiChatService.messages,
                  builder: (context, messages, _) {
                    return ValueListenableBuilder<String>(
                      valueListenable: aiChatService.streamingText,
                      builder: (context, streamingText, _) {
                        return ValueListenableBuilder<bool>(
                          valueListenable: aiChatService.isStreaming,
                          builder: (context, isStreaming, _) {
                            final itemCount =
                                messages.length +
                                (streamingText.isNotEmpty ? 1 : 0) // streaming text
                                +
                                (_pendingTool != null ? 1 : 0); // pending confirmation

                            if (messages.isEmpty && !isStreaming) {
                              return _emptyState();
                            }

                            return ListView.builder(
                              controller: _scrollController,
                              reverse: true,
                              padding: EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceSM),
                              itemCount: itemCount,
                              itemBuilder: (context, reverseIndex) {
                                final index = itemCount - 1 - reverseIndex;
                                if (index < messages.length) {
                                  return _buildMessage(messages[index]);
                                }
                                final offset = index - messages.length;
                                if (streamingText.isNotEmpty && offset == 0) {
                                  return Padding(
                                    padding: EdgeInsets.only(bottom: spaceXS),
                                    child: _responseStreaming(streamingText),
                                  );
                                }
                                if (_pendingTool != null) {
                                  return _confirmationChip(_pendingTool!);
                                }
                                return const SizedBox.shrink();
                              },
                            );
                          },
                        );
                      },
                    );
                  },
                ),

                Positioned(
                  top: spaceSM,
                  left: spaceMD,
                  right: spaceMD,
                  child: Row(
                    children: [
                      ValueListenableBuilder<List<ChatMessage>>(
                        valueListenable: aiChatService.messages,
                        builder: (context, messages, _) {
                          if (messages.isEmpty) return const SizedBox.shrink();
                          return GestureDetector(
                            onTap: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (context) => Dialog(
                                  backgroundColor: colours.secondaryDark,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusMD)),
                                  child: Padding(
                                    padding: EdgeInsets.all(spaceMD),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          "Clear chat?",
                                          style: TextStyle(color: colours.primaryLight, fontSize: textLG, fontWeight: FontWeight.bold),
                                        ),
                                        SizedBox(height: spaceXS),
                                        Text(
                                          "This will delete the entire conversation history for this container.",
                                          style: TextStyle(color: colours.secondaryLight, fontSize: textSM),
                                          textAlign: TextAlign.center,
                                        ),
                                        SizedBox(height: spaceMD),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: TextButton(
                                                onPressed: () => Navigator.pop(context, false),
                                                style: ButtonStyle(
                                                  backgroundColor: WidgetStatePropertyAll(colours.tertiaryDark),
                                                  shape: WidgetStatePropertyAll(
                                                    RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusSM)),
                                                  ),
                                                  padding: WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: spaceSM)),
                                                ),
                                                child: Text(
                                                  "Cancel",
                                                  style: TextStyle(color: colours.primaryLight, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                            ),
                                            SizedBox(width: spaceXS),
                                            Expanded(
                                              child: TextButton(
                                                onPressed: () => Navigator.pop(context, true),
                                                style: ButtonStyle(
                                                  backgroundColor: WidgetStatePropertyAll(colours.primaryNegative),
                                                  shape: WidgetStatePropertyAll(
                                                    RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusSM)),
                                                  ),
                                                  padding: WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: spaceSM)),
                                                ),
                                                child: Text(
                                                  "Clear",
                                                  style: TextStyle(color: colours.primaryDark, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                              if (confirmed == true) aiChatService.clearConversation();
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: spaceSM, vertical: spaceXXS),
                              decoration: BoxDecoration(
                                color: colours.secondaryDark,
                                borderRadius: BorderRadius.all(cornerRadiusMax),
                                border: Border.all(color: colours.primaryNegative),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  FaIcon(FontAwesomeIcons.trashCan, color: colours.primaryNegative, size: textXS),
                                  SizedBox(width: spaceXXS),
                                  Text(
                                    "Clear chat",
                                    style: _mono.merge(TextStyle(color: colours.primaryNegative, fontSize: textXS)),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      Spacer(),
                      GestureDetector(
                        onTap: () => _showTokenDialog(context),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: spaceSM, vertical: spaceXXS),
                          decoration: BoxDecoration(
                            color: colours.secondaryDark,
                            borderRadius: BorderRadius.all(cornerRadiusMax),
                            border: Border.all(color: colours.tertiaryDark),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FaIcon(FontAwesomeIcons.microchip, color: colours.secondaryLight, size: textXS),
                              SizedBox(width: spaceXXS),
                              Text(
                                _currentProvider ?? '',
                                style: _mono.merge(TextStyle(color: colours.secondaryLight, fontSize: textXS)),
                              ),
                              if (_currentModel != null) ...[
                                SizedBox(width: spaceXXS),
                                Text(
                                  _currentModel!,
                                  style: _mono.merge(TextStyle(color: colours.tertiaryInfo, fontSize: textXS, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          ValueListenableBuilder<String?>(
            valueListenable: aiChatService.error,
            builder: (context, error, _) {
              if (error == null) return const SizedBox.shrink();
              return Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceXS),
                color: colours.primaryNegative.withValues(alpha: 0.15),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        error,
                        style: _mono.merge(TextStyle(color: colours.primaryNegative, fontSize: textXS)),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => aiChatService.error.value = null,
                      child: FaIcon(FontAwesomeIcons.xmark, color: colours.primaryNegative, size: textSM),
                    ),
                  ],
                ),
              );
            },
          ),

          _inputBar(),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: spaceMD),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Spacer(),
          FaIcon(FontAwesomeIcons.wandMagicSparkles, color: colours.tertiaryInfo, size: spaceLG),
          SizedBox(height: spaceSM),
          Text(
            "GitSync AI",
            style: TextStyle(color: colours.primaryLight, fontSize: textLG, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: spaceXXS),
          Text(
            "Ask anything about your repository",
            style: TextStyle(color: colours.secondaryLight, fontSize: textSM),
          ),
          SizedBox(height: spaceLG),
          Wrap(
            spacing: spaceXS,
            runSpacing: spaceXS,
            alignment: WrapAlignment.center,
            children: [
              _quickAction(FontAwesomeIcons.codeBranch, "What's my status?", "Summarize uncommitted changes, branch, and sync state"),
              _quickAction(FontAwesomeIcons.penToSquare, "Write a commit", "Stage changes and create a commit with a good message"),
              _quickAction(FontAwesomeIcons.clockRotateLeft, "Recent history", "Show recent commits with details"),
              _quickAction(FontAwesomeIcons.circleQuestion, "Open issues", "List open issues in this repo"),
            ],
          ),
          SizedBox(height: spaceLG),
        ],
      ),
    );
  }

  Widget _quickAction(FaIconData icon, String title, String subtitle) {
    return GestureDetector(
      onTap: () {
        _inputController.text = title;
        _sendMessage();
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(spaceSM),
        decoration: BoxDecoration(
          color: colours.secondaryDark,
          borderRadius: BorderRadius.all(cornerRadiusSM),
          border: Border.all(color: colours.tertiaryDark),
        ),
        child: Row(
          children: [
            FaIcon(icon, color: colours.tertiaryInfo, size: textSM),
            SizedBox(width: spaceSM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(color: colours.primaryLight, fontSize: textSM, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(color: colours.secondaryLight, fontSize: textXS),
                  ),
                ],
              ),
            ),
            FaIcon(FontAwesomeIcons.chevronRight, color: colours.tertiaryDark, size: textXS),
          ],
        ),
      ),
    );
  }

  Widget _buildMessage(ChatMessage msg) {
    switch (msg.role) {
      case ChatRole.user:
        return Padding(
          padding: EdgeInsets.only(bottom: spaceSM),
          child: _prompt(msg.textContent),
        );

      case ChatRole.assistant:
        final widgets = <Widget>[];
        for (final block in msg.content) {
          if (block is TextBlock && block.text.isNotEmpty) {
            widgets.add(_responseMarkdown(block.text));
            widgets.add(SizedBox(height: spaceXS));
          } else if (block is ToolUseBlock) {
            widgets.add(_toolUseWidget(block));
            widgets.add(SizedBox(height: spaceXS));
          }
        }
        if (widgets.isNotEmpty && widgets.last is SizedBox) widgets.removeLast();
        return Padding(
          padding: EdgeInsets.only(bottom: spaceSM),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: widgets),
        );

      case ChatRole.tool:
        return const SizedBox.shrink();
    }
  }

  Widget _prompt(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "> ",
          style: _mono.merge(TextStyle(color: colours.tertiaryInfo, fontSize: textMD, fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: Text(
            text,
            style: _mono.merge(TextStyle(color: colours.primaryLight, fontSize: textMD, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _responseMarkdown(String text) {
    return MarkdownBlock(data: text, config: buildMarkdownConfig(), generator: buildMarkdownGenerator());
  }

  Widget _responseStreaming(String text) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          style: TextStyle(color: colours.primaryLight, fontSize: textSM),
        ),
        SizedBox(height: spaceXS),
        _typingIndicator(),
      ],
    );
  }

  Widget _typingIndicator() {
    return _AnimatedDots();
  }

  Widget _toolUseWidget(ToolUseBlock block) {
    final statusIcon = switch (block.status) {
      ToolCallStatus.pending => FontAwesomeIcons.clock,
      ToolCallStatus.approved => FontAwesomeIcons.check,
      ToolCallStatus.rejected => FontAwesomeIcons.xmark,
      ToolCallStatus.running => FontAwesomeIcons.spinner,
      ToolCallStatus.completed => FontAwesomeIcons.check,
      ToolCallStatus.failed => FontAwesomeIcons.triangleExclamation,
    };
    final statusColor = switch (block.status) {
      ToolCallStatus.pending => colours.secondaryLight,
      ToolCallStatus.approved || ToolCallStatus.completed => colours.primaryPositive,
      ToolCallStatus.rejected => colours.primaryNegative,
      ToolCallStatus.running => colours.tertiaryInfo,
      ToolCallStatus.failed => colours.primaryNegative,
    };

    final inputSummary = _summarizeToolInput(block.toolName, block.input);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: colours.tertiaryDark),
        borderRadius: BorderRadius.all(cornerRadiusSM),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: spaceSM, vertical: spaceXXS),
            decoration: BoxDecoration(
              color: colours.tertiaryDark,
              borderRadius: BorderRadius.vertical(top: Radius.circular(cornerRadiusSM.x)),
            ),
            child: Row(
              children: [
                FaIcon(statusIcon, color: statusColor, size: textXS),
                SizedBox(width: spaceXS),
                Expanded(
                  child: Text(
                    "${block.toolName}  $inputSummary",
                    style: _mono.merge(TextStyle(color: colours.secondaryLight, fontSize: textXS)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          if (block.output != null || block.error != null) Padding(padding: EdgeInsets.all(spaceSM), child: _toolResultContent(block)),
        ],
      ),
    );
  }

  Widget _toolResultContent(ToolUseBlock block) {
    if (block.error != null) {
      return Text(
        block.error!,
        style: _mono.merge(TextStyle(color: colours.primaryNegative, fontSize: textXS)),
      );
    }

    final output = block.output ?? '';
    try {
      final json = jsonDecode(output);
      final result = json['result'];
      final error = json['error'];
      if (error != null) {
        return Text(
          error.toString(),
          style: _mono.merge(TextStyle(color: colours.primaryNegative, fontSize: textXS)),
        );
      }
      if (result is String) {
        return Text(
          result,
          style: _mono.merge(TextStyle(color: colours.secondaryLight, fontSize: textXS)),
          maxLines: 20,
          overflow: TextOverflow.ellipsis,
        );
      }
      if (result is Map || result is List) {
        final formatted = const JsonEncoder.withIndent('  ').convert(result);
        return Text(
          formatted,
          style: _mono.merge(TextStyle(color: colours.secondaryLight, fontSize: textXS)),
          maxLines: 20,
          overflow: TextOverflow.ellipsis,
        );
      }
      return Text(
        result.toString(),
        style: _mono.merge(TextStyle(color: colours.secondaryLight, fontSize: textXS)),
      );
    } catch (_) {
      return Text(
        output,
        style: _mono.merge(TextStyle(color: colours.secondaryLight, fontSize: textXS)),
        maxLines: 20,
        overflow: TextOverflow.ellipsis,
      );
    }
  }

  String _summarizeToolInput(String toolName, Map<String, dynamic> input) {
    if (input.containsKey('paths')) return (input['paths'] as List).join(', ');
    if (input.containsKey('path')) return input['path'] as String;
    if (input.containsKey('file_path')) return input['file_path'] as String;
    if (input.containsKey('name')) return input['name'] as String;
    if (input.containsKey('sha')) return input['sha'] as String;
    if (input.containsKey('message')) {
      final msg = input['message'] as String;
      return msg.length > 50 ? '${msg.substring(0, 50)}...' : msg;
    }
    if (input.containsKey('pattern')) return input['pattern'] as String;
    return '';
  }

  Widget _confirmationChip(AiTool tool) {
    final isDanger = tool.confirmation == ToolConfirmation.danger;
    final isConfirm = tool.confirmation == ToolConfirmation.confirm || isDanger;
    final borderColor = isConfirm ? colours.primaryNegative : colours.primaryWarning;

    if (isDanger) return _dangerConfirmationChip(tool);

    return Container(
      margin: EdgeInsets.only(bottom: spaceSM),
      padding: EdgeInsets.all(spaceSM),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.all(cornerRadiusSM),
        color: borderColor.withValues(alpha: 0.08),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Allow ${tool.name}?",
            style: _mono.merge(TextStyle(color: colours.primaryLight, fontSize: textSM, fontWeight: FontWeight.bold)),
          ),
          SizedBox(height: spaceXS),
          Text(
            tool.description,
            style: TextStyle(color: colours.secondaryLight, fontSize: textXS),
          ),
          SizedBox(height: spaceSM),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => _confirmationCompleter?.complete(false),
                  style: ButtonStyle(
                    backgroundColor: WidgetStatePropertyAll(colours.tertiaryDark),
                    shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusSM))),
                    padding: WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: spaceXS)),
                  ),
                  child: Text(
                    "Reject",
                    style: TextStyle(color: colours.primaryNegative, fontSize: textSM, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              SizedBox(width: spaceXS),
              Expanded(
                child: TextButton(
                  onPressed: () => _confirmationCompleter?.complete(true),
                  style: ButtonStyle(
                    backgroundColor: WidgetStatePropertyAll(
                      isConfirm ? colours.primaryNegative.withValues(alpha: 0.15) : colours.primaryWarning.withValues(alpha: 0.15),
                    ),
                    shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusSM))),
                    padding: WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: spaceXS)),
                  ),
                  child: Text(
                    "Allow",
                    style: TextStyle(
                      color: isConfirm ? colours.primaryNegative : colours.primaryWarning,
                      fontSize: textSM,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dangerConfirmationChip(AiTool tool) {
    final confirmController = TextEditingController();
    return StatefulBuilder(
      builder: (context, setChipState) {
        final typed = confirmController.text.trim().toUpperCase() == 'CONFIRM';
        return Container(
          margin: EdgeInsets.only(bottom: spaceSM),
          padding: EdgeInsets.all(spaceSM),
          decoration: BoxDecoration(
            border: Border.all(color: colours.primaryNegative, width: 2),
            borderRadius: BorderRadius.all(cornerRadiusSM),
            color: colours.primaryNegative.withValues(alpha: 0.12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  FaIcon(FontAwesomeIcons.triangleExclamation, color: colours.primaryNegative, size: textSM),
                  SizedBox(width: spaceXS),
                  Expanded(
                    child: Text(
                      "Destructive: ${tool.name}",
                      style: _mono.merge(TextStyle(color: colours.primaryNegative, fontSize: textSM, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              SizedBox(height: spaceXS),
              Text(
                tool.description,
                style: TextStyle(color: colours.primaryLight, fontSize: textXS),
              ),
              SizedBox(height: spaceSM),
              Text(
                "Type CONFIRM to proceed:",
                style: TextStyle(color: colours.secondaryLight, fontSize: textXS),
              ),
              SizedBox(height: spaceXXS),
              TextField(
                controller: confirmController,
                onChanged: (_) => setChipState(() {}),
                style: _mono.merge(TextStyle(color: colours.primaryLight, fontSize: textSM)),
                decoration: InputDecoration(
                  hintText: "CONFIRM",
                  hintStyle: _mono.merge(TextStyle(color: colours.tertiaryDark, fontSize: textSM)),
                  filled: true,
                  fillColor: colours.primaryDark,
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(cornerRadiusSM), borderSide: BorderSide.none),
                  contentPadding: EdgeInsets.symmetric(horizontal: spaceSM, vertical: spaceXS),
                ),
              ),
              SizedBox(height: spaceSM),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        confirmController.dispose();
                        _confirmationCompleter?.complete(false);
                      },
                      style: ButtonStyle(
                        backgroundColor: WidgetStatePropertyAll(colours.tertiaryDark),
                        shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusSM))),
                        padding: WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: spaceXS)),
                      ),
                      child: Text(
                        "Reject",
                        style: TextStyle(color: colours.primaryNegative, fontSize: textSM, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  SizedBox(width: spaceXS),
                  Expanded(
                    child: TextButton(
                      onPressed: typed
                          ? () {
                              confirmController.dispose();
                              _confirmationCompleter?.complete(true);
                            }
                          : null,
                      style: ButtonStyle(
                        backgroundColor: WidgetStatePropertyAll(typed ? colours.primaryNegative : colours.tertiaryDark),
                        shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusSM))),
                        padding: WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: spaceXS)),
                      ),
                      child: Text(
                        "I understand, proceed",
                        style: TextStyle(color: typed ? colours.primaryDark : colours.secondaryLight, fontSize: textSM, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showTokenDialog(BuildContext context) async {
    final isSelfHosted = _currentProvider == 'Self-hosted';
    String? selectedModel = _currentModel;
    List<String> availableModels = [];
    bool loadingModels = true;

    void Function(void Function())? _setDialogState;

    () async {
      final provider = aiProviderFromString(_currentProvider);
      if (provider != null) {
        final apiKey = await repoManager.getStringNullable(StorageKey.repoman_aiApiKey) ?? '';
        final endpoint = isSelfHosted ? await repoManager.getStringNullable(StorageKey.repoman_aiEndpoint) : null;
        final (models, _) = await fetchAvailableModels(provider: provider, apiKey: apiKey, endpoint: endpoint);
        availableModels = models;
      }
      loadingModels = false;
      _setDialogState?.call(() {});
    }();

    final signedOut = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          _setDialogState = setDialogState;

          final model = selectedModel ?? '';

          return Dialog(
            backgroundColor: colours.secondaryDark,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusMD)),
            child: Padding(
              padding: EdgeInsets.all(spaceMD),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      FaIcon(FontAwesomeIcons.microchip, color: colours.tertiaryInfo, size: textLG),
                      SizedBox(width: spaceXS),
                      Text(
                        "AI Settings",
                        style: TextStyle(color: colours.primaryLight, fontSize: textLG, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  SizedBox(height: spaceMD),

                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(spaceSM),
                    decoration: BoxDecoration(color: colours.tertiaryDark, borderRadius: BorderRadius.all(cornerRadiusSM)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              "Provider",
                              style: TextStyle(color: colours.secondaryLight, fontSize: textXS),
                            ),
                            Spacer(),
                            Text(
                              _currentProvider ?? '',
                              style: _mono.merge(TextStyle(color: colours.tertiaryInfo, fontSize: textXS, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        SizedBox(height: spaceXS),
                        Row(
                          children: [
                            Text(
                              "Model",
                              style: TextStyle(color: colours.secondaryLight, fontSize: textXS),
                            ),
                            SizedBox(width: spaceSM),
                            Expanded(
                              child: loadingModels
                                  ? Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        SizedBox(
                                          width: textSM,
                                          height: textSM,
                                          child: CircularProgressIndicator(strokeWidth: 1.5, color: colours.secondaryLight),
                                        ),
                                        SizedBox(width: spaceXS),
                                        Text(
                                          model,
                                          style: _mono.merge(TextStyle(color: colours.primaryLight, fontSize: textXS)),
                                        ),
                                      ],
                                    )
                                  : availableModels.isNotEmpty
                                  ? DropdownButton<String>(
                                      value: availableModels.contains(selectedModel) ? selectedModel : null,
                                      hint: Text(
                                        model,
                                        style: _mono.merge(TextStyle(color: colours.primaryLight, fontSize: textXS)),
                                      ),
                                      isExpanded: true,
                                      dropdownColor: colours.secondaryDark,
                                      underline: SizedBox.shrink(),
                                      isDense: true,
                                      alignment: AlignmentDirectional.centerEnd,
                                      style: _mono.merge(TextStyle(color: colours.primaryLight, fontSize: textXS)),
                                      items: availableModels
                                          .map(
                                            (m) => DropdownMenuItem(
                                              value: m,
                                              alignment: AlignmentDirectional.centerEnd,
                                              child: Text(m, overflow: TextOverflow.ellipsis),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (v) async {
                                        if (v == null) return;
                                        await repoManager.setStringNullable(StorageKey.repoman_aiModel, v);
                                        setDialogState(() => selectedModel = v);
                                        if (mounted) setState(() => _currentModel = v);
                                      },
                                    )
                                  : Align(
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        model,
                                        style: _mono.merge(TextStyle(color: colours.primaryLight, fontSize: textXS, fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: spaceMD),

                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () async {
                            await repoManager.setStringNullable(StorageKey.repoman_aiProvider, null);
                            await repoManager.setStringNullable(StorageKey.repoman_aiApiKey, null);
                            await repoManager.setStringNullable(StorageKey.repoman_aiEndpoint, null);
                            await repoManager.setStringNullable(StorageKey.repoman_aiModel, null);
                            aiKeyConfigured.value = false;
                            aiChatService.clearConversation();
                            Navigator.pop(context, true);
                          },
                          style: ButtonStyle(
                            backgroundColor: WidgetStatePropertyAll(colours.tertiaryDark),
                            shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusSM))),
                            padding: WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: spaceSM)),
                          ),
                          child: Text(
                            "Sign Out",
                            style: TextStyle(color: colours.primaryNegative, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      SizedBox(width: spaceXS),
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: ButtonStyle(
                            backgroundColor: WidgetStatePropertyAll(colours.tertiaryInfo),
                            shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusSM))),
                            padding: WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: spaceSM)),
                          ),
                          child: Text(
                            "Done",
                            style: TextStyle(color: colours.primaryDark, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    _setDialogState = null;

    if (signedOut == true && mounted) {
      setState(() => _initialized = false);
    }
  }

  void _confirmStop(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: colours.secondaryDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusMD)),
        child: Padding(
          padding: EdgeInsets.all(spaceMD),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Stop generating?",
                style: TextStyle(color: colours.primaryLight, fontSize: textLG, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: spaceXS),
              Text(
                "This will cancel the current response. Any partial output will be kept.",
                style: TextStyle(color: colours.secondaryLight, fontSize: textSM),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: spaceMD),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: ButtonStyle(
                        backgroundColor: WidgetStatePropertyAll(colours.tertiaryDark),
                        shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusSM))),
                        padding: WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: spaceSM)),
                      ),
                      child: Text(
                        "Continue",
                        style: TextStyle(color: colours.primaryLight, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  SizedBox(width: spaceXS),
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ButtonStyle(
                        backgroundColor: WidgetStatePropertyAll(colours.primaryNegative),
                        shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusSM))),
                        padding: WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: spaceSM)),
                      ),
                      child: Text(
                        "Stop",
                        style: TextStyle(color: colours.primaryDark, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed == true) aiChatService.stop();
  }

  Widget _inputBar() {
    return ValueListenableBuilder<bool>(
      valueListenable: aiChatService.isStreaming,
      builder: (context, isStreaming, _) {
        return Container(
          decoration: BoxDecoration(color: colours.primaryDark),
          child: SafeArea(
            top: false,
            child: Container(
              decoration: BoxDecoration(color: colours.tertiaryDark, borderRadius: BorderRadius.all(cornerRadiusSM)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      focusNode: _focusNode,
                      enabled: !isStreaming,
                      style: _mono.merge(TextStyle(color: colours.primaryLight, fontSize: textSM)),
                      maxLines: 4,
                      minLines: 1,
                      decoration: InputDecoration(
                        hintText: "Ask anything...",
                        hintStyle: _mono.merge(TextStyle(color: colours.secondaryLight, fontSize: textSM)),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: spaceSM, vertical: spaceSM),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  GestureDetector(
                    onTap: isStreaming ? () => _confirmStop(context) : _sendMessage,
                    child: Container(
                      margin: EdgeInsets.all(spaceXXS),
                      padding: EdgeInsets.all(spaceSM),
                      decoration: BoxDecoration(
                        color: isStreaming ? colours.primaryNegative : colours.tertiaryInfo,
                        borderRadius: BorderRadius.all(cornerRadiusSM),
                      ),
                      child: FaIcon(isStreaming ? FontAwesomeIcons.stop : FontAwesomeIcons.solidPaperPlane, color: colours.primaryDark, size: textSM),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AnimatedDots extends StatefulWidget {
  @override
  State<_AnimatedDots> createState() => _AnimatedDotsState();
}

class _AnimatedDotsState extends State<_AnimatedDots> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++)
              Padding(
                padding: EdgeInsets.only(right: spaceXXS),
                child: Opacity(
                  opacity: ((t * 3 - i).clamp(0.0, 1.0) - (t * 3 - i - 1.5).clamp(0.0, 1.0)).abs().clamp(0.3, 1.0),
                  child: Container(
                    width: spaceXS,
                    height: spaceXS,
                    decoration: BoxDecoration(color: colours.tertiaryInfo, shape: BoxShape.circle),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _UninitializedPage extends StatefulWidget {
  final VoidCallback onSubscribe;
  const _UninitializedPage({required this.onSubscribe});

  @override
  State<_UninitializedPage> createState() => _UninitializedPageState();
}

class _UninitializedPageState extends State<_UninitializedPage> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: colours.primaryDark,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: spaceMD),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: spaceXL),
              FaIcon(FontAwesomeIcons.wandMagicSparkles, color: colours.tertiaryInfo, size: spaceXL),
              SizedBox(height: spaceMD),
              Text(
                "GitSync AI",
                style: TextStyle(color: colours.primaryLight, fontSize: textXXL, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: spaceXS),
              Text(
                "Your AI-powered Git assistant",
                style: TextStyle(color: colours.secondaryLight, fontSize: textMD),
              ),
              SizedBox(height: spaceLG),
              _featureRow(FontAwesomeIcons.codeCommit, "Smart Commits", "Auto-generate meaningful commit messages from your changes"),
              SizedBox(height: spaceSM),
              _featureRow(FontAwesomeIcons.codeBranch, "Conflict Resolution", "Resolve merge conflicts with context-aware suggestions"),
              SizedBox(height: spaceSM),
              _featureRow(FontAwesomeIcons.filePen, "Code Editing", "Edit files, add headers, refactor code — all from chat"),
              SizedBox(height: spaceSM),
              _featureRow(FontAwesomeIcons.filter, "LFS & Filters", "Set up Git LFS, git-crypt, and .gitignore rules instantly"),
              SizedBox(height: spaceLG * 2),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => _showByokDialog(context),
                  style: ButtonStyle(
                    backgroundColor: WidgetStatePropertyAll(colours.tertiaryInfo),
                    shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusSM))),
                    padding: WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: spaceSM)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FaIcon(FontAwesomeIcons.key, color: colours.primaryDark, size: textMD),
                      SizedBox(width: spaceXS),
                      Text(
                        "Connect API Key",
                        style: TextStyle(color: colours.primaryDark, fontSize: textMD, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: spaceLG),
            ],
          ),
        ),
      ),
    );
  }

  void _showByokDialog(BuildContext context) async {
    final apiKeyController = TextEditingController();
    final endpointController = TextEditingController();
    final dialogScrollController = ScrollController();
    String? selectedProvider;
    String? selectedModel;
    List<String> availableModels = [];
    bool loadingModels = false;
    bool loading = false;
    String? error;
    String? modelFetchError;
    Timer? fetchDebounce;
    bool dialogOpen = true;
    void Function(void Function())? safeSetState;

    void tryFetchModels() {
      fetchDebounce?.cancel();
      if (!dialogOpen || selectedProvider == null || apiKeyController.text.trim().isEmpty || loadingModels) return;
      fetchDebounce = Timer(const Duration(milliseconds: 800), () async {
        if (!dialogOpen) return;
        safeSetState?.call(() {
          loadingModels = true;
        });
        final provider = aiProviderFromString(selectedProvider);
        if (provider != null) {
          final apiKey = apiKeyController.text.trim();
          final endpoint = selectedProvider == "Self-hosted" ? endpointController.text.trim() : null;
          final (models, fetchError) = await fetchAvailableModels(provider: provider, apiKey: apiKey, endpoint: endpoint);
          if (!dialogOpen) return;
          availableModels = models;
          modelFetchError = fetchError;
          if (availableModels.isNotEmpty) selectedModel = availableModels.first;
        }
        safeSetState?.call(() {
          loadingModels = false;
        });
        if (modelFetchError != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (dialogScrollController.hasClients) {
              dialogScrollController.animateTo(
                dialogScrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
              );
            }
          });
        }
      });
    }

    final connected = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          safeSetState = (fn) {
            if (dialogOpen) setDialogState(fn);
          };
          final canConnect =
              selectedProvider != null && apiKeyController.text.trim().isNotEmpty && selectedModel != null && !loading && !loadingModels;

          return Dialog(
            backgroundColor: colours.secondaryDark,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusMD)),
            child: Padding(
              padding: EdgeInsets.all(spaceMD),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      FaIcon(FontAwesomeIcons.key, color: colours.tertiaryInfo, size: textLG),
                      SizedBox(width: spaceXS),
                      Text(
                        "Bring Your Own Key",
                        style: TextStyle(color: colours.primaryLight, fontSize: textLG, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  SizedBox(height: spaceMD),
                  Text(
                    "Provider",
                    style: TextStyle(color: colours.secondaryLight, fontSize: textSM, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: spaceXS),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: spaceSM),
                    decoration: BoxDecoration(color: colours.tertiaryDark, borderRadius: BorderRadius.all(cornerRadiusSM)),
                    child: DropdownButton<String>(
                      value: selectedProvider,
                      isExpanded: true,
                      dropdownColor: colours.secondaryDark,
                      underline: SizedBox.shrink(),
                      hint: Text(
                        "Select a provider",
                        style: TextStyle(color: colours.secondaryLight, fontSize: textSM),
                      ),
                      style: TextStyle(color: colours.primaryLight, fontSize: textSM, fontWeight: FontWeight.bold),
                      items: [
                        for (final p in [
                          ("Anthropic", FontAwesomeIcons.claude),
                          ("OpenAI", FontAwesomeIcons.openai),
                          ("Google", FontAwesomeIcons.google),
                          ("Self-hosted", FontAwesomeIcons.server),
                        ])
                          DropdownMenuItem(
                            value: p.$1,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                FaIcon(p.$2, color: colours.secondaryLight, size: textSM),
                                SizedBox(width: spaceXS),
                                Text(p.$1),
                              ],
                            ),
                          ),
                      ],
                      onChanged: loading
                          ? null
                          : (name) {
                              safeSetState?.call(() {
                                selectedProvider = name;
                                availableModels = [];
                                selectedModel = null;
                                modelFetchError = null;
                              });
                              if (name != null && apiKeyController.text.trim().isNotEmpty) {
                                tryFetchModels();
                              }
                            },
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      controller: dialogScrollController,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: spaceMD),
                          if (selectedProvider == "Self-hosted") ...[
                            Text(
                              "Endpoint URL",
                              style: TextStyle(color: colours.secondaryLight, fontSize: textSM, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: spaceXS),
                            TextField(
                              controller: endpointController,
                              style: _mono.merge(TextStyle(color: colours.primaryLight, fontSize: textSM)),
                              decoration: InputDecoration(
                                hintText: "your-server.com/v1",
                                hintStyle: _mono.merge(TextStyle(color: colours.secondaryLight, fontSize: textSM)),
                                filled: true,
                                fillColor: colours.tertiaryDark,
                                border: OutlineInputBorder(borderRadius: BorderRadius.all(cornerRadiusSM), borderSide: BorderSide.none),
                                contentPadding: EdgeInsets.symmetric(horizontal: spaceSM, vertical: spaceSM),
                              ),
                            ),
                            SizedBox(height: spaceSM),
                          ],
                          Text(
                            "API Key",
                            style: TextStyle(color: colours.secondaryLight, fontSize: textSM, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: spaceXS),
                          TextField(
                            controller: apiKeyController,
                            obscureText: true,
                            onChanged: (_) {
                              safeSetState?.call(() {
                                modelFetchError = null;
                              });
                              if (availableModels.isEmpty) tryFetchModels();
                            },
                            style: _mono.merge(TextStyle(color: colours.primaryLight, fontSize: textSM)),
                            decoration: InputDecoration(
                              hintText: selectedProvider == null ? "Select a provider first" : "sk-...",
                              hintStyle: _mono.merge(TextStyle(color: colours.secondaryLight, fontSize: textSM)),
                              filled: true,
                              fillColor: colours.tertiaryDark,
                              border: OutlineInputBorder(borderRadius: BorderRadius.all(cornerRadiusSM), borderSide: BorderSide.none),
                              contentPadding: EdgeInsets.symmetric(horizontal: spaceSM, vertical: spaceSM),
                            ),
                            enabled: selectedProvider != null && !loading,
                          ),
                          SizedBox(height: spaceSM),
                          Row(
                            children: [
                              Text(
                                "Model",
                                style: TextStyle(color: colours.secondaryLight, fontSize: textSM, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(width: spaceXS),
                              if (loadingModels)
                                SizedBox(
                                  width: textSM,
                                  height: textSM,
                                  child: CircularProgressIndicator(strokeWidth: 1.5, color: colours.secondaryLight),
                                ),
                            ],
                          ),
                          SizedBox(height: spaceXS),
                          if (availableModels.isEmpty && !loadingModels)
                            GestureDetector(
                              onTap: (selectedProvider != null && apiKeyController.text.trim().isNotEmpty && !loadingModels)
                                  ? () async {
                                      safeSetState?.call(() {
                                        loadingModels = true;
                                      });
                                      final provider = aiProviderFromString(selectedProvider);
                                      if (provider != null) {
                                        final apiKey = apiKeyController.text.trim();
                                        final endpoint = selectedProvider == "Self-hosted" ? endpointController.text.trim() : null;
                                        final (models, fetchError) = await fetchAvailableModels(provider: provider, apiKey: apiKey, endpoint: endpoint);
                                        if (!dialogOpen) return;
                                        availableModels = models;
                                        modelFetchError = fetchError;
                                        if (availableModels.isNotEmpty) selectedModel = availableModels.first;
                                      }
                                      safeSetState?.call(() {
                                        loadingModels = false;
                                      });
                                      if (modelFetchError != null) {
                                        WidgetsBinding.instance.addPostFrameCallback((_) {
                                          if (dialogScrollController.hasClients) {
                                            dialogScrollController.animateTo(
                                              dialogScrollController.position.maxScrollExtent,
                                              duration: const Duration(milliseconds: 200),
                                              curve: Curves.easeOut,
                                            );
                                          }
                                        });
                                      }
                                    }
                                  : null,
                              child: Container(
                                width: double.infinity,
                                padding: EdgeInsets.symmetric(horizontal: spaceSM, vertical: spaceSM),
                                decoration: BoxDecoration(color: colours.tertiaryDark, borderRadius: BorderRadius.all(cornerRadiusSM)),
                                child: Text(
                                  selectedProvider == null ? "Select a provider first" : "Tap to load models",
                                  style: _mono.merge(TextStyle(color: colours.secondaryLight, fontSize: textSM)),
                                ),
                              ),
                            )
                          else if (availableModels.isNotEmpty)
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(horizontal: spaceSM),
                              decoration: BoxDecoration(color: colours.tertiaryDark, borderRadius: BorderRadius.all(cornerRadiusSM)),
                              child: DropdownButton<String>(
                                value: selectedModel,
                                isExpanded: true,
                                dropdownColor: colours.secondaryDark,
                                underline: SizedBox.shrink(),
                                style: _mono.merge(TextStyle(color: colours.primaryLight, fontSize: textSM)),
                                items: availableModels
                                    .map(
                                      (m) => DropdownMenuItem(
                                        value: m,
                                        child: Text(m, overflow: TextOverflow.ellipsis),
                                      ),
                                    )
                                    .toList(),
                                onChanged: loading ? null : (v) => safeSetState?.call(() => selectedModel = v),
                              ),
                            ),
                          if (modelFetchError != null) ...[
                            SizedBox(height: spaceXS),
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(horizontal: spaceSM, vertical: spaceXS),
                              decoration: BoxDecoration(
                                color: colours.primaryNegative.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.all(cornerRadiusSM),
                                border: Border.all(color: colours.primaryNegative.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                children: [
                                  FaIcon(FontAwesomeIcons.circleExclamation, color: colours.primaryNegative, size: textSM),
                                  SizedBox(width: spaceXS),
                                  Expanded(
                                    child: Text(
                                      modelFetchError!,
                                      style: TextStyle(color: colours.primaryNegative, fontSize: textXS, height: 1.4),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (error != null) ...[
                            SizedBox(height: spaceXS),
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(horizontal: spaceSM, vertical: spaceXS),
                              decoration: BoxDecoration(
                                color: colours.primaryNegative.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.all(cornerRadiusSM),
                                border: Border.all(color: colours.primaryNegative.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                children: [
                                  FaIcon(FontAwesomeIcons.circleExclamation, color: colours.primaryNegative, size: textSM),
                                  SizedBox(width: spaceXS),
                                  Expanded(
                                    child: Text(
                                      error!,
                                      style: TextStyle(color: colours.primaryNegative, fontSize: textXS, height: 1.4),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: spaceMD),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: canConnect
                          ? () async {
                              safeSetState?.call(() {
                                loading = true;
                                error = null;
                              });

                              final provider = aiProviderFromString(selectedProvider);
                              final apiKey = apiKeyController.text.trim();
                              final endpoint = selectedProvider == "Self-hosted" ? endpointController.text.trim() : null;

                              final validationError = await validateAiApiKey(provider: provider!, apiKey: apiKey, endpoint: endpoint);

                              if (!dialogOpen) return;

                              if (validationError != null) {
                                safeSetState?.call(() {
                                  loading = false;
                                  error = validationError;
                                });
                                return;
                              }

                              await repoManager.setStringNullable(StorageKey.repoman_aiProvider, selectedProvider);
                              await repoManager.setStringNullable(StorageKey.repoman_aiApiKey, apiKey);
                              await repoManager.setStringNullable(StorageKey.repoman_aiEndpoint, endpoint);
                              await repoManager.setStringNullable(StorageKey.repoman_aiModel, selectedModel);
                              aiKeyConfigured.value = true;

                              if (!dialogOpen) return;
                              Navigator.pop(context, true);
                            }
                          : null,
                      style: ButtonStyle(
                        backgroundColor: WidgetStatePropertyAll(canConnect ? colours.tertiaryInfo : colours.tertiaryDark),
                        shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusSM))),
                        padding: WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: spaceSM)),
                      ),
                      child: loading
                          ? SizedBox(
                              height: textMD,
                              width: textMD,
                              child: CircularProgressIndicator(strokeWidth: 2, color: colours.primaryDark),
                            )
                          : Text(
                              "Connect",
                              style: TextStyle(
                                color: canConnect ? colours.primaryDark : colours.secondaryLight,
                                fontSize: textMD,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  SizedBox(height: spaceXS),
                  Text(
                    "Your API key is stored locally on this device and never sent to GitSync servers.",
                    style: TextStyle(color: colours.secondaryLight, fontSize: textXS, height: 1.4),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    dialogOpen = false;
    fetchDebounce?.cancel();

    if (connected == true) {
      widget.onSubscribe();
    }
  }

  Widget _featureRow(FaIconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: spaceLG,
          height: spaceLG,
          decoration: BoxDecoration(color: colours.tertiaryInfo.withValues(alpha: 0.15), borderRadius: BorderRadius.all(cornerRadiusSM)),
          child: Center(
            child: FaIcon(icon, color: colours.tertiaryInfo, size: textMD),
          ),
        ),
        SizedBox(width: spaceSM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(color: colours.primaryLight, fontSize: textMD, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: spaceXXXS),
              Text(
                description,
                style: TextStyle(color: colours.secondaryLight, fontSize: textSM, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
