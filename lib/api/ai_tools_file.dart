import 'dart:io';

import 'package:GitSync/api/ai_tools.dart';
import 'package:GitSync/global.dart';

Future<String?> _repoRoot(ToolContext? context) async => context?.repoPath ?? (await uiSettingsManager.getGitDirPath())?.$1;

Future<String?> _resolve(String relativePath, ToolContext? context) async {
  final root = await _repoRoot(context);
  if (root == null || relativePath.contains('\x00')) return null;
  final joined = Uri.parse('$root/$relativePath').normalizePath().toFilePath();
  try {
    final canonical = File(joined).resolveSymbolicLinksSync();
    final canonicalRoot = Directory(root).resolveSymbolicLinksSync();
    if (!canonical.startsWith('$canonicalRoot/') && canonical != canonicalRoot) return null;
    return canonical;
  } on FileSystemException {
    final parent = File(joined).parent;
    try {
      final canonicalParent = parent.resolveSymbolicLinksSync();
      final canonicalRoot = Directory(root).resolveSymbolicLinksSync();
      if (!canonicalParent.startsWith('$canonicalRoot/') && canonicalParent != canonicalRoot) return null;
      return joined;
    } on FileSystemException {
      return null;
    }
  }
}

class FileReadTool extends AiTool {
  @override
  String get name => 'file_read';
  @override
  String get description => 'Read a file. Use offset/limit for large files.';
  @override
  ToolConfirmation get confirmation => ToolConfirmation.none;
  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'path': {'type': 'string'},
      'offset': {'type': 'integer', 'default': 0},
      'limit': {'type': 'integer', 'default': 500},
    },
    'required': ['path'],
  };

  @override
  Future<String> execute(Map<String, dynamic> input, ToolContext? context) async {
    final path = input['path'] as String;
    final offset = (input['offset'] as int?) ?? 0;
    final limit = ((input['limit'] as int?) ?? 500).clamp(1, 500);

    final resolved = await _resolve(path, context);
    if (resolved == null) return err('Invalid path or no repository open');

    final file = File(resolved);
    if (!await file.exists()) return err('File not found: $path');

    try {
      final lines = await file.readAsLines();
      final total = lines.length;
      final start = offset.clamp(0, total);
      final end = (start + limit).clamp(start, total);
      final slice = lines.sublist(start, end);

      final numbered = StringBuffer();
      var truncatedLines = 0;
      for (var i = 0; i < slice.length; i++) {
        if (numbered.length >= 4000) {
          truncatedLines = slice.length - i;
          numbered.writeln('... [truncated, $truncatedLines more lines in window; narrow with offset/limit]');
          break;
        }
        numbered.writeln('${start + i + 1}: ${slice[i]}');
      }

      return ok({'total_lines': total, 'showing': '${start + 1}-${end - truncatedLines}', 'content': numbered.toString()});
    } catch (e) {
      return err('Could not read file (may be binary): $e');
    }
  }
}

class FileWriteTool extends AiTool {
  @override
  String get name => 'file_write';
  @override
  String get description => 'Create or fully replace a file.';
  @override
  ToolConfirmation get confirmation => ToolConfirmation.confirm;
  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'path': {'type': 'string'},
      'content': {'type': 'string'},
    },
    'required': ['path', 'content'],
  };

  @override
  Future<String> execute(Map<String, dynamic> input, ToolContext? context) async {
    final path = input['path'] as String;
    final content = input['content'] as String;

    final resolved = await _resolve(path, context);
    if (resolved == null) return err('Invalid path or no repository open');

    final file = File(resolved);
    final existed = await file.exists();
    if (!existed) {
      await file.parent.create(recursive: true);
    }
    await file.writeAsString(content);
    return ok(existed ? 'Overwrote $path' : 'Created $path');
  }
}

class FileEditTool extends AiTool {
  @override
  String get name => 'file_edit';
  @override
  String get description =>
      'Replace exact strings in a file. Supports a single edit (old_content/new_content) or batch edits (edits array). Each old_content must match uniquely.';
  @override
  ToolConfirmation get confirmation => ToolConfirmation.warn;
  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'path': {'type': 'string'},
      'old_content': {'type': 'string'},
      'new_content': {'type': 'string'},
      'edits': {
        'type': 'array',
        'items': {
          'type': 'object',
          'properties': {
            'old_content': {'type': 'string'},
            'new_content': {'type': 'string'},
          },
          'required': ['old_content', 'new_content'],
        },
      },
    },
    'required': ['path'],
  };

  @override
  Future<String> execute(Map<String, dynamic> input, ToolContext? context) async {
    final path = input['path'] as String;

    final resolved = await _resolve(path, context);
    if (resolved == null) return err('Invalid path or no repository open');

    final file = File(resolved);
    if (!await file.exists()) return err('File not found: $path');

    // Build the list of edits — either from the edits array or single old/new.
    final List<Map<String, String>> edits;
    if (input.containsKey('edits')) {
      final raw = input['edits'] as List<dynamic>;
      edits = raw.map((e) {
        final m = e as Map<String, dynamic>;
        return {'old_content': m['old_content'] as String, 'new_content': m['new_content'] as String};
      }).toList();
    } else if (input.containsKey('old_content') && input.containsKey('new_content')) {
      edits = [
        {'old_content': input['old_content'] as String, 'new_content': input['new_content'] as String},
      ];
    } else {
      return err('Provide either old_content/new_content or an edits array');
    }

    if (edits.isEmpty) return err('No edits provided');

    var content = await file.readAsString();

    // Validate all edits before applying any.
    for (var i = 0; i < edits.length; i++) {
      final old = edits[i]['old_content']!;
      final count = old.allMatches(content).length;
      if (count == 0) return err('Edit ${i + 1}: old_content not found in $path');
      if (count > 1) return err('Edit ${i + 1}: old_content matches $count times in $path — provide more context to make it unique');
    }

    // Apply all edits sequentially.
    for (final edit in edits) {
      content = content.replaceFirst(edit['old_content']!, edit['new_content']!);
    }

    await file.writeAsString(content);
    return ok(edits.length == 1 ? 'Edited $path' : 'Applied ${edits.length} edits to $path');
  }
}

class FileListTool extends AiTool {
  @override
  String get name => 'file_list';
  @override
  String get description => 'List files in a directory.';
  @override
  ToolConfirmation get confirmation => ToolConfirmation.none;
  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'path': {'type': 'string', 'default': '.'},
      'recursive': {'type': 'boolean', 'default': false},
      'max_depth': {'type': 'integer', 'default': 3},
    },
  };

  @override
  Future<String> execute(Map<String, dynamic> input, ToolContext? context) async {
    final path = (input['path'] as String?) ?? '.';
    final recursive = (input['recursive'] as bool?) ?? false;
    final maxDepth = ((input['max_depth'] as int?) ?? 3).clamp(1, 5);

    final root = await _repoRoot(context);
    if (root == null) return err('No repository open');

    final resolved = await _resolve(path, context);
    if (resolved == null) return err('Invalid path');

    final dir = Directory(resolved);
    if (!await dir.exists()) return err('Directory not found: $path');

    final entries = <String>[];
    await _listDir(dir, root, entries, recursive ? maxDepth : 0, 0);

    if (entries.length > 500) {
      return ok({'entries': entries.sublist(0, 500), 'truncated': true, 'total': entries.length});
    }
    return ok({'entries': entries, 'truncated': false});
  }

  Future<void> _listDir(Directory dir, String root, List<String> entries, int maxDepth, int currentDepth) async {
    try {
      final list = dir.listSync();
      for (final entity in list) {
        final name = entity.path.replaceFirst('$root/', '');
        if (name.startsWith('.git/') || name == '.git') continue;
        final isDir = entity is Directory;
        entries.add(isDir ? '$name/' : name);
        if (isDir && currentDepth < maxDepth) {
          await _listDir(entity, root, entries, maxDepth, currentDepth + 1);
        }
      }
    } catch (_) {}
  }
}

class FileSearchTool extends AiTool {
  @override
  String get name => 'file_search';
  @override
  String get description => 'Regex search across files. file_glob filters filenames (e.g. "*.dart").';
  @override
  ToolConfirmation get confirmation => ToolConfirmation.none;
  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'pattern': {'type': 'string'},
      'path': {'type': 'string', 'default': '.'},
      'file_glob': {'type': 'string'},
    },
    'required': ['pattern'],
  };

  @override
  Future<String> execute(Map<String, dynamic> input, ToolContext? context) async {
    final pattern = input['pattern'] as String;
    final path = (input['path'] as String?) ?? '.';
    final fileGlob = input['file_glob'] as String?;

    final root = await _repoRoot(context);
    if (root == null) return err('No repository open');

    final resolved = await _resolve(path, context);
    if (resolved == null) return err('Invalid path');

    final regex = RegExp(pattern, multiLine: true);
    final matches = <Map<String, dynamic>>[];
    final dir = Directory(resolved);
    if (!await dir.exists()) return err('Directory not found: $path');

    await _searchDir(dir, root, regex, fileGlob, matches);
    return ok({'matches': matches, 'truncated': matches.length >= 50});
  }

  Future<void> _searchDir(Directory dir, String root, RegExp regex, String? fileGlob, List<Map<String, dynamic>> matches) async {
    if (matches.length >= 50) return;
    try {
      for (final entity in dir.listSync()) {
        if (matches.length >= 50) return;
        final relPath = entity.path.replaceFirst('$root/', '');
        if (relPath.startsWith('.git/') || relPath == '.git') continue;

        if (entity is Directory) {
          await _searchDir(entity, root, regex, fileGlob, matches);
        } else if (entity is File) {
          if (fileGlob != null && !_matchGlob(entity.path.split('/').last, fileGlob)) continue;
          try {
            final lines = await entity.readAsLines();
            for (var i = 0; i < lines.length && matches.length < 50; i++) {
              if (regex.hasMatch(lines[i])) {
                matches.add({'file': relPath, 'line': i + 1, 'content': lines[i]});
              }
            }
          } catch (_) {} // skip binary files
        }
      }
    } catch (_) {}
  }

  bool _matchGlob(String fileName, String glob) {
    final pattern = glob.replaceAll('.', r'\.').replaceAll('*', '.*');
    return RegExp('^$pattern\$').hasMatch(fileName);
  }
}

List<AiTool> allFileTools() => [FileReadTool(), FileWriteTool(), FileEditTool(), FileListTool(), FileSearchTool()];
