import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:GitSync/api/manager/git_manager.dart';
import 'package:GitSync/api/manager/storage.dart';
import 'package:GitSync/api/logger.dart';
import 'package:GitSync/constant/strings.dart';
import 'package:GitSync/global.dart';
import 'package:GitSync/src/rust/api/git_manager.dart' as GitManagerRs;

abstract class CachedGitNotifier<T> extends AsyncNotifier<T> {
  Future<T> readCache();
  Future<T> fetchLive();
  Future<void> writeCache(T value);

  @override
  Future<T> build() async {
    var cancelled = false;
    ref.onDispose(() => cancelled = true);

    final cached = await readCache();

    () async {
      try {
        final live = await fetchLive();
        if (!cancelled) {
          state = AsyncData(live);
          await writeCache(live);
        }
      } catch (_) {}
    }();

    return cached;
  }

  void set(T value) {
    state = AsyncData(value);
    writeCache(value);
  }
}

class BranchNameNotifier extends CachedGitNotifier<String?> {
  @override
  Future<String?> readCache() => uiSettingsManager.getStringNullable(StorageKey.setman_branchName);

  @override
  Future<String?> fetchLive() => runGitOperation<String?>(LogType.BranchName, (event) => event?["result"]);

  @override
  Future<void> writeCache(String? value) => uiSettingsManager.setStringNullable(StorageKey.setman_branchName, value);
}

final branchNameProvider = AsyncNotifierProvider<BranchNameNotifier, String?>(BranchNameNotifier.new);

class RemoteUrlLinkNotifier extends CachedGitNotifier<(String, String)?> {
  @override
  Future<(String, String)?> readCache() async {
    final cached = await uiSettingsManager.getStringList(StorageKey.setman_remoteUrlLink);
    if (cached.isEmpty) return null;
    return (cached.first, cached.last);
  }

  @override
  Future<(String, String)?> fetchLive() => runGitOperation<(String, String)?>(
    LogType.GetRemoteUrlLink,
    (event) => event == null || event["result"] == null ? null : (event["result"][0] as String, event["result"][1] as String),
  );

  @override
  Future<void> writeCache((String, String)? value) =>
      uiSettingsManager.setStringList(StorageKey.setman_remoteUrlLink, value == null ? [] : [value.$1, value.$2]);
}

final remoteUrlLinkProvider = AsyncNotifierProvider<RemoteUrlLinkNotifier, (String, String)?>(RemoteUrlLinkNotifier.new);

class ListRemotesNotifier extends CachedGitNotifier<List<String>> {
  @override
  Future<List<String>> readCache() => uiSettingsManager.getStringList(StorageKey.setman_remotes);

  @override
  Future<List<String>> fetchLive() => runGitOperation<List<String>>(
    LogType.ListRemotes,
    (event) => event?["result"].map<String>((r) => "$r").toList() ?? <String>[],
  );

  @override
  Future<void> writeCache(List<String> value) => uiSettingsManager.setStringList(StorageKey.setman_remotes, value);
}

final listRemotesProvider = AsyncNotifierProvider<ListRemotesNotifier, List<String>>(ListRemotesNotifier.new);

class BranchNamesNotifier extends CachedGitNotifier<Map<String, String>> {
  @override
  Future<Map<String, String>> readCache() async {
    final cached = await uiSettingsManager.getStringList(StorageKey.setman_branchNames);
    if (cached.isEmpty) return {};
    final map = <String, String>{};
    for (final entry in cached) {
      final parts = entry.split(conflictSeparator);
      map[parts[0]] = parts.length > 1 ? parts[1] : 'both';
    }
    return map;
  }

  @override
  Future<Map<String, String>> fetchLive() => runGitOperation<Map<String, String>>(
    LogType.BranchNames,
    (event) {
      final raw = event?["result"]?.map<String>((path) => "$path").toList() ?? <String>[];
      final map = <String, String>{};
      for (final entry in raw) {
        final parts = entry.split(conflictSeparator);
        map[parts[0]] = parts.length > 1 ? parts[1] : 'both';
      }
      return map;
    },
  );

  @override
  Future<void> writeCache(Map<String, String> value) =>
      uiSettingsManager.setStringList(
        StorageKey.setman_branchNames,
        value.entries.map((e) => "${e.key}$conflictSeparator${e.value}").toList(),
      );
}

final branchNamesProvider = AsyncNotifierProvider<BranchNamesNotifier, Map<String, String>>(BranchNamesNotifier.new);

class HasGitFiltersNotifier extends CachedGitNotifier<bool> {
  @override
  Future<bool> readCache() => uiSettingsManager.getBool(StorageKey.setman_hasGitFilters);

  @override
  Future<bool> fetchLive() => runGitOperation<bool>(LogType.HasGitFilters, (event) => event?["result"] ?? false);

  @override
  Future<void> writeCache(bool value) => uiSettingsManager.setBool(StorageKey.setman_hasGitFilters, value);
}

final hasGitFiltersProvider = AsyncNotifierProvider<HasGitFiltersNotifier, bool>(HasGitFiltersNotifier.new);

class ConflictingFilesNotifier extends CachedGitNotifier<List<(String, GitManagerRs.ConflictType)>> {
  @override
  Future<List<(String, GitManagerRs.ConflictType)>> readCache() async {
    final cached = await uiSettingsManager.getStringList(StorageKey.setman_conflicting);
    return cached.map((item) {
      final decoded = jsonDecode(item) as List;
      return (decoded[0] as String, GitManagerRs.ConflictType.values.byName(decoded[1] as String));
    }).toList();
  }

  @override
  Future<List<(String, GitManagerRs.ConflictType)>> fetchLive() => runGitOperation<List<(String, GitManagerRs.ConflictType)>>(
        LogType.ConflictingFiles,
        (event) => (event?["result"] as List)
            .map<(String, GitManagerRs.ConflictType)>((item) => (item[0] as String, GitManagerRs.ConflictType.values.byName(item[1] as String)))
            .toList(),
      );

  @override
  Future<void> writeCache(List<(String, GitManagerRs.ConflictType)> value) => uiSettingsManager.setStringList(
        StorageKey.setman_conflicting,
        value.map((e) => jsonEncode([e.$1, e.$2.name])).toList(),
      );
}

final conflictingFilesProvider =
    AsyncNotifierProvider<ConflictingFilesNotifier, List<(String, GitManagerRs.ConflictType)>>(ConflictingFilesNotifier.new);
