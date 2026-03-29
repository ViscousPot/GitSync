import 'dart:convert';

import 'package:GitSync/api/ai_tools.dart';
import 'package:GitSync/type/ai_chat.dart';

class ToolExecutor {
  final ToolRegistry registry;

  final Future<bool> Function(AiTool tool, Map<String, dynamic> input) onConfirmationRequired;

  ToolExecutor({required this.registry, required this.onConfirmationRequired});

  Future<String> execute(ToolUseBlock block, ToolContext? context) async {
    final tool = registry.get(block.toolName);
    if (tool == null) {
      block.status = ToolCallStatus.failed;
      block.error = 'Unknown tool: ${block.toolName}';
      return jsonEncode({'error': 'Unknown tool: ${block.toolName}'});
    }

    if (tool.confirmation != ToolConfirmation.none) {
      block.status = ToolCallStatus.pending;
      final approved = await onConfirmationRequired(tool, block.input);
      if (!approved) {
        block.status = ToolCallStatus.rejected;
        block.error = 'User rejected this operation';
        return jsonEncode({'error': 'User rejected this operation'});
      }
      block.status = ToolCallStatus.approved;
    }

    block.status = ToolCallStatus.running;
    try {
      final result = await tool.execute(block.input, context).timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          block.status = ToolCallStatus.failed;
          block.error = 'Tool execution timed out after 60s';
          return jsonEncode({'error': 'Tool execution timed out after 60s'});
        },
      );
      if (block.status == ToolCallStatus.running) {
        block.status = ToolCallStatus.completed;
        block.output = result;
      }
      return result;
    } catch (e) {
      block.status = ToolCallStatus.failed;
      block.error = e.toString();
      return jsonEncode({'error': e.toString()});
    }
  }
}
