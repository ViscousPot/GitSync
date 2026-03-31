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

class RecentCommitsNotifier extends CachedGitNotifier<List<GitManagerRs.Commit>> {
  bool _hasMoreCommits = true;
  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;

  @override
  Future<List<GitManagerRs.Commit>> readCache() async {
    final cached = await uiSettingsManager.getStringList(StorageKey.setman_recentCommits);
    return cached.map((item) => CommitJson.fromJson(jsonDecode(utf8.fuse(base64).decode(item)))).toList();
  }

  @override
  Future<List<GitManagerRs.Commit>> fetchLive() => runGitOperation<List<GitManagerRs.Commit>>(
        LogType.RecentCommits,
        (event) =>
            event?["result"]?.map<GitManagerRs.Commit>((path) => CommitJson.fromJson(jsonDecode(utf8.fuse(base64).decode("$path")))).toList() ??
            <GitManagerRs.Commit>[],
      );

  @override
  Future<void> writeCache(List<GitManagerRs.Commit> value) => uiSettingsManager.setStringList(
        StorageKey.setman_recentCommits,
        value.map((item) => utf8.fuse(base64).encode(jsonEncode(item.toJson()))).toList(),
      );

  @override
  Future<List<GitManagerRs.Commit>> build() async {
    _hasMoreCommits = true;
    _isLoadingMore = false;

    var cancelled = false;
    ref.onDispose(() => cancelled = true);

    final cached = await readCache();

    if (cached.isEmpty) {
      final live = await fetchLive();
      await writeCache(live);
      return live;
    }

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

  Future<void> loadMore() async {
    if (!_hasMoreCommits || _isLoadingMore) return;
    final current = state.valueOrNull ?? [];
    _isLoadingMore = true;
    state = AsyncData(current);
    final moreCommits = await GitManager.getMoreRecentCommits(current.length);
    if (moreCommits.isEmpty) {
      _hasMoreCommits = false;
    } else {
      final updated = [...current, ...moreCommits];
      state = AsyncData(updated);
      await writeCache(updated);
    }
    _isLoadingMore = false;
    state = AsyncData(state.valueOrNull ?? current);
  }
}

final recentCommitsProvider =
    AsyncNotifierProvider<RecentCommitsNotifier, List<GitManagerRs.Commit>>(RecentCommitsNotifier.new);

class RecommendedActionNotifier extends CachedGitNotifier<int?> {
  @override
  Future<int?> readCache() => uiSettingsManager.getIntNullable(StorageKey.setman_recommendedAction);

  @override
  Future<int?> fetchLive() => runGitOperation<int?>(LogType.RecommendedAction, (event) => event?["result"]);

  @override
  Future<void> writeCache(int? value) => uiSettingsManager.setIntNullable(StorageKey.setman_recommendedAction, value);

  Future<int?> refresh() async {
    try {
      final live = await fetchLive();
      state = AsyncData(live);
      await writeCache(live);
      return live;
    } catch (_) {
      return state.valueOrNull;
    }
  }
}

final recommendedActionProvider = AsyncNotifierProvider<RecommendedActionNotifier, int?>(RecommendedActionNotifier.new);
