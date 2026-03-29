import 'dart:convert';

import 'package:GitSync/api/manager/auth/git_provider_manager.dart';
import 'package:GitSync/type/git_provider.dart';

enum ToolConfirmation { none, warn, confirm, danger }

enum ToolTier {
  core,
  contextual,
  advanced,
}

class ToolContext {
  final int repoIndex;
  final String repoPath;
  final GitProvider? gitProvider;
  final bool githubAppOauth;
  final String accessToken;
  final String username;
  final String owner;
  final String repo;
  final GitProviderManager? providerManager;
  final String authorName;
  final String authorEmail;

  ToolContext({
    required this.repoIndex,
    required this.repoPath,
    required this.gitProvider,
    required this.githubAppOauth,
    required this.accessToken,
    required this.username,
    required this.owner,
    required this.repo,
    required this.providerManager,
    required this.authorName,
    required this.authorEmail,
  });
}

abstract class AiTool {
  String get name;
  String get description;
  Map<String, dynamic> get inputSchema;
  ToolConfirmation get confirmation;
  ToolTier get tier => ToolTier.core;

  Future<String> execute(Map<String, dynamic> input, ToolContext? context);

  Map<String, dynamic> toAnthropic() => {
    'name': name,
    'description': description,
    'input_schema': inputSchema,
  };

  Map<String, dynamic> toOpenAI() => {
    'type': 'function',
    'function': {
      'name': name,
      'description': description,
      'parameters': inputSchema,
    },
  };

  Map<String, dynamic> toGoogle() => {
    'name': name,
    'description': description,
    'parameters': inputSchema,
  };

  String ok(dynamic data) => jsonEncode({'result': data});
  String err(String message) => jsonEncode({'error': message});
}

class ToolRegistry {
  final Map<String, AiTool> _tools = {};

  void register(AiTool tool) => _tools[tool.name] = tool;
  void registerAll(List<AiTool> tools) => tools.forEach(register);

  AiTool? get(String name) => _tools[name];
  List<AiTool> get all => _tools.values.toList();

  List<AiTool> getFiltered({required bool hasOAuth, Set<String>? activated}) {
    return _tools.values.where((tool) {
      if (tool.tier == ToolTier.core) return true;
      if (tool.tier == ToolTier.contextual) return hasOAuth;
      if (tool.tier == ToolTier.advanced) {
        return activated?.contains(tool.name) ?? false;
      }
      return false;
    }).toList();
  }

  List<Map<String, String>> listAdvancedTools() {
    return _tools.values
        .where((t) => t.tier == ToolTier.advanced)
        .map((t) => {'name': t.name, 'description': t.description})
        .toList();
  }
}

class ListAvailableToolsTool extends AiTool {
  final ToolRegistry _registry;
  ListAvailableToolsTool(this._registry);

  @override String get name => 'list_available_tools';
  @override String get description =>
      'List additional tools not currently loaded. Call this when you need a capability not in your current tool set, such as advanced git operations, history rewriting, force operations, remote management, submodules, tags, or maintenance.';
  @override ToolConfirmation get confirmation => ToolConfirmation.none;
  @override ToolTier get tier => ToolTier.core;
  @override Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {},
  };

  @override
  Future<String> execute(Map<String, dynamic> input, ToolContext? context) async {
    final tools = _registry.listAdvancedTools();
    return ok({'available_tools': tools});
  }
}
