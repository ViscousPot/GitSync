enum ChatRole { user, assistant, tool }

enum ToolCallStatus { pending, approved, rejected, running, completed, failed }

class ChatMessage {
  final String id;
  final ChatRole role;
  final DateTime timestamp;
  final List<ContentBlock> content;
  TokenUsage? usage;

  ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    this.usage,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  bool get hasToolCalls => content.any((b) => b is ToolUseBlock);
  List<ToolUseBlock> get toolCalls => content.whereType<ToolUseBlock>().toList();
  String get textContent => content.whereType<TextBlock>().map((b) => b.text).join();

  Map<String, dynamic> toJson() => {
    'id': id,
    'role': role.name,
    'timestamp': timestamp.millisecondsSinceEpoch,
    'content': content.map((b) {
      if (b is TextBlock) return {'type': 'text', 'text': b.text};
      if (b is ToolUseBlock) return {
        'type': 'tool_use',
        'toolCallId': b.toolCallId,
        'toolName': b.toolName,
        'input': b.input,
        'status': b.status.name,
        'output': b.output,
        'error': b.error,
      };
      return {};
    }).toList(),
    if (usage != null) 'usage': {'input': usage!.inputTokens, 'output': usage!.outputTokens},
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final content = (json['content'] as List).map<ContentBlock>((b) {
      if (b['type'] == 'text') return TextBlock(b['text'] ?? '');
      if (b['type'] == 'tool_use') return ToolUseBlock(
        toolCallId: b['toolCallId'] ?? '',
        toolName: b['toolName'] ?? '',
        input: (b['input'] as Map<String, dynamic>?) ?? {},
        status: _parseToolCallStatus(b['status']),
        output: b['output'],
        error: b['error'],
      );
      return TextBlock('');
    }).toList();

    final usageJson = json['usage'] as Map<String, dynamic>?;

    return ChatMessage(
      id: json['id'] ?? '',
      role: ChatRole.values.byName(json['role'] ?? 'user'),
      content: content,
      usage: usageJson != null ? TokenUsage(usageJson['input'] ?? 0, usageJson['output'] ?? 0) : null,
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] ?? 0),
    );
  }
}

sealed class ContentBlock {}

class TextBlock extends ContentBlock {
  String text;
  TextBlock(this.text);
}

class ToolUseBlock extends ContentBlock {
  final String toolCallId;
  final String toolName;
  final Map<String, dynamic> input;
  ToolCallStatus status;
  String? output;
  String? error;

  ToolUseBlock({
    required this.toolCallId,
    required this.toolName,
    required this.input,
    this.status = ToolCallStatus.pending,
    this.output,
    this.error,
  });
}

ToolCallStatus _parseToolCallStatus(dynamic value) {
  if (value is String) {
    for (final s in ToolCallStatus.values) {
      if (s.name == value) return s;
    }
  }
  return ToolCallStatus.completed;
}

class TokenUsage {
  final int inputTokens;
  final int outputTokens;

  const TokenUsage(this.inputTokens, this.outputTokens);

  TokenUsage operator +(TokenUsage other) => TokenUsage(
    inputTokens + other.inputTokens,
    outputTokens + other.outputTokens,
  );
}
