import 'dart:io';

import 'package:GitSync/api/ai_tools.dart';
import 'package:GitSync/global.dart';

String? _repoRoot(ToolContext? context) => context?.repoPath ?? uiSettingsManager.gitDirPath?.$1;

String? _resolve(String relativePath, ToolContext? context) {
  final root = _repoRoot(context);
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
  @override String get name => 'file_read';
  @override String get description => 'Read the contents of a file in the repository. For large files, use offset and limit.';
  @override ToolConfirmation get confirmation => ToolConfirmation.none;
  @override Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'path': {'type': 'string', 'description': 'Relative path from repo root'},
      'offset': {'type': 'integer', 'description': 'Line offset to start reading from (0-based)', 'default': 0},
      'limit': {'type': 'integer', 'description': 'Maximum number of lines to read', 'default': 500},
    },
    'required': ['path'],
  };

  @override
  Future<String> execute(Map<String, dynamic> input, ToolContext? context) async {
    final path = input['path'] as String;
    final offset = (input['offset'] as int?) ?? 0;
    final limit = ((input['limit'] as int?) ?? 500).clamp(1, 500);

    final resolved = _resolve(path, context);
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
      for (var i = 0; i < slice.length; i++) {
        numbered.writeln('${start + i + 1}: ${slice[i]}');
      }

      return ok({'total_lines': total, 'showing': '${start + 1}-$end', 'content': numbered.toString()});
    } catch (e) {
      return err('Could not read file (may be binary): $e');
    }
  }
}

class FileWriteTool extends AiTool {
  @override String get name => 'file_write';
  @override String get description => 'Write content to a file, creating it if it doesn\'t exist or replacing it entirely.';
  @override ToolConfirmation get confirmation => ToolConfirmation.confirm;
  @override Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'path': {'type': 'string', 'description': 'Relative path from repo root'},
      'content': {'type': 'string', 'description': 'Full file content to write'},
    },
    'required': ['path', 'content'],
  };

  @override
  Future<String> execute(Map<String, dynamic> input, ToolContext? context) async {
    final path = input['path'] as String;
    final content = input['content'] as String;

    final resolved = _resolve(path, context);
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
  @override String get name => 'file_edit';
  @override String get description => 'Apply a targeted edit to a file by replacing an exact string match with new content.';
  @override ToolConfirmation get confirmation => ToolConfirmation.warn;
  @override Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'path': {'type': 'string', 'description': 'Relative path from repo root'},
      'old_content': {'type': 'string', 'description': 'Exact text to find (must match uniquely)'},
      'new_content': {'type': 'string', 'description': 'Replacement text'},
    },
    'required': ['path', 'old_content', 'new_content'],
  };

  @override
  Future<String> execute(Map<String, dynamic> input, ToolContext? context) async {
    final path = input['path'] as String;
    final oldContent = input['old_content'] as String;
    final newContent = input['new_content'] as String;

    final resolved = _resolve(path, context);
    if (resolved == null) return err('Invalid path or no repository open');

    final file = File(resolved);
    if (!await file.exists()) return err('File not found: $path');

    final content = await file.readAsString();
    final count = oldContent.allMatches(content).length;
    if (count == 0) return err('old_content not found in $path');
    if (count > 1) return err('old_content matches $count times in $path — provide more context to make it unique');

    await file.writeAsString(content.replaceFirst(oldContent, newContent));
    return ok('Edited $path');
  }
}

class FileListTool extends AiTool {
  @override String get name => 'file_list';
  @override String get description => 'List files and directories at a given path in the repository.';
  @override ToolConfirmation get confirmation => ToolConfirmation.none;
  @override Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'path': {'type': 'string', 'description': "Relative directory path ('.' for repo root)", 'default': '.'},
      'recursive': {'type': 'boolean', 'description': 'List recursively', 'default': false},
      'max_depth': {'type': 'integer', 'description': 'Max recursion depth (only with recursive=true)', 'default': 3},
    },
  };

  @override
  Future<String> execute(Map<String, dynamic> input, ToolContext? context) async {
    final path = (input['path'] as String?) ?? '.';
    final recursive = (input['recursive'] as bool?) ?? false;
    final maxDepth = ((input['max_depth'] as int?) ?? 3).clamp(1, 5);

    final root = _repoRoot(context);
    if (root == null) return err('No repository open');

    final resolved = _resolve(path, context);
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
  @override String get name => 'file_search';
  @override String get description => 'Search for a text pattern across files in the repository.';
  @override ToolConfirmation get confirmation => ToolConfirmation.none;
  @override Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'pattern': {'type': 'string', 'description': 'Text or regex pattern to search for'},
      'path': {'type': 'string', 'description': 'Subdirectory to search in', 'default': '.'},
      'file_glob': {'type': 'string', 'description': "File name filter, e.g. '*.dart'"},
    },
    'required': ['pattern'],
  };

  @override
  Future<String> execute(Map<String, dynamic> input, ToolContext? context) async {
    final pattern = input['pattern'] as String;
    final path = (input['path'] as String?) ?? '.';
    final fileGlob = input['file_glob'] as String?;

    final root = _repoRoot(context);
    if (root == null) return err('No repository open');

    final resolved = _resolve(path, context);
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

List<AiTool> allFileTools() => [
  FileReadTool(),
  FileWriteTool(),
  FileEditTool(),
  FileListTool(),
  FileSearchTool(),
];
